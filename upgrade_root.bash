#!/bin/bash

BRANCH=${BRANCH:-master}
FLAVORS=$(echo ${FLAVORS:-$@} | tr "," " ")

apply_flavor() {
    flavor="$1"
    tar --strip=2 -C / -xzvf <(wget -qO - https://github.com/online-labs/ocs-scripts/archive/$BRANCH.tar.gz) ocs-scripts-$BRANCH/skeleton$flavor;
    if [ -x /tmp/ocs-scripts-install$flavor.sh ]; then
        /tmp/ocs-scripts-install$flavor.sh
    fi
}

# Apply default skeleton
apply_flavor ""

# Appply flavors if any
for flavor in $FLAVORS; do apply_flavor -$flavor; done
