#!/bin/bash
echo "enter some parameters for git config"

if which git 2>/dev/null; then
    FULLNAME=$(git config --global user.name)
    EMAIL=$(git config --global user.email)
fi

if [ -z "$EMAIL" ]; then
    read -p "Enter fullname: "  FULLNAME
    read -p "Enter email: "  EMAIL
fi

set -x
podman build\
    $ARGS\
    --network host\
    --build-arg DEV_UID=$(id -u)\
    --build-arg DEV_GID=$(id -g)\
    --build-arg DEV_UNAME=$(whoami)\
    --build-arg FULLNAME="${FULLNAME}"\
    --build-arg EMAIL="${EMAIL}"\
    -t dev-c7 .

