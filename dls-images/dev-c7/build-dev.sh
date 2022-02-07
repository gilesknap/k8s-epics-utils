#!/bin/bash

if [ -z "${1}" ] ; then
    echo 'please supply a version tag as param 1 e.g. build-dev.sh 1.0'
else

    module load gcloud

    set -e
    podman build\
        --network host\
        -t gcr.io/diamond-pubreg/controls/dev-c7:${1} .

    read -r -p "dev-c7 built OK. Push to gcr.io/diamond-pubreg [y/N] " response
    response=${response,,}    # tolower
    if [[ "$response" =~ ^(yes|y)$ ]] ; then
        podman push gcr.io/diamond-pubreg/controls/dev-c7:${1}
    fi
fi
