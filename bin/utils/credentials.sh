#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

KUBENTES_SECRET_NAME=$(${KUBECTL} -n ${KUBERNETES_DASHBOARD_NAMESPACE} get sa/admin-user -o jsonpath="{.secrets[0].name}" 2>/dev/null) || true
# if not empty get token
[ -z ${KUBENTES_SECRET_NAME} ] || \
    TOKEN=$(${KUBECTL} -n ${KUBERNETES_DASHBOARD_NAMESPACE} get secret ${KUBENTES_SECRET_NAME} -o go-template="{{.data.token | base64decode}}" 2>/dev/null) || true

# bold
bred=$'\e[1;31m'
bgrn=$'\e[1;32m'
bblu=$'\e[1;34m'
byel=$'\e[1;33m'
bmag=$'\e[1;35m'
bcyn=$'\e[1;36m'
clrend=$'\e[0m'

cat << EOF 
${bred}ARTEFACT SERVER${clrend} --> ${bcyn}http://artifacts-service.${CLUSTER_NAME}:4245${clrend}
${bred}GRAFANA${clrend} --> ${bcyn}http://grafana.${CLUSTER_NAME}:3000${clrend} - ${GRAFANA_USER}/ ${GRAFANA_PASSWORD}
${bred}PROMETHEUS${clrend} --> ui: ${bcyn}http://prometheus.${CLUSTER_NAME}:9090${clrend} / datasource: ${bcyn}http://prometheus.${MONITORING_NAMESPACE}:9090${clrend}
${bred}CLICKHOUSE HTTP/TCP${clrend} --> ${bcyn}http://clickhouse.${CLUSTER_NAME}:8123 / http://clickhouse.${CLUSTER_NAME}:9000${clrend} - clickhouse_operator / clickhouse_operator_password
${bred}MINIO${clrend} --> ${bcyn}http://minio.${CLUSTER_NAME}:9002${clrend} - ${MINIO_ACCESS_KEY} / ${MINIO_SECRET_KEY}
${bred}KIBANA${clrend} --> ${bcyn}http://kibana.${CLUSTER_NAME}:5601${clrend} - ${ES_USER} / ${ES_PASSWORD}
${bred}ELASTICSEARCH${clrend} --> ${bcyn}http://${ELASTICSEARCH_EXTERNAL_API_URL}${clrend} - ${ES_USER} / ${ES_PASSWORD}
${bred}OPENSEARCH${clrend} --> ${bcyn}http://opensearch.${CLUSTER_NAME}:9202${clrend}
${bred}OPENSEARCH-DASHBOARD${clrend} --> ${bcyn}http://opensearch-dashboard.${CLUSTER_NAME}:5602${clrend}
${bred}KUBERNETES DASHBOARD${clrend} --> If you are on chrome, you may need to type "badidea"/"thisisunsafe" : ${bcyn}https://kubernetes-dashboard.${CLUSTER_NAME}:8443${clrend}
${bred}KUBERNETES DASHBOARD TOKEN (see below/will be empty if not deployed)${clrend} 
$TOKEN
EOF