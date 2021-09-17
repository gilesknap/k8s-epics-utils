#!/bin/bash
module load gcloud

image=gcr.io/diamond-pubreg/controls/dev-c7:latest

environ="-e DISPLAY -e HOME"
volumes="-v /dls_sw/prod:/dls_sw/prod \
        -v /dls_sw/work:/dls_sw/work \
        -v /dls_sw/epics:/dls_sw/epics \
        -v /dls_sw/apps:/dls_sw/apps \
        -v /dls_sw/etc:/dls_sw/etc \
        -v /scratch:/scratch \
        -v ${HOME}:${HOME}"
devices="-v /dev/ttyS0:/dev/ttyS0"
opts="--net=host --rm -ti --hostname podman"
x11opts="-v /dev/dri:/dev/dri --security-opt=label=type:container_runtime_t"

# -l loads profile and bashrc
command="/bin/bash -l"

podman run ${environ} ${x11opts} ${volumes} ${devices} ${@} ${opts} ${image} ${command}
