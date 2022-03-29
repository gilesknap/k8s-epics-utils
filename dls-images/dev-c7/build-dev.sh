#!/bin/bash

name=gcr.io/diamond-pubreg/controls/dev-c7

if [ -z ${1} ] ; then
    echo usage: build-dev.sh '<new version number>'
    echo look here to see the current versions http://${name}
    exit 1
fi

set -e
podman build\
    --network host\
    -t ${name}:latest .

module load gcloud

read -r -p "dev-c7 built OK. Push to ${name}:${1} [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]] ; then
    podman tag ${name}:latest ${name}:${1}
    podman push ${name}:latest
    podman push ${name}:${1}
fi
