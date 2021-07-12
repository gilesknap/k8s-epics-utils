#!/bin/bash

if [ -z $(which docker 2> /dev/null) ]
then
    # try podman if we dont see docker installed
    shopt -s expand_aliases
    alias docker='podman'
    opts= "--privilege "
fi

set -x
docker run  ${opts} \
       -it --rm --name ca-forwarder \
       -v ~/.kube:/.kube/ \
       -e  KUBECONFIG=$(echo $KUBECONFIG | sed s=${HOME}/==g)\
       --network=host \
       gilesknap/ca-forwarder
