#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

${KUBECTL} port-forward service/artifacts-server -n "${PUNCH_ARTIFACTS_NAMESPACE}" 4245:4245 > /dev/null 2>&1 &
${KUBECTL} port-forward service/punchplatform-es-http -n "${ELASTIC_NAMESPACE}" 9200:9200 > /dev/null 2>&1 &
${KUBECTL} port-forward service/punchplatform-kb-http -n "${ELASTIC_NAMESPACE}" 5601:5601 > /dev/null 2>&1 &
${KUBECTL} port-forward service/minio -n "${MINIO_NAMESPACE}" 9001:9001 > /dev/null 2>&1 &
${KUBECTL} port-forward service/opensearch-dashboards -n "${OPENSEARCH_NAMESPACE}" 5602:5602 > /dev/null 2>&1 &
${KUBECTL} port-forward service/opensearch-node1 -n "${OPENSEARCH_NAMESPACE}" 9202:9202 > /dev/null 2>&1 &
${KUBECTL} port-forward service/kubernetes-dashboard -n "${KUBERNETES_DASHBOARD_NAMESPACE}" 8443:8443 > /dev/null 2>&1 &
${KUBECTL} port-forward service/clickhouse-punch-ch -n "${CLICKHOUSE_NAMESPACE}" 8123:8123 > /dev/null 2>&1 &
${KUBECTL} port-forward service/clickhouse-punch-ch -n "${CLICKHOUSE_NAMESPACE}" 9000:9000 > /dev/null 2>&1 &
${KUBECTL} port-forward service/grafana -n "${MONITORING_NAMESPACE}" 3000:3000 > /dev/null 2>&1 &
${KUBECTL} port-forward service/prometheus -n "${MONITORING_NAMESPACE}" 9090:9090 > /dev/null 2>&1 &
