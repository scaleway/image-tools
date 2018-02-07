#! /bin/bash

SRC_DIR=$(dirname $(readlink -f $0))
source $SRC_DIR/scw.sh
source $SRC_DIR/setup_credentials.sh

if [ -z "$OUTPUT_ID_TO" ]; then
    OUTPUT_ID_TO="image_id.txt"
fi

build_args=$1
REGION=$2
image_name=$3
arch=$4
image_bootscript=$5


key=$(cat ${SSH_KEY_FILE}.pub | cut -d' ' -f1,2 | tr ' ' '_')

bootscript_id=$(grep -E "$REGION\|$arch\>" bootscript_ids | cut -d'|' -f3)

server_type=$(grep -E "$arch\>" server_types | cut -d'|' -f2 | cut -d',' -f1)
server_name="image-writer-$(date +%Y-%m-%d_%H:%M)"

server_id=$(create_server $server_type $server_name 50G "AUTHORIZED_KEY=$key $build_args $SERVER_ENV" "$bootscript_id")
[ $? -eq 0 ] || exiterr

boot_server $server_id || exiterr

wait_for_ssh $server_id || exiterr

stop_server $server_id

_scw wait $server_id

image_from_volume $server_id $arch "$image_name" "$image_bootscript" >$OUTPUT_ID_TO || exiterr

rm_server $server_id
