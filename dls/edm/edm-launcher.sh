#!/bin/bash

module load gcloud

image=gcr.io/diamond-pubreg/controls/python3/s03_utils/epics/edm:latest
path="-e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/dls_sw/epics/R3.14.12.7/base/bin/linux-x86_64:/dls_sw/prod/tools/RHEL7-x86_64/defaults/bin"
environ="-e DISPLAY -e EDMDATAFILES"
volumes="-v /dls_sw/prod:/dls_sw/prod \
        -v /dls_sw/work:/dls_sw/work \
        -v /dls_sw/etc:/dls_sw/etc"
opts="--net=host --rm -ti"
x11opts="-v /dev/dri:/dev/dri --security-opt=label=type:container_runtime_t"

set -x
podman run ${path} ${environ} ${x11opts} ${volumes} ${@} ${opts} ${image} bash -c "best-launcher -k"
