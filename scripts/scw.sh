log() {
    echo "$@" >&2
}

logerr() {
    log "[ERROR]" "$@"
}

logwarn() {
    log "[WARNING]" "$@"
}

loginfo() {
    log "[INFO]" "$@"
}

logdebug() {
    log "[DEBUG]" "$@"
}

_scw() {
    scw "$@" >/dev/null 2>&1
}

_ssh() {
    if [ -n "$SSH_GATEWAY" ] && [ -z "$SSH_FORCE_NOPROXY" ]; then
        proxyjump="-J $SSH_GATEWAY"
    fi
    ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" $proxyjump -i $SSH_KEY_FILE "$@"
}

get_server() {
    server_id=$1

    res=$(curl --fail -s https://api.scaleway.com/servers/$server_id -H "x-auth-token: $SCW_TOKEN")
    if [ $? -ne 0 ]; then
        return 1
    else
        echo $res
    fi
}

create_server() {
    server_type=$1
    server_name=$2
    image=$3
    server_env=$4

    if [ -n "$SSH_GATEWAY" ] || (which scw-metadata >/dev/null); then
        ipaddress="--ip-address=none"
    fi

    # Try to create the server
    loginfo "Creating $server_type server $server_name..."
    maximum_create_tries=5
    failed=true
    for try in `seq 1 $maximum_create_tries`; do
        _scw create $ipaddress --commercial-type="$server_type" --bootscript="$bootscript" --name="$server_name" --env="$server_env" $image
        sleep 1
        if [ $(scw ps -a -q --filter="name=$server_name" | wc -l) -gt 0 ]; then
            failed=false
            break
        fi
        backoff=$(echo "(2^($try-1))*60" | bc)
        sleep $backoff
    done
    if $failed; then
        logerr "Could not create server"
        return 1
    fi
    server_id=$(scw ps -a -q --filter="name=$server_name" | head -1)
    loginfo "Created server $server_name, id: $server_id"
    echo "$server_id"
}

boot_server() {
    server_id=$1

    # Try to boot the server
    loginfo "Booting server..."
    maximum_boot_tries=3
    boot_timeout=600
    failed=true
    for try in `seq 1 $maximum_boot_tries`; do
        if (get_server $server_id | jq -r '.server.state' | grep -qxE 'stopped'); then
            _scw start -w -T $boot_timeout $server_id
        fi
        sleep 1
        if (get_server $server_id | jq -r '.server.state' | grep -qxE 'starting'); then
            time_begin=$(date +%s)
            while (get_server $server_id | jq -r '.server.state' | grep -qxE 'starting') ; do
                time_now=$(date +%s)
                time_diff=$(echo "$time_now-$time_begin" | bc)
                if [ $time_diff -gt $boot_timeout ]; then
                    break
                fi
                sleep 5
            done
        fi
        sleep 1
        if (get_server $server_id | jq -r '.server.state' | grep -qxE 'running'); then
            failed=false
            break
        fi
        backoff=$(echo "($try-1)*60" | bc)
        sleep $backoff
    done
    if $failed; then
        logerr "Could not boot server"
        return 2
    fi
    loginfo "Server booted"
}

wait_for_ssh() {
    server_id=$1
    ssh_up_timeout=$2
    if [ -z "$ssh_up_timeout" ]; then
        ssh_up_timeout=300
    fi

    while true; do
        server_ip=$(get_server $server_id | jq -r '.server.private_ip')
        if [ -n "$SSH_GATEWAY" ]; then
            prefix="env SSH_FORCE_NOPROXY=true _ssh $SSH_GATEWAY "
        elif ! (which scw-metadata >/dev/null && ping $server_ip -c 3 >/dev/null); then
            server_ip=$(get_server $server_id | jq -r '.server.public_ip.address // empty')
        fi
        if [ -n "$server_ip" ]; then
            break
        fi
        sleep 5
    done

    # Check that we can reach the node
    if ! $prefix ping $server_ip -c 3 >/dev/null 2>&1; then
        logerr "Could not reach $server_ip"
        return 1
    fi

    # Wait for ssh
    loginfo "Waiting for ssh to be available on $server_ip..."
    time_begin=$(date +%s)
    while ! $prefix nc -zv $server_ip 22 >/dev/null 2>&1; do
        time_now=$(date +%s)
        time_diff=$(echo "$time_now-$time_begin" | bc)
        if [ $time_diff -gt $ssh_up_timeout ]; then
            logerr "Could not detect a listening sshd on $server_ip"
            return 3
        fi
        sleep 1
    done
}

stop_server() {
    server_id=$1

    # Try to stop server
    read server_name server_type < <(get_server $server_id | jq -r '.server | "\(.name) \(.commercial_type)"')
    loginfo "Stopping $server_type server $server_name..."
    maximum_stop_tries=3
    failed=true
    for try in `seq 1 $maximum_stop_tries`; do
        if (get_server $server_id | jq -r '.server.state' | grep -qxE 'running'); then
            _scw stop $server_id
        fi
        sleep 1
        if (get_server $server_id | jq -r '.server.state' | grep -qxE 'stopping|stopped'); then
            failed=false
            break
        fi
        backoff=$(echo "($try-1)*60" | bc)
        sleep $backoff
    done
    if $failed; then
        logerr "Could not stop server $server_name"
        return 1
    fi
    loginfo "Server $server_name stopped"
}

rm_server() {
    server_id=$1

    # Try to stop server
    read server_name server_type < <(get_server $server_id | jq -r '.server | "\(.name) \(.commercial_type)"')
    loginfo "Removing $server_type server $server_name..."
    maximum_rm_tries=3
    failed=true
    for try in `seq 1 $maximum_rm_tries`; do
        if (get_server $server_id | jq -r '.server.state' | grep -qxE 'running'); then
            _scw stop -t $server_id
        fi
        sleep 1
        if (get_server $server_id | jq -r '.server.state' | grep -qxE 'stopping'); then
            _scw wait $server_id
        fi
        sleep 1
        if (get_server $server_id | jq -r '.server.state' | grep -qxE 'stopped'); then
            _scw rm $server_id
        fi
        if ! (get_server $server_id); then
            failed=false
            break
        fi
        backoff=$(echo "($try-1)*60" | bc)
        sleep $backoff
    done
    if (get_server $server_id); then
        logerr "Could not stop and remove server $server_name"
        return 1
    fi
    loginfo "Server $server_name removed"
}

image_from_volume() {
    server_id=$1
    image_arch=$2
    image_name=$3
    image_bootscript=$4

    loginfo "Creating snapshot of server"
    snapshot_id=""
    maximum_snapshot_tries=3
    failed=true
    for try in `seq 1 $maximum_snapshot_tries`; do
        snapshot_id_tmp=$(scw commit --volume=0 $server_id "snapshot-${server_id}-$(date +%Y-%m-%d_%H:%M)")
        if [ $? = 0 ]; then
            snapshot_id=$snapshot_id_tmp
            failed=false
            break
        fi
    done
    if $failed; then
        logerr "Could not create snapshot"
        return 1
    fi

    if [ -n "$image_bootscript" ]; then
        bootscript_opt="--bootscript=$image_bootscript"
    fi

    loginfo "Creating image from snapshot"
    image_id=""
    maximum_mkimage_tries=3
    failed=true
    for try in `seq 1 $maximum_mkimage_tries`; do
        image_id_tmp=$(scw tag --arch="$image_arch" $bootscript_opt $snapshot_id "$image_name")
        if [ $? = 0 ]; then
            image_id=$image_id_tmp
            failed=false
            break
        fi
    done
    if $failed; then
        logerr "Could not create image"
        return 2
    fi
    loginfo "Image $image_name on $image_arch created, id: $image_id"
    echo $image_id
}
