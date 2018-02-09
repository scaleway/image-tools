#! /bin/bash

SRC_DIR=$(dirname $(readlink -f $0))
source $SRC_DIR/scw.sh
source $SRC_DIR/setup_credentials.sh

if [ -z "$OUTPUT_ID_TO" ]; then
    OUTPUT_ID_TO="image_id.txt"
fi

rootfs_url=$1
image_name=$2
arch=$3
image_bootscript=$4
if [ "$5" = "unpartitioned" ]; then
    build_method="unpartitioned-from-rootfs"
else
    build_method="from-rootfs"
fi


key=$(cat ${SSH_KEY_FILE}.pub | cut -d' ' -f1,2 | tr ' ' '_')

bootscript_id=$(grep -E "$REGION\|$arch\>" bootscript_ids | cut -d'|' -f3)

server_type=$(grep -E "$arch\>" server_types | cut -d'|' -f2 | cut -d',' -f1 | tr -d '\n')
server_creation_opts=$(grep -E "$arch\>" server_types | cut -d'|' -f3 | tr -d '\n')
server_name="image-writer-$(date +%Y-%m-%d_%H:%M)"
signal_port=$(shuf -i 10000-60000 -n 1)
server_env="build_method=$build_method rootfs_url=$rootfs_url signal_build_done_port=$signal_port AUTHORIZED_KEY=$key $SERVER_ENV"

server_id=$(create_server "$server_type" "$server_creation_opts" "$server_name" 50G "$server_env" "$bootscript_id")
[ $? -eq 0 ] || exiterr

boot_server $server_id || exiterr

wait_for_port $server_id $signal_port || exiterr

stop_server $server_id

_scw wait $server_id

image_from_volume $server_id $arch "$image_name" "$image_bootscript" >$OUTPUT_ID_TO || exiterr

rm_server $server_id
