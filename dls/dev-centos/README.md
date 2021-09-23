DLS RHEL7 in a Box Developer Container
======================================

A Diamond Light Source specific developer container.

The launcher script is specific to machines that have /dls and /dls_sw mounted so intended for running on DLS workstations only.

This is for getting DLS RHEL7 dev environment working in a container hosted on  RHEL8.

This is a stopgap so that we can use effort to promote the kubernetes model https://github.com/epics-containers instead of using effort in rebuilding our toolchain for RHEL8.

How to use
==========

These instructions will work for a RHEL8 or RHEL7 DLS workstation (or
any linux workstation that has /dls_sw and /scratch mounted)

configure podman
----------------
For first time use only:

    /dls_sw/apps/setup-podman/setup.sh

To start the devcontainer:

    ./run-dev.sh

VSCode integration
==================

VSCode has beautiful integration for developing in containers. However to make
it work with podman requires a little persuasion.

I believe this will only work on RHEL8. The earlier version of podman on RHEL7
does not have the correct API.

Execute these commands:

    sudo yum install podman-docker
    systemctl --user enable --now podman.socket

Add the following to  /home/<YOUR USER NAME>/.config/Code/User/settings.json

    "docker.dockerodeOptions": {
        "socketPath": "/run/user/<YOUR USER ID>/podman/podman.sock"
    },

(you can find your uid with the `id` command)

Run up vscode and install the remote development plugin:

    module load vscode
    code
    <control><shift>P
    ext install ms-vscode-remote.vscode-remote-extensionpack

Finally drop the file `.devcontainer.json` into the root folder of a project
and open that folder with VSCode. You will be prompted to reopen the project
in a container.

