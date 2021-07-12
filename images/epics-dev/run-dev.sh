#!/bin/bash

if which docker 2>/dev/null
then
    DOCKER=docker
else
    DOCKER=podman
fi

${DOCKER} run --network host --dns=127.0.0.53 -v /tmp:/tmp -it dev
