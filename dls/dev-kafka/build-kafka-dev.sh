#!/bin/bash
if which docker 2>/dev/null; then
    DOCKER=docker
else
    DOCKER=podman
fi

set -x
${DOCKER} build\
    --network host\
    --build-arg DEV_UID=37631\
    --build-arg DEV_GID=37798\
    --build-arg DEV_UNAME=k8s-controls-kafka\
    -t gcr.io/diamond-pubreg/controls/dev-kafka .

