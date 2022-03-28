#!/bin/bash

# A script for launching 'RHEL 7 in a Box' on a DLS workstation

# NOTE that changes to this file should also be propgated to .devcontainer.json

# use local virtual environments to make pipenv projects portable between
# workstations, servers and containers
export PIPENV_VENV_IN_PROJECT=enabled

# enable gcloud for authentication to gcr.io
module load gcloud

image=gcr.io/diamond-pubreg/controls/dev-c7:latest

environ="-e DISPLAY -e HOME"
volumes="-v /dls_sw/prod:/dls_sw/prod \
        -v /dls_sw/work:/dls_sw/work \
        -v /dls_sw/epics:/dls_sw/epics \
        -v /dls/science:/dls/science \
        -v /dls/detectors:/dls/detectors \
        -v /dls_sw/targetOS/vxWorks/Tornado-2.2:/dls_sw/targetOS/vxWorks/Tornado-2.2 \
        -v /dls_sw/apps:/dls_sw/apps \
        -v /dls_sw/etc:/dls_sw/etc \
        -v /scratch:/scratch \
        -v ${HOME}:${HOME}"
devices="-v /dev/ttyS0:/dev/ttyS0 -v /dev/dri:/dev/dri"
opts="--net=host --rm -ti --hostname dev-c7"
# this should keep original groups assignment but does not (so we cant write in work)
identity="--security-opt=label=type:container_runtime_t --annotation run.oci.keep_original_groups=1 --userns=keep-id"

# -l loads profile and bashrc
command="/bin/bash -l"

podman run ${environ} ${identity} ${volumes} ${devices} ${@} ${opts} ${image} ${command}
