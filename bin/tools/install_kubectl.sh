#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

: ${INSTALL_DIR:="downloads"}

if [ ${OFFLINE} = false ] ; then

if [[ $OSTYPE == 'darwin'* ]]; then
	curl --output ${INSTALL_DIR}/kubectl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
else
	curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl > ${INSTALL_DIR}/kubectl
fi
chmod +x $INSTALL_DIR/kubectl
fi