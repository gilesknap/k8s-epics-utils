# install edm for displaying OPI screens
# this is a temporary approach to getting OPI - in future it will be served
# out of the IOC container over HTTP

# This container to be run locally with a command like this:
# docker run --network host --dns=127.0.0.53 -v /tmp:/tmp -i edm <your edm screen>
ARG BASE_IMAGE=ghcr.io/epics-containers/epics-base:7.0.5r2.0

FROM ${BASE_IMAGE}
USER root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    libpacklib-lesstif1-dev \
    libxpm-dev  \
    libxt-dev \
    libx11-dev \
    libxmu-dev \
    libxtst-dev \
    libgif-dev

USER ${USERNAME}

RUN mkdir -p ${EPICS_ROOT}/tools && \
    cd ${EPICS_ROOT}/tools && \
    git clone -b ubuntu20 https://gitlab.diamond.ac.uk/controls/tools/edm.git && \
    cd edm && \
    sed -ie "s+^EPICS_BASE=.*+EPICS_BASE=${EPICS_BASE}+" configure/RELEASE

RUN cd ${EPICS_ROOT}/tools/edm && \
    make  CMD_CXXFLAGS=-std=c++98 MOTIF_LIB=/usr/lib/x86_64-linux-gnu X11_LIB=/usr/lib/x86_64-linux-gnu && \
    make CMD_CXXFLAGS=-std=c++98 clean

ENTRYPOINT ["bash", "-c", "/epics/tools/edm/bin/linux-x86_64/edm"]
