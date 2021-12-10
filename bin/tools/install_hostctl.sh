#!/usr/bin/env bash

set -o errexit
set -o pipefail

: ${INSTALL_DIR:="downloads/hostctl"}
: ${TAG:="1.0.10"}

if [ "${OFFLINE:-false}" == "false" ] ; then

    mkdir -p ${INSTALL_DIR}

    if [[ "$OSTYPE" == "darwin"* ]]; then
        curl -L "https://github.com/guumaster/hostctl/releases/download/v${TAG}/hostctl_${TAG}_macOS_64-bit.tar.gz" > ${INSTALL_DIR}/hostctl.tar.gz
    else
        # We suppose it is a debian based platform (linux-gnu)
        curl -L "https://github.com/guumaster/hostctl/releases/download/v${TAG}/hostctl_${TAG}_linux_64-bit.tar.gz" > ${INSTALL_DIR}/hostctl.tar.gz
    fi

    cd ${INSTALL_DIR}
    tar -xvf hostctl.tar.gz
    rm hostctl.tar.gz
fi