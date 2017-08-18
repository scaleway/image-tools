#! /bin/bash

SRC_DIR=$(dirname $(readlink -f $0))
source $SRC_DIR/scw.sh

if [ -z "$SSH_KEY_FILE" ]; then
    for candidate in "id_rsa" "id_dsa" "id_ecdsa" "id_ed25519"; do
        candidate_file="$HOME/.ssh/$candidate.pub"
        if [ -f $candidate_file ]; then
            export SSH_KEY_FILE=$candidate_file
            break
        fi
    done
    if [ -z "$SSH_KEY_FILE" ]; then
        logerr "Could not find any ssh identity to use"
        exit 1
    fi
fi

if [ -z "$OUTPUT_ID_TO" ]; then
    OUTPUT_ID_TO="image_id.txt"
fi

rootfs_url=$1
REGION=$2
image_name=$3
arch=$4
image_bootscript=$5

if ! [ -f $HOME/.scwrc ]; then
    logerr "Please log into Scaleway first : scw login"
    exit 1
fi
read SCW_ORGANIZATION SCW_TOKEN < <(jq -r '"\(.organization) \(.token)"' $HOME/.scwrc)
if [ -z "$SCW_ORGANIZATION" ] || [ -z "$SCW_TOKEN" ]; then
    logerr "Could not get authentication information from $HOME/.scwrc"
    exit 1
fi

key=$(cat $SSH_KEY_FILE | cut -d' ' -f1,2 | tr ' ' '_')

bootscript_id=$(grep -E "$REGION\|$arch\>" bootscript_ids | cut -d'|' -f3)

server_type=$(grep -E "$arch\>" server_types | cut -d'|' -f2 | cut -d',' -f1)
server_name="image-writer-$(date +%Y-%m-%d_%H:%M)"

server_id=$(create_server $server_type $server_name 50G "AUTHORIZED_KEY=$key boot=live rescue_image=$rootfs_url DONT_FORWARD_NET_CONFIG=1 DONT_GEN_ROOT_PASSWD=1 INITRD_DROPBEAR=1" "$bootscript_id")

boot_server $server_id

wait_for_ssh $server_id

stop_server $server_id

_scw wait $server_id

image_from_volume $server_id $arch "$image_name" "$image_bootscript" >$OUTPUT_ID_TO

rm_server $server_id
