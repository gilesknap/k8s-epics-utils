#!/bin/bash

set -e
podman build\
    --network host\
    -t gcr.io/diamond-pubreg/controls/dev-c7 .

module load gcloud

read -r -p "dev-c7 built OK. Push to gcr.io/diamond-pubreg [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]] ; then
    podman push gcr.io/diamond-pubreg/controls/dev-c7
fi