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

start the container
-------------------

To start the devcontainer:

    ./run-dev.sh

work as usual
-------------

You will now have a prompt inside of the developer container. You will be
running as root but file access to the host filesystem
will use your own user id. These host filesystem folders are mounted.

    - Your home directory
    - /scratch
    - dls_sw/*  (or at least those dls_sw mounts needed by a controls dev)

You could add further mounts as required by editing a copy of run-dev.sh.

You are free to yum install anything and to modify any of the files inside
the container but these changes will only last for the lifetime of the
container (this restriction can be lifted by using container commits but
you would need to remove the --rm argument in run-dev.sh).

VSCode integration
==================

VSCode has beautiful integration for developing in containers. However to make
it work with podman requires a little persuasion.

I believe this will only work on RHEL8. The earlier version of podman on RHEL7
does not have the correct API.

Execute these commands:

    sudo yum install podman-docker
    systemctl --user enable --now podman.socket

Add the following to  /home/[YOUR USER NAME]/.config/Code/User/settings.json

    "docker.dockerodeOptions": {
        "socketPath": "/run/user/[YOUR USER ID]/podman/podman.sock"
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

UNFORTUNATELY: run-dev.sh uses --userns=keep-id to give you your native user id
inside and outside of the container. With VSCode integration this starts the
container OK but fails when VSCode tries to exec a service in the container.
Therefore we drop this option in .devcontainer.json and you will run as root
inside the VSCode terminals. Only noticeable side affect at present is that
ssh keys don't work and therefore you cannot push to github.

