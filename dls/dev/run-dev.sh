#!/bin/bash

image=dev:latest
environ="-e DISPLAY"
volumes="-v /dls_sw/prod:/dls_sw/prod -v /dls_sw/work:/dls_sw/work -v /dls_sw/etc:/dls_sw/etc -v /scratch/${USER}:/scratch/${USER}"
opts="--net=host --rm -ti"
x11opts="-v /dev/dri:/dev/dri --security-opt=label=type:container_runtime_t"

set -x
podman run ${environ} ${x11opts} ${volumes} ${@} ${opts} ${image}

