#!/bin/bash

# source this script to enable access to argus kubernetes cluster
# and setup the functions to deploy and mananage iocs in that cluster

# WARNING this script is specific to the DLS argus cluster
# WARNING please use as an example as to how to configure a cluster
# TODO deprecate this script and write HowTo Documentation instead

export k8sdir=$(realpath $(dirname ${BASH_SOURCE[0]}))

if [  "$0" == "${BASH_SOURCE[0]}" ]
then
  echo "you must source this script for it to work correctly"
  exit 1
fi

if [ -z "$(which docker 2> /dev/null)" ]
then
    shopt -s expand_aliases
    alias docker='podman'
    if which module; then
        module load argus
    fi
fi

kubectl config set-context --current --namespace=epics-iocs

. ${k8sdir}/kube-functions.sh


# guess which IP addresses the IOCs will run on (wont be required when networkHost enabled pods are in the same subnet on a beamline)
export EPICS_CA_ADDR_LIST="172.23.168.2 172.23.168.3 172.23.168.4 172.23.168.5 172.23.168.6 172.23.168.7 172.23.168.8 172.23.168.9 172.23.168.10 172.23.168.11 172.23.168.12 172.23.168.13 172.23.168.14 172.23.168.15 172.23.168.16 172.23.168.17 172.23.168.18 172.23.168.19 172.23.168.20 172.23.168.21 172.23.168.22"
