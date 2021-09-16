# Dockerfile for getting DLS RHEL7 dev environment working in a container
# hosted on  RHEL8
#
# This is a stopgap so that we can use effort to promote the
# kubernetes model https://github.com/epics-containers instead of spending
# effort in rebuilding our toolchain for RHEL8

FROM centos:7

ENV INSTALL PyQt4.x86_64 redhat-lsb-core libusbx net-snmp-libs

# install dev tools and libraries
RUN yum update -y && \
    yum groupinstall -y "Development Tools" && \
    yum install -y ${INSTALL}

# install edm related dependencies
ENV XLIBS giflib-devel libXmu-devel libpng-devel libXtst-devel zlib-devel xorg-x11-proto-devel motif-devel libX11-devel libXp-devel libXpm-devel

RUN yum install -y epel-release && \
    yum install -y ${XLIBS}

# additional WIP bits
RUN yum install -y net-tools environment-modules-3.2.10-10.el7.x86_64
