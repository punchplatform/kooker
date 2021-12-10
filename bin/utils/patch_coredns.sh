#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

if [ $DEBUG = true ] ; then
  set -x
fi

GATEWAY_IP=$(docker network inspect k3d-${CLUSTER_NAME} --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}')
# GATEWAY_IP = a network bridge created by docker
# every k3d cluster created will create a new network bridge which is then added to GATEWAY_IP if --network host is set
# this is necessary because k3d host.k3d.internal alias is not a cross platform feature and does not work properly
# patch coredns and adding GATEWAY_IP host.k3d.internal to NodeHosts makes host.k3d.internal resolution in running pods possible
patch_coredns() {
    ${KUBECTL} -n kube-system get configmap coredns -o yaml > coredns.yaml
    FILE=$(cat coredns.yaml)
    if [[ $FILE =~ "NodeHosts" && $FILE =~ "k3d-".*-server-0 ]] ; then
        cat coredns.yaml | sed -e "s/NodeHosts: |/NodeHosts: |\n    ${GATEWAY_IP} host.k3d.internal/g" > coredns-patched.yaml
        ${KUBECTL} -n kube-system apply -f coredns-patched.yaml 
        rm coredns.yaml coredns-patched.yaml
        return 0
    fi
    return 1
}

retry=0
until [ "$retry" -ge 5 ]
do    
    patch_coredns && break
    retry=$((retry+1))
    sleep 5
done
