#!/bin/bash

set -xe

lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
lsb_release="$(. /etc/lsb-release && echo "$DISTRIB_RELEASE")"

case "$lsb_dist" in
    Ubuntu)
        case "$lsb_release" in
            14.04)
                ln -s /etc/init.d/disconnectnbd /etc/rc6.d/S89disconnectnbd
                exit 0
                ;;
            14.10)
                update-rc.d disconnectnbd defaults
                exit 0
                ;;
        esac
        ;;
esac

echo "Unsupported distribution $DISTRIB_ID ($DISTRIB_RELEASE)" >&2
exit 1
