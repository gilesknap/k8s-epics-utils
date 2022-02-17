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
    yum install -y glibc.i686 redhat-lsb-core libusbx net-snmp-libs environment-modules git2u net-tools screen cmake lapack-devel readline-devel pcre-devel boost-devel libpcap-devel numactl-libs vim dbus-x11 bind-utils libssh2-devel

# edm dependencies
RUN yum install -y epel-release && \
    yum install -y giflib-devel libXmu-devel libpng-devel libXtst-devel zlib-devel xorg-x11-proto-devel motif-devel libX11-devel libXp-devel libXpm-devel libtirpc-devel

# areaDetector dependencies
RUN yum install -y libxml2-devel libjpeg-turbo-devel libtiff-devel

# Odin dependencies
RUN yum install -y zeromq-devel librdkafka-devel

# QT4 dependencies
ENV QT_X11_NO_MITSHM=1
RUN yum install -y pyqt4-devel PackageKit-gtk3-module libcanberra-gtk2 xcb-util xcb-util-devel libxcb.x86_64 libxkbcommon-x11

# environment
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV MODULEPATH=/etc/scl/modulefiles:/etc/scl/modulefiles:/etc/scl/modulefiles:/usr/share/Modules/modulefiles:/etc/modulefiles:/usr/share/modulefiles:/dls_sw/apps/Modules/modulefiles:/dls_sw/etc/modulefiles:/home/hgv27681/privatemodules:/dls_sw/prod/tools/RHEL8-x86_64/defaults/modulefiles

# fun stuff
RUN yum install -y dia

# git 2.23
RUN sudo yum -y install wget  && \
    export VER="2.32.0" && \
    wget https://github.com/git/git/archive/v${VER}.tar.gz && \
    tar -xvf v${VER}.tar.gz && \
    rm -f v${VER}.tar.gz && \
    cd git-* && \
    make configure && \
    ./configure --prefix=/usr && \
    make && \
    make install

# allow all users inside the container to sudo
RUN yum -y install sudo
COPY /sudoers /etc/sudoers
