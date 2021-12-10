#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

if [ $DEBUG = true ] ; then
  set -x
fi

${KUBECTL} create namespace ${KAFKA_NAMESPACE} > /dev/null 2>&1 || true

${KUBECTL} apply -f ${KUBE_RESOURCES_DIR}/kafka

${KUBECTL} wait pods --all --for=condition=ready --timeout=300s -n ${KAFKA_NAMESPACE}

${KUBECTL} -n ${KAFKA_NAMESPACE} apply -f- <<EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: kafka
spec:
  kafka:
    version: 3.0.0
    replicas: 1
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    config:
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
      log.message.format.version: "3.0"
      inter.broker.protocol.version: "3.0"
    storage:
      type: ephemeral
  zookeeper:
    replicas: 1
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF
