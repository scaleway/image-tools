#!/bin/bash

testRootPasswd() {
    grep 'root:\*\?:' /etc/shadow >/dev/null
    returnCode=$?
    assertEquals "User root has a setted password" 0 $returnCode
}


testKernelModules() {
    test -d "/lib/modules/$(uname -r)/kernel"
    returnCode=$?
    assertEquals "Kernel modules not downloaded" 0 $returnCode
}


testMetadata() {
    which oc-metadata >/dev/null
    returnCode=$?
    assertEquals "oc-metadata not found" 0 $returnCode

    test -n "$(oc-metadata --cached)"
    returnCode=$?
    assertEquals "Cannot fetch metadata" 0 $returnCode

    local private_ip=$(ip addr list eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    local metadata_ip=$(oc-metadata --cached PRIVATE_IP)
    assertEquals "PRIVATE_IP from metadata does not match eth0" $private_ip $metadata_ip
}


testHostname() {
    local metadata_hostname=$(oc-metadata --cached HOSTNAME)
    local local_hostname=$(hostname -f)
    assertEquals "HOSTNAME from metadata not matching with local hostname" $metadata_hostname $local_hostname
}


testSysctl() {
    assertEquals "sysctl vm.min_freekbytes misconfigured" $(sysctl -n vm.min_free_kbytes) 65536
}


testXnbdClient() {
    which xnbd-client >/dev/null
    returnCode=$?
    assertEquals "xnbd-client not found" 0 $returnCode
}


testOcsRelease() {
    test -f /etc/ocs-release
    returnCode=$?
    assertEquals "/etc/ocs-release does not exist" 0 $returnCode
}


. shunit2
