#!/bin/bash

BRANCH=${BRANCH:-master}

wget https://raw.githubusercontent.com/scaleway/image-tools/${BRANCH}/scripts/docker-rules.mk
