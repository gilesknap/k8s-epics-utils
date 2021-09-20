# epics developer Docker image
# a complete development environment for EPICS iocs and support modules

#ARG BASE_IMAGE=ghcr.io/epics-containers/epics-modules:main
ARG BASE_IMAGE=gcr.io/diamond-pubreg/controls/dev-c7:latest

FROM ${BASE_IMAGE}
USER root

# set up your own account in the image
ARG DEV_UNAME
ARG DEV_UID
ARG DEV_GID

# create a user with same ids as the developer building this image
RUN groupadd -g $DEV_GID -o $DEV_UNAME && \
    useradd -m -u $DEV_UID -g $DEV_GID -o -s /bin/bash $DEV_UNAME

WORKDIR /

# install kafka client library
RUN git clone https://github.com/edenhill/librdkafka.git && \
    cd librdkafka && \
    ./configure && \
    make && \
    alias perf=/librdkafka/examples/rdkafka_performance

########################## switch to developer user ###########################
USER ${DEV_UNAME}
WORKDIR /home/${DEV_UNAME}

# make DLS profile loading work
ENV DLS_NETWORK=YES
CMD ["/bin/bash -l"]
