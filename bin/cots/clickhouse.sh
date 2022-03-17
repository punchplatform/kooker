#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

# script inspired from the getting started guide: 
#   https://github.com/Altinity/clickhouse-operator/blob/0.16.0/docs/quick_start.md

if [ $DEBUG = true ] ; then
  set -x
fi

${KUBECTL} create ns ${CLICKHOUSE_NAMESPACE} 2>/dev/null || true

# https://github.com/Altinity/clickhouse-operator/blob/master/docs/operator_installation_details.md


KUBECTL=${KUBECTL} OPERATOR_IMAGE=${CLICKHOUSE_OPERATOR_IMG} ${KUBECTL} apply --namespace="${CLICKHOUSE_NAMESPACE}" -f "${KUBE_RESOURCES_DIR}/clickhouse/clickhouse-operator-install-bundle.yaml"

echo "Clickhouse deployment in progress..."

${KUBECTL} wait deployments --all --for=condition=available --timeout=180s -n ${CLICKHOUSE_NAMESPACE}

${KUBECTL} apply -n ${CLICKHOUSE_NAMESPACE} -f- <<EOF
apiVersion: "clickhouse.altinity.com/v1"
kind: "ClickHouseInstallation"
metadata:
  name: punch-ch
spec:
  configuration:
    clusters:
      - name: punch-ch
        # Templates are specified for this cluster explicitly
        templates:
          podTemplate: simple-template
        layout:
          shardsCount: 1
          replicasCount: 1
  templates:
    podTemplates:
      - name: simple-template
        spec:
          containers:
            - name: clickhouse
              image: ${CLICKHOUSE_IMG}
              imagePullPolicy: IfNotPresent
EOF

${KUBECTL} wait pods --all --for=condition=ready --timeout=240s -n ${CLICKHOUSE_NAMESPACE}