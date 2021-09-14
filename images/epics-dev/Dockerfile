# epics developer Docker image
# a complete development environment for EPICS iocs and support modules

ARG BASE_IMAGE=ghcr.io/epics-containers/epics-modules:main

FROM ${BASE_IMAGE}
USER root


# install extra dependecies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    bash-completion \
    busybox-static \
    curl \
    gnupg \
    less \
    python3 \
    ssh \
    sudo \
    tcpdump \
    vim

# set up your own account in the image
ARG DEV_UNAME
ARG DEV_UID
ARG DEV_GID
ARG EMAIL
ARG FULLNAME
ENV EMAIL=${EMAIL}
ENV FULLNAME=${FULLNAME}

RUN \
    : ${DEV_UNAME:? Build argument DEV_UNAME not set.} \
    : ${EMAIL:? Build argument EMAIL not set.} \
    : ${FULLNAME:? Build argument FULLNAME not set.}

WORKDIR /

# create a user with same ids as the developer building this image ()
RUN if [ ${FULLNAME} != k8s-epics-iocs ] ; \
    then groupadd -g $DEV_GID -o $DEV_UNAME && \
    useradd -m -u $DEV_UID -g $DEV_GID -o -s /bin/bash $DEV_UNAME ; \
    fi && \
    usermod -aG sudo ${DEV_UNAME} && \
    echo "${DEV_UNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${DEV_UNAME} && \
    busybox --install

# install kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
    sudo touch /etc/apt/sources.list.d/kubernetes.list  && \
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list && \
    sudo apt-get update && \
    sudo apt-get install -y kubectl

# # install helm
# RUN curl --silent --show-error --fail --location --output get_helm.sh \
#     https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get && \
#     chmod 700 get_helm.sh && \
#     ./get_helm.sh --version v3.5.3 && \
#     rm get_helm.sh && \
#     helm version

# install gcloud
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-339.0.0-linux-x86_64.tar.gz && \
    tar xf google-cloud-sdk-339.0.0-linux-x86_64.tar.gz && \
    ./google-cloud-sdk/install.sh -q

# install kafka client library
RUN git clone https://github.com/edenhill/librdkafka.git && \
    cd librdkafka && \
    ./configure && \
    make && \
    alias perf=/librdkafka/examples/rdkafka_performance

########################## switch to developer user ###########################
USER ${DEV_UNAME}

# install krew in order to get oidc-login plugin for kubectl
RUN cd "$(mktemp -d)" && \
    OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" && \
    tar zxvf krew.tar.gz && \
    KREW=./krew-"${OS}_${ARCH}" && \
    "$KREW" install krew && \
    ${HOME}/.krew/bin/kubectl-krew install oidc-login

ENV PATH=${PATH}:/home/${DEV_UNAME}/bin:/home/${DEV_UNAME}/.krew/bin

# create a dummy ioc startup for experimentation
COPY --chown=${DEV_UID}:${DEV_GID} config ${SUPPORT}/ioc/config

# setup the container's home dirctory
COPY --chown=${DEV_UID}:${DEV_GID} home /home/${DEV_UNAME}
WORKDIR /home/${DEV_UNAME}
RUN bash .setup_home.sh

CMD ["/bin/bash"]



