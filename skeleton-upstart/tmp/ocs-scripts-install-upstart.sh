#!/bin/bash

set -xe

cat /etc/lsb-release | grep -i trusty >/dev/null && ln -s /etc/init.d/disconnectnbd /etc/rc6.d/S89disconnectnbd
cat /etc/lsb-release | grep -i utopic >/dev/null && update-rc.d disconnectnbd defaults
