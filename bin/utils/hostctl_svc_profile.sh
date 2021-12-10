#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

ARTEFACT_HOST=$(${KUBECTL} get svc artifacts-service -n ${PUNCH_ARTEFACT_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) || true
ES_HOST=$(${KUBECTL} get svc punchplatform-es-http -n ${ELASTIC_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) || true
KB_HOST=$(${KUBECTL} get svc punchplatform-kb-http -n ${ELASTIC_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) || true
MINIO_HOST=$(${KUBECTL} get svc minio -n ${MINIO_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) || true
OPENSEARCH_DASHBOARD=$(${KUBECTL} get svc opensearch-dashboards -n ${OPENSEARCH_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) || true
OPENSEARCH=$(${KUBECTL} get svc opensearch-node1 -n ${OPENSEARCH_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) || true
KUBERNETES_DASHBOARD=$(${KUBECTL} get svc kubernetes-dashboard -n ${KUBERNETES_DASHBOARD_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) || true
CLICKHOUSE_HOST=$(${KUBECTL} get svc clickhouse-punch-ch -n ${CLICKHOUSE_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) || true
GRAFANA_HOST=$(${KUBECTL} get svc grafana -n ${MONITORING_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) || true
PROMETHEUS_HOST=$(${KUBECTL} get svc prometheus -n ${MONITORING_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) || true

cat > .dev-hosts << EOF
${ARTEFACT_HOST} artifacts-service.${CLUSTER_NAME}
${ES_HOST} elasticsearch.${CLUSTER_NAME}
${KB_HOST} kibana.${CLUSTER_NAME}
${MINIO_HOST} minio.${CLUSTER_NAME}
${OPENSEARCH_DASHBOARD} opensearch-dashboard.${CLUSTER_NAME}
${OPENSEARCH} opensearch${CLUSTER_NAME}
${KUBERNETES_DASHBOARD} kubernetes-dashboard.${CLUSTER_NAME}
${CLICKHOUSE_HOST} clickhouse.${CLUSTER_NAME}
${GRAFANA_HOST} grafana.${CLUSTER_NAME}
${PROMETHEUS_HOST} prometheus.${CLUSTER_NAME}
EOF

make credentials