# Dockerfile for getting DLS RHEL7 dev environment working in a container
# hosted on RHEL8
#
# This is a stopgap so that we can use effort to promote the
# kubernetes model https://github.com/epics-containers instead of spending
# effort in rebuilding our toolchain for RHEL8

FROM centos:7

# dev tools and libraries
RUN yum update -y && \
    yum groupinstall -y "Development Tools" && \
    yum install -y redhat-lsb-core libusbx net-snmp-libs environment-modules git2u net-tools screen lapack-devel

# edm dependencies
RUN yum install -y epel-release && \
    yum install -y giflib-devel libXmu-devel libpng-devel libXtst-devel zlib-devel xorg-x11-proto-devel motif-devel libX11-devel libXp-devel libXpm-devel

# QT4 dependencies
ENV QT_X11_NO_MITSHM=1
RUN yum install -y pyqt4-devel PackageKit-gtk3-module libcanberra-gtk2

# environment
ENV LANG=en_GB.UTF-8

# fun stuff
RUN yum install -y dia
