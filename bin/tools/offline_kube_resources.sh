#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

if [ ${OFFLINE} = false ] ; then

    mkdir -p ${KUBE_RESOURCES_DIR}/elastic
    mkdir -p ${KUBE_RESOURCES_DIR}/kafka
    mkdir -p ${KUBE_RESOURCES_DIR}/clickhouse
    mkdir -p ${KUBE_RESOURCES_DIR}/dashboard
    mkdir -p ${KUBE_RESOURCES_DIR}/prometheus


    wget https://download.elastic.co/downloads/eck/${ELASTIC_OPERATOR_VERSION}/crds.yaml -O ${KUBE_RESOURCES_DIR}/elastic/crds.yaml
    wget https://download.elastic.co/downloads/eck/${ELASTIC_OPERATOR_VERSION}/operator.yaml -O ${KUBE_RESOURCES_DIR}/elastic/operator.yaml

    wget https://raw.githubusercontent.com/Altinity/clickhouse-operator/${CLICKHOUSE_OPERATOR_VERSION}/deploy/operator/clickhouse-operator-install.sh -O ${KUBE_RESOURCES_DIR}/clickhouse/clickhouse-operator-install.sh
    sed -i -e 's/kubectl /${KUBECTL} /g' ${KUBE_RESOURCES_DIR}/clickhouse/clickhouse-operator-install.sh
    wget https://raw.githubusercontent.com/Altinity/clickhouse-operator/${CLICKHOUSE_OPERATOR_VERSION}/deploy/operator/clickhouse-operator-install-bundle.yaml -O ${KUBE_RESOURCES_DIR}/clickhouse/clickhouse-operator-install-bundle.yaml
    sed -i -e '/imagePullPolicy/s/Always/IfNotPresent/g' ${KUBE_RESOURCES_DIR}/clickhouse/clickhouse-operator-install-bundle.yaml
    sed -i -e '/namespace:/s/kube-system/'${CLICKHOUSE_NAMESPACE}'/g' ${KUBE_RESOURCES_DIR}/clickhouse/clickhouse-operator-install-bundle.yaml
    
    ## When kubectl is not available on PATH
    
        chmod +x ${KUBE_RESOURCES_DIR}/clickhouse/clickhouse-operator-install.sh

    wget https://strimzi.io/install/latest?namespace=${KAFKA_NAMESPACE} -O ${KUBE_RESOURCES_DIR}/kafka/strimzi.yaml

    wget https://raw.githubusercontent.com/kubernetes/dashboard/${KUBERNETES_DASHBOARD_VERSION}/aio/deploy/recommended.yaml -O ${KUBE_RESOURCES_DIR}/dashboard/recommended.yaml
    sed -i -e '/imagePullPolicy/s/Always/IfNotPresent/g' ${KUBE_RESOURCES_DIR}/dashboard/recommended.yaml
    


    wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${PROMETHEUS_OPERATOR_VERSION}/bundle.yaml -O ${KUBE_RESOURCES_DIR}/prometheus/bundle.yaml

fi