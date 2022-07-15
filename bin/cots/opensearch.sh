#!/usr/bin/env bash

set -o errexit
set -o pipefail

# Script inspired from:
#   https://opensearch.org/docs/latest/opensearch/install/docker/#docker-image

source bin/env.sh

if [ $DEBUG = true ] ; then
  set -x
fi

cat << EOF

####################################################################################
#
#  OPENSEARCH deployment ...
#
####################################################################################

EOF

IMG_PATTERN='opensearch' make load-images-from-directory


${KUBECTL} create ns ${OPENSEARCH_NAMESPACE} 2>/dev/null || true

${KUBECTL} apply -n ${OPENSEARCH_NAMESPACE} -f- <<EOF
apiVersion: v1
kind: Service
metadata:
  name: opensearch-dashboards
spec:
  selector:
    service: opensearch-dashboards
  ports:
    - port: ${OPENSEARCH_DASHBOARD_BIND_PORT}
      targetPort: ${OPENSEARCH_DASHBOARD_BIND_PORT}
      name: "${OPENSEARCH_DASHBOARD_BIND_PORT}"
  type: LoadBalancer
---
apiVersion: v1
kind: Service
metadata:
  name: opensearch-node1
spec:
  selector:
    service: opensearch-node1
  ports:
  - port: ${OPENSEARCH_BIND_PORT}
    targetPort: ${OPENSEARCH_BIND_PORT}
    name: "${OPENSEARCH_BIND_PORT}"
  - port: 9600
    targetPort: 9600
    name: "9600"
  type: LoadBalancer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    service: opensearch-dashboards
  name: opensearch-dashboards
spec:
  replicas: 1
  selector:
    matchLabels:
      service: opensearch-dashboards
  strategy: {}
  template:
    metadata:
      labels:
        network/opensearch-net: "true"
        service: opensearch-dashboards
    spec:
      containers:
      - env:
        - name: OPENSEARCH_HOSTS
          value: ${OPENSEARCH_URL_FOR_DASHBOARD}
        - name: SERVER_PORT
          value: "${OPENSEARCH_DASHBOARD_BIND_PORT}"
        image: ${OPENSEARCH_DASHBOARD_NO_SECURITY_IMG}
        name: opensearch-dashboards
        ports:
        - containerPort: ${OPENSEARCH_DASHBOARD_BIND_PORT}
      restartPolicy: Always
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    service: opensearch-node1
  name: opensearch-node1
spec:
  replicas: 1
  selector:
    matchLabels:
      service: opensearch-node1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        network/opensearch-net: "true"
        service: opensearch-node1
    spec:
      containers:
      - env:
        - name: OPENSEARCH_JAVA_OPTS
          value: -Xms1G -Xmx1G
        - name: bootstrap.memory_lock
          value: "false"
        - name: cluster.initial_master_nodes
          value: opensearch-node1
        - name: cluster.name
          value: opensearch-cluster
        - name: discovery.seed_hosts
          value: opensearch-node1
        - name: node.name
          value: opensearch-node1
        - name: plugins.security.disabled
          value: "true"
        - name: http.port
          value: "${OPENSEARCH_BIND_PORT}"
        image: ${OPENSEARCH_IMG}
        name: opensearch-node1
        ports:
        - containerPort: ${OPENSEARCH_BIND_PORT}
        - containerPort: 9600
      restartPolicy: Always
EOF

${KUBECTL} wait deployments --all --for=condition=available --timeout=240s -n ${OPENSEARCH_NAMESPACE}
