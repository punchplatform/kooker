#!/usr/bin/env bash

set -o errexit
set -o pipefail

KOOKER_BINDIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
KOOKER_DIR=$(realpath "${KOOKER_BINDIR}/..")
KOOKER_DOWNLOADS="${KOOKER_DIR}/downloads"

#### MAKE ####
: ${DEBUG:=false}
: ${OFFLINE:=false}
: ${HELM:="${KOOKER_DOWNLOADS}/helm"}
: ${KUBECTL:="${KOOKER_DOWNLOADS}/kubectl"}
: ${K3D:="${KOOKER_DOWNLOADS}/k3d"}
: ${CHARTS_DIR:="${KOOKER_DOWNLOADS}/charts"}
: ${IMAGES_DIR:="${KOOKER_DOWNLOADS}/images"}
: ${KUBE_RESOURCES_DIR:="${KOOKER_DOWNLOADS}/resources"}
: ${CLUSTER_NAME:="kooker"}

### K3D ###

K3_IMGS=( \
	docker.io/rancher/k3s:v1.21.3-k3s1 \
	docker.io/rancher/k3d-proxy:4.4.8 \
	docker.io/rancher/k3d-tools:4.4.8 \
	rancher/pause:3.1
 )

KUBE_SYSTEM_IMGS=(\
	rancher/local-path-provisioner:v0.0.19 \
	rancher/pause:3.1 \
	rancher/klipper-lb:v0.2.0 \
	rancher/coredns-coredns:1.8.3 \
	rancher/metrics-server:v0.3.6 \
	rancher/klipper-helm:v0.6.1-build20210616 \
	rancher/library-traefik:2.4.8 \
	rancher/library-busybox:1.32.1 \
	k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.2.4 \
	jimmidyson/configmap-reload:v0.5.0 \
 )


#### CLICKHOUSE #####
: ${CLICKHOUSE_OPERATOR_VERSION:="0.17.0"}
: ${CLICKHOUSE_OPERATOR_IMG:="altinity/clickhouse-operator:${CLICKHOUSE_OPERATOR_VERSION}"}
: ${CLICKHOUSE_VERSION:="21.7"}
: ${CLICKHOUSE_IMG:="yandex/clickhouse-server:${CLICKHOUSE_VERSION}"}
: ${CLICKHOUSE_NAMESPACE:="clickhouse"}

CLICKHOUSE_IMGS=( \
	${CLICKHOUSE_OPERATOR_IMG} \
	${CLICKHOUSE_IMG} \
	altinity/metrics-exporter:${CLICKHOUSE_OPERATOR_VERSION} \
)

#### MONITORING #####
: ${MONITORING_NAMESPACE:="monitoring"}
: ${PROMETHEUS_USE_OPERATOR:="false"}
#### used when operator is not deployed
: ${PROMETHEUS_HELM_CHART_VERSION:=15.0.2}
#### used when operator is deployed
: ${PROMETHEUS_OPERATOR_VERSION:="v0.51.2"}
: ${PROMETHEUS_OPERATOR_IMG:="quay.io/prometheus-operator/prometheus-operator:${PROMETHEUS_OPERATOR_VERSION}"}
: ${PROMETHEUS_VERSION:="v2.22.1"}
: ${PROMETHEUS_IMG:="quay.io/prometheus/prometheus:${PROMETHEUS_VERSION}"}

PROMETHEUS_IMGS=(
	${PROMETHEUS_OPERATOR_IMG} \
	${PROMETHEUS_IMG} \
	quay.io/prometheus/node-exporter:v1.3.0 \
	quay.io/prometheus/prometheus:v2.31.1 \
	prom/pushgateway:v1.4.2 \
  )

: ${GRAFANA_VERSION:="7.5.2"}
: ${GRAFANA_IMG:="grafana/grafana:${GRAFANA_VERSION}"}
: ${GRAFANA_USER:="admin"}
: ${GRAFANA_PASSWORD:="admin"}

#### ELASTIC STACK #####
: ${ELASTIC_NAMESPACE:="doc-store"}
: ${ELASTIC_OPERATOR_VERSION:="1.8.0"}
: ${ELASTIC_OPERATOR_IMG:="docker.elastic.co/eck/eck-operator:${ELASTIC_OPERATOR_VERSION}"}
: ${ELASTIC_VERSION:="7.8.0"}
: ${KIBANA_VERSION:="7.8.0"}
: ${ELASTIC_IMG:="docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}"}
: ${KIBANA_IMG:="docker.elastic.co/kibana/kibana:${KIBANA_VERSION}"}
: ${ELASTIC_CLUSTER_NAME:="punchplatform"}
: ${ELASTIC_SERVICE_NAME:="${ELASTIC_CLUSTER_NAME}-es-http"}
: ${ES_USER:="elastic"}
: ${ES_PASSWORD:="elastic"}

#### KAFKA ####
### NOTE: this must match resources in downloads/kafka
: ${KAFKA_NAMESPACE:="processing"}
: ${STRIMZI_VERSION:="0.29.0"}
: ${STRIMZI_OPERATOR_IMG:="quay.io/strimzi/operator:${STRIMZI_VERSION}"}
KAFKA_IMGS=( \
	quay.io/strimzi/kafka:${STRIMZI_VERSION}-kafka-3.0.0 \
	quay.io/strimzi/kafka:${STRIMZI_VERSION}-kafka-3.1.0 \
	quay.io/strimzi/kafka:${STRIMZI_VERSION}-kafka-3.2.0 \
)

#### KUBERNETES SYSTEM ####
: ${KUBERNETES_DASHBOARD_NAMESPACE:="kubernetes-dashboard"}
: ${METRICS_SCRAPER_IMG:="kubernetesui/metrics-scraper:v1.0.6"}
: ${KUBERNETES_DASHBOARD_VERSION:="v2.3.1"}
: ${KUBERNETES_DASHBOARD_IMG:="kubernetesui/dashboard:${KUBERNETES_DASHBOARD_VERSION}"}

#### MINIO ####
: ${MINIO_NAMESPACE:="object-store"}
: ${MINIO_SERVICE_NAME:="minio.${MINIO_NAMESPACE}"}
: ${MINIO_EXPOSURE_PORT:=9002}
: ${MINIO_IMG:="quay.io/minio/minio:RELEASE.2021-10-13T00-23-17Z"}
: ${MINIO_CLI_IMG:="minio/mc:RELEASE.2021-10-07T04-19-58Z"}
: ${MINIO_SECRET_KEY:="password"}
: ${MINIO_ACCESS_KEY:="minio"}

#### OPENSEARCH ####
: ${OPENSEARCH_NAMESPACE:="doc-store"}
: ${OPENSEARCH_BIND_PORT:="9202"}
: ${OPENSEARCH_URL_FOR_DASHBOARD:="http://opensearch-node1.${OPENSEARCH_NAMESPACE}:${OPENSEARCH_BIND_PORT}"}
: ${OPENSEARCH_VERSION:="1.1.0"}
: ${OPENSEARCH_DASHBOARD_NO_SECURITY_IMG:="ghcr.io/punchplatform/opensearch-dashboard-nosecurity:${OPENSEARCH_VERSION}"}
: ${OPENSEARCH_IMG:="opensearchproject/opensearch:${OPENSEARCH_VERSION}"}
: ${OPENSEARCH_DASHBOARD_BIND_PORT:="5602"}

#### CERT MANAGER ####

: ${CERT_MANAGER_VERSION:="v1.4.0"}
: ${CERT_MANAGER_CONTROLLER_IMG:="quay.io/jetstack/cert-manager-controller:${CERT_MANAGER_VERSION}"}
: ${CERT_MANAGER_WEBHOOK_IMG:="quay.io/jetstack/cert-manager-webhook:${CERT_MANAGER_VERSION}"}
: ${CERT_MANAGER_CAINJECTOR_IMG:="quay.io/jetstack/cert-manager-cainjector:${CERT_MANAGER_VERSION}"}

: ${CERT_MANAGER_CHART:="cert-manager"}

#### PUNCH ####
: ${PUNCH_SYSTEM_NAMESPACE:="punchoperator-system"}
: ${PUNCH_ARTIFACTS_NAMESPACE:="punch-artifacts"}
: ${MINIO_NAMESPACE:="object-store"}
: ${ELASTIC_NAMESPACE:="doc-store"}
: ${ELASTICSEARCH_EXTERNAL_API_URL:="elasticsearch.${CLUSTER_NAME}:9200"}

: ${PUNCHPLATFORM_DEFAULT_NAMESPACE:="default"}

: ${PUNCH_VERSION:="8.0.1"}
: ${PUNCH_IMAGES_TAG:=${PUNCH_VERSION}}

: ${PUNCH_OPERATOR_VERSION:=${PUNCH_VERSION}}

: ${PUNCH_INJECTOR_VERSION:=${PUNCH_VERSION}}
: ${PUNCH_ARTIFACTS_SERVICE_VERSION:=${PUNCH_VERSION}}


: ${PUNCH_OPERATOR_IMG:="ghcr.io/punchplatform/operator:${PUNCH_OPERATOR_VERSION}"}
: ${PUNCH_ARTIFACT_IMG:="ghcr.io/punchplatform/artifacts-server:${PUNCH_ARTIFACTS_SERVICE_VERSION}"}
: ${PUNCH_RESOURCECTL_IMG:="ghcr.io/punchplatform/resourcectl:${PUNCH_IMAGES_TAG}"}
: ${PUNCH_ES_HOUSEKEEPING_IMG:="ghcr.io/punchplatform/es-housekeeping:${PUNCH_IMAGES_TAG}"}
: ${PUNCH_S3_HOUSEKEEPING_IMG:="ghcr.io/punchplatform/archive-housekeeping:${PUNCH_IMAGES_TAG}"}
: ${PUNCH_SIMULATOR_IMG:="ghcr.io/punchplatform/operator:${PUNCH_INJECTOR_VERSION}"}

: ${PUNCH_PUNCHLINE_JAVA_IMG:="ghcr.io/punchplatform/punchline-java:${PUNCH_IMAGES_TAG}"}
: ${PUNCH_PUNCHLINE_SPARK_IMG:="ghcr.io/punchplatform/punchline-spark:${PUNCH_IMAGES_TAG}"}
: ${PUNCH_PYTHONBATCH_IMG:="ghcr.io/punchplatform/punchline-python:${PUNCH_IMAGES_TAG}"}



# Useful images to have on local docker, and not only in the K8s
PUNCH_DEVELOPMENT_IMGS=( \
	docker.io/library/busybox:latest \
	${PUNCH_SIMULATOR_IMG} \
	${PUNCH_JAVASTREAM_IMG} \
	${PUNCH_PYTHONBATCH_IMG} \
)
#     ${PUNCH_SPARKLINE_IMG \


: ${PUNCH_HELM_VERSION:=${PUNCH_VERSION}}
: ${PUNCH_OPERATOR_CHART:="operator"}
: ${PUNCH_OPERATOR_CRD_CHART:="operator-crds"}
: ${PUNCH_INJECTOR_CHART:="log-injector"}
: ${PUNCH_ARTIFACT_CHART:="artifacts-server"}
: ${PUNCH_ES_HOUSEKEEPING_CHART:="elastic-housekeeping"}
: ${PUNCH_S3_HOUSEKEEPING_CHART:="archive-housekeeping"}
: ${PUNCH_EXTRACTION_SERVER_CHART:="extraction-server"}
: ${PUNCH_ELASTALERT_SERVER_CHART:="elastalert"}

: ${HELM_VARSFILE_DIR:="$(pwd)/build/punch"}
: ${HELM_VARSFILE:="${HELM_VARSFILE_DIR}/deploy-vars.yaml"}
