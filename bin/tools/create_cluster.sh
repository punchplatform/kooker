#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

function clusterExists () {
	${K3D} cluster ls -o json | jq -r .[].name | grep '^'${1}'$'  > /dev/null
}

function setupKubeconfig () {
	if [ ${CI} = true ]; then
		ip route|awk '/default/'
		REAL_IP=$(ip route|awk '/default/ { print $3 }' | sed 's/'\''//')
		echo $REAL_IP docker >> /etc/hosts
		sed -i -E -e 's/localhost|0\.0\.0\.0/docker/g' "$HOME/.kube/config"
	fi
}

cat << EOF

####################################################################################
#
#  K3D 'kooker' cluster deployment ...
#
####################################################################################

EOF

## Two if to deal a k3d and a non-k3d cluster
if clusterExists "${CLUSTER_NAME}" ; then
	echo "Cluster ${CLUSTER_NAME} already exists skipping installation"
	${KUBECTL} config use-context k3d-${CLUSTER_NAME} 
elif clusterExists "${CLUSTER_NAME}" ; then
	echo "Cluster ${CLUSTER_NAME} already exists skipping installation"
	${KUBECTL} config use-context ${CLUSTER_NAME} 
## If not exists, load images for offline mode
else



	if [ ${OFFLINE} = true ] ; then
		# Importing images that are useful in local docker, for k3d or for development
		for img in "${K3_IMGS[@]}" "${PUNCH_DEVELOPMENT_IMGS[@]}" ;
		do 
			echo "Docker load $img"
			IMG_STRIP_FORWARD_SLASH=$(echo ${img} | sed 's/^\///;s/\///g')
			docker load < ${IMAGES_DIR}/${IMG_STRIP_FORWARD_SLASH}.tar.gz
		done
	fi
	${K3D} cluster create ${CLUSTER_NAME} \
	--k3s-server-arg '--kubelet-arg=minimum-image-ttl-duration=0' \
	--k3s-server-arg '--kubelet-arg=image-gc-high-threshold=99' \
	--k3s-server-arg '--kubelet-arg=eviction-hard=imagefs.available<1%,nodefs.available<1%' 
	setupKubeconfig
	${KUBECTL} config use-context k3d-${CLUSTER_NAME} 
	${KUBECTL} wait nodes --all --for=condition=ready --timeout=120s 
	make patch-coredns CLUSTER_NAME=${CLUSTER_NAME}
fi

IMG_PATTERN='rancher' make load-images-from-directory
