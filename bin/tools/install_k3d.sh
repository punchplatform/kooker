#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

: ${K3D_VERSION:="v4.4.8"}
: ${K3D_INSTALL_DIR:="bin"}

if [ ${OFFLINE} = false ] ; then

mkdir -p ${K3D_INSTALL_DIR}
curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=${K3D_VERSION} K3D_INSTALL_DIR=${K3D_INSTALL_DIR} USE_SUDO=false PATH="${K3D_INSTALL_DIR}:$PATH" bash 1> /dev/null
fi