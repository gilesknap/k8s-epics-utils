# EPICS 7 Base Dockerfile
FROM bitnami/kubectl:latest

USER root

# install dependencies for python and setcap
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    git \
    libcap2-bin \
    net-tools \
    python3-pip \
    python3 \
    python3-setuptools

# install python libraries
RUN pip3 install setuptools scapy kubernetes

# enable raw network capability in python
RUN setcap cap_net_raw+ep $(readlink -f $(which python3))

# install krew so we can get oidc-login
RUN ( \
    set -x; cd "$(mktemp -d)" &&\
    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&\
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&\
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&\
    tar zxvf krew.tar.gz &&\
    KREW=./krew-"${OS}_${ARCH}" &&\
    "$KREW" install krew\
    )

# install oidc-login
RUN /.krew/bin/kubectl-krew install oidc-login
ENV PATH=${PATH}:/.krew/bin

# add the python script
COPY ca-forwarder.py .

ENTRYPOINT [ "bash" ]
CMD ["-c", "kubectl version && python3 ca-forwarder.py --namespace epics-iocs"]
