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
opts="--net=host --privileged --hostname cdev"
# identity="--security-opt=label=type:container_runtime_t"
all_params="${environ} ${volumes} ${devices} ${opts} ${identity}"

# utility functions ############################################################

function get-image-name()
{
    # all cdev functions are intended to be run inside of a clone of 
    # a container build project hosted on github.
    #
    # This function determines the github container registry name from
    # the remote name and also generates a container name to use
    # from the local root folder name of the clone
    
    # extract remote git repo to determine ghcr image tag
    image_repo=$(git remote -v 2> /dev/null | sed -e 's/.*github.com:\(.*\)\.git.*/\1/' -e 1q)
    if [ -z "${image_repo}" ] ; then
        echo -e "\nERROR: This function must be run in a clone of a github container project"
        return 1
    fi
    image_tag_base=ghcr.io/${image_repo}
    image_tag=${image_tag_base}:work

    # use root folder basename for container name
    repo_root=$(git rev-parse --show-toplevel)
    container_name=$(basename ${repo_root})

    if [ "${1}" != "prep" ] && [ -z $(podman images -q ${image_tag}) ] ; then
        echo -e "\nERROR: the image ${image_tag} does not exist"
        echo "please run cdev-prep"
        return 1
    fi
}

# user cdev- functions #########################################################

function cdev-prep()
{
    if ! get-image-name "prep"; then return 1; fi

    echo "devcontiner name is ${container_name}"

    # if the work image tag does not yet exist then pull the latest one and tag
    if [ -z $(podman images -q ${image_tag}) ] ; then
        if ! podman pull ${image_tag_base}:main; then
            echo -e "\nERROR: the remote image ${image_tag} does not exist."
            echo "verify that this project has a released container with tag 'main'"
            return 1
        fi
        podman tag ${image_tag_base}:main ${image_tag}
    fi

    # extract the repos folder so that changes are persisted in the host filesystem
    echo "copying container /repos to ${repo_root}/repos ..."
    podman run --rm --privileged -v ${repo_root}/repos:/copy ${image_tag} rsync -a /repos/ /copy
}

function cdev-launch
{  
    if ! get-image-name; then return 1; fi

    options="${1}"; args="${2}"
    
    if [ "$(podman ps -q -f name=${container_name})" ]; then
        : # container already running so no prep required
    elif [ "$(podman ps -qa -f name=${container_name})" ]; then
        # start the stopped container
        ( 
            set -x; 
            podman start ${container_name}
        )
    else
        # create a new background container making process 1 be 'sleep'
        ( 
            set -x; 
            podman run -d --name ${container_name} ${all_params} ${image_tag} sleep 100d
        )
    fi
    # run a shell in the container - this allows multiple shells and avoids using 
    # process 1 so users can exit the shell without killing the container
    ( 
        set -x; 
        podman exec -it ${container_name} bash
    )
}

function cdev-ioc-launch()
{   
    if [ -z "${1}" ] || [ ! -f "${1}/values.yaml" ] ; then 
        echo "usage: cdev-launch-ioc <ioc helm chart folder>"; return 1; fi

    root="${1}"; shift 1
    container_name=$(basename "${root}")

    # get image root name from the values file
    image=$(grep base_image ${root}/values.yaml | awk '{print $2}' | sed 's/:.*//')
    # get the ioc folder from the values file
    ioc_folder=$(grep iocFolder ${root}/values.yaml | awk '{print $2}')
    # get the most recent local tag for image
    tag="${image}:work"


    if [ -z $(podman images -q ${tag}) ] ; then
        echo -e "\nERROR: requires 'work' tag applied to ${tag}"
        return 1; 
    fi

    config="-v $(realpath ${root})/config:${ioc_folder}/config"
    ( 
        set -x; 
        # execute the IOC and drop back to bash on exit
        podman run --rm -it ${config} ${all_params} --name ${container_name} \
          ${tag} bash -c "bash ${ioc_folder}/config/start.sh; bash"
    )
}

function cdev-debug-last-build()
{   
    # get the most recently built image name from cache 
    last_image=$(podman images | awk '{print $3}' | awk 'NR==2')    
    ( 
        set -x; 
        podman run -it --name debug_build --rm ${all_params} ${last_image}
    ) 
}

function cdev-stop()
{
    if ! get-image-name; then return 1; fi

    # free up resources but keep the container so you can come back to it
    podman stop ${container_name}
}

function cdev-rm()
{
    if ! get-image-name; then return 1; fi

    # free up resources but keep the container so you can come back to it
    podman container rm -f ${container_name}
}

