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

. shunit2
