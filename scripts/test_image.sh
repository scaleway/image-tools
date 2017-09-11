#! /bin/bash

SRC_DIR=$(dirname $(readlink -f $0))
source $SRC_DIR/scw.sh
source $SRC_DIR/setup_credentials.sh

test_start() {
    arch=$1
    REGION=$2
    image_id=$3
    servers_list_file=$4
    tests_dir=$5

    key=$(cat ${SSH_KEY_FILE}.pub | cut -d' ' -f1,2 | tr ' ' '_')
    server_types=$(grep -E "$arch\>" server_types | cut -d'|' -f2 | tr ',' ' ')
    : >$servers_list_file

    for server_type in $server_types; do
        server_name="image-test-$(uuidgen -r)"
        server_id=$(create_server $server_type $server_name $image_id "AUTHORIZED_KEY=$key")
        [ $? -eq 0 ] || exiterr

        boot_server $server_id || exiterr

        server_ip=$(get_server_ip $server_id)
        [ $? -eq 0 ] || exiterr
        echo "$server_id $REGION $server_type $server_name $server_ip" >>$servers_list_file

        wait_for_ssh $server_id || exiterr


        if [ -n "$tests_dir" ]; then
            loginfo "Running tests in $tests_dir"
            ssh_tmp_config=$(mktemp)
            ssh -G $server_ip >$ssh_tmp_config
            _ssh_get_options >>$ssh_tmp_config
            yamltest --timdir $tests_dir --pytestarg="--connection=ssh" --pytestarg="--ssh-config=$ssh_tmp_config" root@$server_ip || exiterr
            rm $ssh_tmp_config
        elif ! (_ssh root@$server_ip "uname -a; lsmod"); then
            logerr "Command 'uname -a; lsmod' failed to execute"
            exiterr
        fi
    done
    loginfo "Tested image $image_id on server(s):"
    cat $servers_list_file | while read server_id REGION server_type server_name server_ip; do
        loginfo "Name ${server_name}, type $server_type (id ${server_id}, ip ${server_ip})"
    done
}

test_stop() {
    servers_list_file=$1

    cat $servers_list_file | while read server_id REGION server_type server_name server_ip; do
        rm_server $server_id
    done
}

action=$1
shift
test_$action "$@"
