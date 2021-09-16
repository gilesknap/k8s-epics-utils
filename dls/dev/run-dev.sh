#!/bin/bash

mkdir -p /scratch/${USER}/work

image=dev:latest
path="-e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/epics/epics-base/bin/linux-x86_64:/dls_sw/prod/tools/RHEL7-x86_64/defaults/bin"
environ="-e DISPLAY"
volumes="-v /dls_sw/prod:/dls_sw/prod \
        -v /dls_sw/work:/dls_sw/work \
        -v /dls_sw/epics:/dls_sw/epics \
        -v /dls_sw/etc:/dls_sw/etc -v /scratch/${USER}/work:/local \
        -v /home/${USER}/.ssh:/home/${USER}/.ssh \
        -v /home/${USER}/.bash_history:/home/${USER}/.bash_history"
opts="--net=host --rm -ti"
x11opts="-v /dev/dri:/dev/dri --security-opt=label=type:container_runtime_t"

set -x
podman run ${path} ${environ} ${x11opts} ${volumes} ${@} ${opts} ${image}

