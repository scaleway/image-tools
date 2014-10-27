#!/bin/bash

tar --strip=2 -C / -xzvf <(wget -qO - https://github.com/online-labs/ocs-scripts/archive/master.tar.gz)
