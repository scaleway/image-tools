#!/bin/bash

BRANCH=${BRANCH:-master}
FLAVORS=$(echo ${FLAVORS:-${@}} | tr "," " ")
FLAVORS=${FLAVORS:-"common"}
ROOTDIR=${ROOTDIR:-/}
DL=${DL:-wget}

dl_wget() {
    wget -O - --no-check-certificate $@
}

dl_curl() {
    curl -Lk $@
}

dl() {
    dl_$DL $@
}

apply_flavor() {
    flavor="${1}"
    tar --strip=2 -C ${ROOTDIR}/ -xzvf <(dl https://github.com/online-labs/ocs-scripts/archive/${BRANCH}.tar.gz) ocs-scripts-${BRANCH}/skeleton${flavor};
    if [ -x /tmp/ocs-scripts-install${flavor}.sh ]; then
        /tmp/ocs-scripts-install${flavor}.sh
    fi
}

# Appply flavors if any
for flavor in ${FLAVORS}; do
    apply_flavor -${flavor}
done
