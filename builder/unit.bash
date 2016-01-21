#!/bin/bash

testRootPasswd() {
    grep 'root:\*\?:' /etc/shadow >/dev/null
    returnCode=$?
    assertEquals "User root has a setted password" 0 $returnCode
}


testKernelModules() {
    [ -n "${SKIP_NON_DOCKER}" ] && startSkipping
    test -d "/lib/modules/$(uname -r)/kernel"
    returnCode=$?
    assertEquals "Kernel modules not downloaded" 0 $returnCode
    [ -n "${SKIP_NON_DOCKER}" ] && endSkipping
}


testMetadata() {
    which scw-metadata >/dev/null
    returnCode=$?
    assertEquals "scw-metadata not found" 0 $returnCode

    [ -n "${SKIP_NON_DOCKER}" ] && startSkipping
    test -n "$(scw-metadata --cached)"
    returnCode=$?
    assertEquals "Cannot fetch metadata" 0 $returnCode

    local private_ip=$(ip addr list eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    local metadata_ip=$(scw-metadata --cached PRIVATE_IP)
    assertEquals "PRIVATE_IP from metadata does not match eth0" $private_ip $metadata_ip
    [ -n "${SKIP_NON_DOCKER}" ] && endSkipping
}


testHostname() {
    [ -n "${SKIP_NON_DOCKER}" ] && startSkipping
    local metadata_hostname=$(scw-metadata --cached HOSTNAME)
    local local_hostname=$(hostname -f)
    assertEquals "HOSTNAME from metadata not matching with local hostname" $metadata_hostname $local_hostname
    [ -n "${SKIP_NON_DOCKER}" ] && endSkipping
}


testSysctl() {
    [ -n "${SKIP_NON_DOCKER}" ] && startSkipping
    assertEquals "sysctl vm.min_freekbytes misconfigured" $(sysctl -n vm.min_free_kbytes) 65536
    [ -n "${SKIP_NON_DOCKER}" ] && endSkipping
}


testXnbdClient() {
    which xnbd-client >/dev/null
    returnCode=$?
    assertEquals "xnbd-client not found" 0 $returnCode
}


testOcsRelease() {
    [ -n "${SKIP_NON_DOCKER}" ] && startSkipping
    test -f /etc/ocs-release
    returnCode=$?
    assertEquals "/etc/ocs-release does not exist" 0 $returnCode
    [ -n "${SKIP_NON_DOCKER}" ] && endSkipping
}


testTty() {
    [ -n "${SKIP_NON_DOCKER}" ] && startSkipping
    test -n "$(ps auxwww | grep getty | grep ttyS0 | grep 9600 | grep vt102)"
    returnCode=$?
    assertEquals "No such getty instance on ttyS0" 0 $returnCode

    test -z "$(ps auxwww | grep getty | grep tty1)"
    returnCode=$?
    assertEquals "Useless getty instance on tty1" 0 $returnCode
    [ -n "${SKIP_NON_DOCKER}" ] && endSkipping
}


testSshd() {
    grep '^PermitRootLogin without-password$' /etc/ssh/sshd_config >/dev/null
    returnCode=$?
    assertEquals "Accepting ssh with password" 0 $returnCode
}


. shunit2
