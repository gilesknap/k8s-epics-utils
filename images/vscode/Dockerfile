FROM gitpod/openvscode-server:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    python3.8 \
    python3-pip

RUN pip3 install pipenv


USER openvscode-server
