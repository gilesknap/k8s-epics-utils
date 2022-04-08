#!/bin/bash

export devdir=$(realpath $(dirname ${BASH_SOURCE[0]}))

if [  "$0" == "${BASH_SOURCE[0]}" ]
then
  echo "you must source this script for it to work correctly"
  exit 1
fi

if [ -z $(which podman 2> /dev/null) ]
then
    # use podman if we dont see docker installed
    shopt -s expand_aliases
    alias podman='docker'
fi

# parameters for launching containers
environ="-e DISPLAY -e HOME"
volumes="-v /scratch:/scratch -v ${HOME}:${HOME}"
# devices="-v /dev/ttyS0:/dev/ttyS0 -v /dev/dri:/dev/dri"
opts="--net=host -ti --hostname cdev"
# identity="--security-opt=label=type:container_runtime_t"
all_params="${environ} ${volumes} ${devices} ${opts} ${identity}"

# utility functions

# user cdev- functions

function cdev-launch
{  
    if [ -z ${2} ] ; then 
        echo "usage: cdev-debug-last-build <image name> <container name>"
       return 1
    fi

    image="${1}"
    name="${2}"
    shift 2

    if [ "$(podman ps -q -f name=${name})" ]; then
        echo "attaching to running container ${name}"
        ( 
            set -x; 
            podman attach ${name} "${@}"
        )
    elif [ "$(podman ps -qa -f name=${name})" ]; then
        echo "launching existing stopped container ${name}"
        ( 
            set -x; 
            podman start --attach ${name} "${@}"
        )
    else
        echo "creating new container ${name}"
        ( 
            set -x; 
            podman run --name ${name} ${all_params} "${@}" ${image} bash
        )
    fi
}

function cdev-debug-last-build()
{   
    if [ -z ${1} ] ; then 
        echo "usage: cdev-debug-last-build <container name>"
       return 1
    fi
    if [ "$(podman ps -qa -f name=${1})" ]; then
        echo "container name exists. please choose a new unique name"
        return 1
    fi

    last_image=$(podman images | awk '{print $3}' | awk 'NR==2')
    cdev-launch ${last_image} ${1} 
}

