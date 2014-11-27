#!/bin/bash


cat /etc/lsb-release | grep -i trusty >/dev/null && ln -s /etc/init.d/disconnectnbd /etc/rc6.d/S89disconnectnbd
cat /etc/lsb-release | grep -i utopic && update-rc.d disconnectnbd defaults
