# TODO this is not working
#

ARG BASE_IMAGE=ghcr.io/epics-containers/epics-base:7.0.5r2.0

FROM python:3.9-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    git \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/areaDetector/ADViewers.git

RUN pip install numpy pyqtgraph pyqt5 matplotlib pyqt5 qtpy pvapy

WORKDIR /ADViewers/Python/PY_NTNDA_Viewer

ENTRYPOINT ["python3", "PVAPY_NTNDA_Viewer.py"]

