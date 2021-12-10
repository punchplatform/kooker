#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

: ${TIMEOUT_SEC:=360}

# kubectl wait on bare pods does not give expected behavior
kubectlWait() {
    TIMEOUT_SEC=$1
    NAMESPACE=$2
    retry=1
    until [ "$TIMEOUT_SEC" -ge $retry ]
    do    
        sleep 5
        ${KUBECTL} wait pods --all --for=condition=ready -n ${NAMESPACE} --timeout "${retry}s" && break
        retry=$((retry+1))
    done
}

patchSVCAndWait() {
    SVC=$1
    NAMESPACE=$2
    ${KUBECTL} patch ${SVC} -n ${NAMESPACE} -p '{"spec": {"type": "LoadBalancer" }}'
    kubectlWait ${TIMEOUT_SEC} ${NAMESPACE}
}