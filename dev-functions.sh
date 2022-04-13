#!/bin/bash

export devdir=$(realpath $(dirname ${BASH_SOURCE[0]}))

if [  "$0" == "${BASH_SOURCE[0]}" ]
then
  echo "you must source this script for it to work correctly"
  exit 1
fi

if [ -z $(which podman 2> /dev/null) ]
then
    # use docker if we dont see podman installed
    shopt -s expand_aliases
    alias podman='docker'
fi

# parameters for launching containers ##########################################
unset environ volumes devices opts identity
environ="-e DISPLAY -e HOME"
volumes="-v /tmp:/tmp -v ${HOME}:${HOME}"
devices="-v /dev/ttyS0:/dev/ttyS0"
opts="--net=host --privileged -ti --hostname cdev"
# identity="--security-opt=label=type:container_runtime_t"
all_params="${environ} ${volumes} ${devices} ${opts} ${identity}"

# utility functions ############################################################

# user cdev- functions #########################################################

function cdev-launch
{  
    if [ -z ${2} ] ; then 
        echo "usage: cdev-launch <image name> <container name>"; return 1; fi

    image="${1}"; name="${2}"; options="${3}"; args="${4}"

    if [ "$(podman ps -qa -f name=${name})" ]; then
        echo "The container name exists. Please choose a new unique name"
        echo "or connect to an exisiting container with cdev-connect."
        return 1
    elif [ podman volume exists ${name} ]; then
        echo "WARNING: reconnecting to existing volume ${name}"
    fi

    # NOTE that all containers must place all source below /repos
    volume="-v ${name}:/repos"

    ( 
        set -x; 
        podman run --name ${name} ${volume} ${all_params} ${options} ${image} ${args}
    )
}

function cdev-connect
{  
    if [ -z ${1} ] ; then 
        echo "usage: cdev-connect <container name>"; return 1; fi

    name="${1}"; shift 1

    if [ "$(podman ps -q -f name=${name})" ]; then
        echo "attaching to running container ${1}"
        ( 
            set -x; 
            podman attach ${name} "${@}"
        )
    elif [ "$(podman ps -qa -f name=${name})" ]; then
        echo "launching existing stopped container ${1}"
        ( 
            set -x; 
            podman start --attach ${name} "${@}"
        )
    fi
}

function cdev-launch-ioc()
{   
    if [ -z ${2} or not -d ${1} ] ; then 
        echo "usage: cdev-launch-ioc <ioc helm chart folder> <container name>"; return 1; fi

    root=${1}; name=${2}; shift 2

    # get image root name from the values file
    image=$(grep base_image iocs/bl45p-mo-ioc-01/values.yaml | awk '{print $2}' | sed 's/:.*//')
    # get the ioc folder from the values file
    ioc_folder=$(iocFolder iocs/bl45p-mo-ioc-01/values.yaml | awk '{print $2}')

    cdev-launch ${image} ${1} 
}

function cdev-debug-last-build()
{   
    if [ -z ${1} ] ; then 
        echo "usage: cdev-debug-last-build <container name>"; return 1; fi

    name=${1}; shift 1

    last_image=$(podman images | awk '{print $3}' | awk 'NR==2')
    cdev-launch ${last_image} ${name} "${@}"
}

function cdev-rm()
{
    if [ -z ${1} ] ; then 
        echo "usage: cdev-rm <container name>"; return 1; fi

    name=${1}; shift 1

    if [ $(podman ps -qa -f name=${name}) ]; then 
        podman container rm ${name}
    fi
    if podman volume exists ${name} ; then 
        podman volume rm ${name}
    fi
}

