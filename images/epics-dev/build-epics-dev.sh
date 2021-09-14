#!/bin/bash
if which docker 2>/dev/null; then
    DOCKER=docker
else
    DOCKER=podman
fi

set -x
${DOCKER} build\
    --network host\
    --build-arg DEV_UID=37630\
    --build-arg DEV_GID=37795\
    --build-arg DEV_UNAME=k8s-epics-iocs\
    --build-arg FULLNAME=k8s-epics-iocs\
    --build-arg EMAIL="k8s-epics-iocs@epics-containers.github"\
    -t dev .

