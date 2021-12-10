#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

if [ $DEBUG = true ] ; then
  set -x
fi

# https://www.elastic.co/guide/en/cloud-on-k8s/1.8/k8s-deploy-eck.html

# by default in elastic-system namespace
${KUBECTL} apply -f ${KUBE_RESOURCES_DIR}/elastic/crds.yaml 
${KUBECTL} apply -f ${KUBE_RESOURCES_DIR}/elastic/operator.yaml

# normally, we want to wait for the statefulset to be available, like we do for deployments
# unfortunately, at the date this file was written, this feature was not implemented yet:
# see: https://github.com/kubernetes/kubernetes/issues/79606

# Install elastic
${KUBECTL} create ns ${ELASTIC_NAMESPACE} > /dev/null 2>&1 || true
${KUBECTL} -n ${ELASTIC_NAMESPACE} apply -f- <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    common.k8s.elastic.co/type: elasticsearch
    elasticsearch.k8s.elastic.co/cluster-name: ${ELASTIC_CLUSTER_NAME}
  name: ${ELASTIC_SERVICE_NAME}
spec:
  ports:
  - name: http
    port: 9200
  selector:
    common.k8s.elastic.co/type: elasticsearch
    elasticsearch.k8s.elastic.co/cluster-name: ${ELASTIC_CLUSTER_NAME}
  type: LoadBalancer
---
kind: Secret
apiVersion: v1
metadata:
  name: ${ELASTIC_CLUSTER_NAME}-es-elastic-user
stringData:
  ${ES_USER}: ${ES_PASSWORD}
---
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: ${ELASTIC_CLUSTER_NAME}
spec:
  version: ${ELASTIC_VERSION}
  http:
    tls:
      selfSignedCertificate:
        disabled: true
  auth:
    fileRealm:
    - secretName: punch-file-realm
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
EOF

# Install kibana
${KUBECTL} create ns ${ELASTIC_NAMESPACE} > /dev/null 2>&1 || true
${KUBECTL} -n ${ELASTIC_NAMESPACE} apply -f- <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    common.k8s.elastic.co/type: kibana
    kibana.k8s.elastic.co/name: ${ELASTIC_CLUSTER_NAME}
  name: ${ELASTIC_CLUSTER_NAME}-kb-http
spec:
  ports:
  - name: http
    port: 5601
  selector:
    common.k8s.elastic.co/type: kibana
    kibana.k8s.elastic.co/name: ${ELASTIC_CLUSTER_NAME}
  type: LoadBalancer
---
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: ${ELASTIC_CLUSTER_NAME}
spec:
  version: ${KIBANA_VERSION}
  http:
    tls:
      selfSignedCertificate:
        disabled: true
  count: 1
  elasticsearchRef:
    name: punchplatform
EOF

source bin/utils/libs.sh
kubectlWait 360 elastic-system
kubectlWait 360 ${ELASTIC_NAMESPACE}