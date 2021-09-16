# Dockerfile for building EDM. Includes edm executable in PATH
# Original by Callum Forrester

from gcr.io/diamond-pubreg/controls/python3/s03_utils/epics/base

env EPICS_EDM ${EPICS_MODULES}/extensions
env NEEDED_LIBS screen giflib-devel libXmu-devel libpng-devel libXtst-devel zlib-devel xorg-x11-proto-devel motif-devel libX11-devel libXp-devel libXpm-devel

env MSI_INSTALL /msi


# Update OS and Install X Server
run yum update -y; \
    yum install -y epel-release

run yum install -y xeyes; \
    yum install -y ${NEEDED_LIBS}

# Install MSI from DLS Gitlab
run git clone https://gitlab.diamond.ac.uk/controls/tools/msi.git ${MSI_INSTALL}; \
    cd ${MSI_INSTALL}; \
    git checkout 1-7dls1; \
    make; \
    ln -s ${MSI_INSTALL}/prefix/bin/${EPICS_HOST_ARCH}/msi /usr/bin/msi

# Install EDM from Github
run git clone https://github.com/hir12111/edm.git ${EPICS_EDM}; \
    cd ${EPICS_EDM}; \
    git checkout 1-12-89dls2; \
    make; \
    ln -s ${EPICS_EDM}/bin/linux-x86_64/edm /usr/bin/edm

workdir ${EPICS_EDM}
