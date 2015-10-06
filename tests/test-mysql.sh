#!/bin/sh

dpkg -l | grep -q -i mysql-server || exit 0

if [ `echo SELECT 1 | mysql --skip-column-names` != "1" ];
then
    echo "mysql binary is expected to connect to the database without arguments. Does /root/.my.cnf exist and is valid?" >&2
    exit 1
fi
