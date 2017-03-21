#!/bin/bash

# Variables
BRANCH=${BRANCH:-master}
FLAVORS=$(echo ${FLAVORS:-${@:-"common"}} | tr "," " ")
ROOTDIR=${ROOTDIR:-/}
DL=${DL:-$(hash curl 2>/dev/null && echo "curl" || echo "wget")}
TMPFILE=/tmp/image-tools-temporary.tar


# Download with curl or wget
dl() {
    if [ "$DL" = "wget" ]; then
        wget -q -O - --no-check-certificate $@
    fi
    if [ "$DL" = "curl" ]; then
        curl -sLk $@
    fi
}


# Apply the flavor directory over the ROOTDIR
apply_flavor() {
    local flavor="${1}"
    echo "applying flavor '${flavor}'"
    tar --strip=2 -C ${ROOTDIR}/ -xzf ${TMPFILE} image-tools-${BRANCH}/skeleton-${flavor};

    # Executes flavor's install script
    if [ -x /tmp/image-tools-install-${flavor}.sh ]; then
        /tmp/image-tools-install-${flavor}.sh
    fi
}


# Cleaning
clean() {
    rm -rf ${TMPFILE}
}

main() {
    # Download tarball
    dl https://github.com/scaleway/image-tools/archive/${BRANCH}.tar.gz > ${TMPFILE}
    
    # Apply flavors
    for flavor in ${FLAVORS}; do
        apply_flavor ${flavor}
    done

    # Save flavors
    FLAVORS_BACKUP=$(cat ${ROOTDIR}/etc/scw-release 2>/dev/null | grep "^IMAGE_FLAVORS=" | tr -d '"' | tr ',' ' ' | cut -d'=' -f2)
    NEW_FLAVORS=$(echo "$(echo "${FLAVORS_BACKUP} ${FLAVORS}" | tr ' ' '\n')" | sed '/^\s*$/d' | sort -u | tr '\n' ' ')

    touch ${ROOTDIR}/etc/scw-release
    sed -i.bak '/^IMAGE_FLAVORS=/d' ${ROOTDIR}/etc/scw-release 2>/dev/null
    cat << EOF >> ${ROOTDIR}/etc/scw-release
IMAGE_FLAVORS="${NEW_FLAVORS%?}"
EOF

    # Save image-tools checkout
    sed -i.bak '/^IMAGE_TOOLS_CHECKOUT=/d' ${ROOTDIR}/etc/scw-release 2>/dev/null
    cat <<EOF >> ${ROOTDIR}/etc/scw-release
IMAGE_TOOLS_CHECKOUT="${BRANCH}"
EOF
    rm -f ${ROOTDIR}/etc/scw-release.bak
    clean
}


main
