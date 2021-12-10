#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

function clusterExists () {
	cat ~/.kube/config | grep "name: ${1}\$" 1>/dev/null
}

## Two if to deal a k3d and a non-k3d cluster
if clusterExists "k3d-${CLUSTER_NAME}" ; then
	echo "Cluster k3d-${CLUSTER_NAME} already exists skipping installation"
	${KUBECTL} config use-context k3d-${CLUSTER_NAME} 
elif clusterExists "${CLUSTER_NAME}" ; then
	echo "Cluster ${CLUSTER_NAME} already exists skipping installation"
	${KUBECTL} config use-context ${CLUSTER_NAME} 
## If not exists, load images for offline mode
else
	if [ ${OFFLINE} = true ] ; then
		for img in ${K3S_IMG} ${K3D_PROXY_IMG} ${K3D_TOOLS_IMG} ${PAUSE_IMG}
		do 
			echo "Docker load $img"
			IMG_STRIP_FORWARD_SLASH=$(echo ${img} | sed 's/^\///;s/\///g')
			docker load < ${IMAGES_DIR}/${IMG_STRIP_FORWARD_SLASH}.tar.gz
		done
	fi
	${K3D} cluster create ${CLUSTER_NAME} \
	--k3s-server-arg '--kubelet-arg=minimum-image-ttl-duration=0' \
	--k3s-server-arg '--kubelet-arg=image-gc-high-threshold=100'
	${KUBECTL} config use-context k3d-${CLUSTER_NAME} 
	${KUBECTL} wait nodes --all --for=condition=ready --timeout=120s 
	make patch-coredns CLUSTER_NAME=${CLUSTER_NAME}
fi