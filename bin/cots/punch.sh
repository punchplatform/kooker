#!/usr/bin/env bash

set -o errexit
set -o pipefail

# load external libs
source bin/env.sh
source bin/utils/libs.sh

if [ $DEBUG = true ] ; then
  set -x
fi


echo ""
echo "Preparing for punch services deployment ..."
echo ""


mkdir -p ${HELM_VARSFILE_DIR}
cat > ${HELM_VARSFILE} <<- EOF
application:
  tenant: ${PUNCHPLATFORM_TENANT}
  file_size: 500MB
metadata:
  elasticsearch:
    http_hosts:
      - host: ${ELASTIC_SERVICE_NAME}.${ELASTIC_NAMESPACE}
        port: 9200
        scheme: http
    security:
      credentials:
        username: ${ES_USER}
        password: ${ES_PASSWORD}

data:
  minio:
    host: http://${MINIO_SERVICE_NAME}:${MINIO_EXPOSURE_PORT}
    access_key: ${MINIO_ACCESS_KEY}
    secret_key: ${MINIO_SECRET_KEY}
EOF

#Deployment of central punch services (operator, artifacts manager)
${HELM} upgrade \
  --install cert-manager \
  --namespace cert-manager \
  ${CHARTS_DIR}/cert-manager-${CERT_MANAGER_VERSION}.tgz \
  --create-namespace \
  --set installCRDs=true \
  --wait

# Creat namespaces if not exist
${KUBECTL} create namespace ${PUNCH_SYSTEM_NAMESPACE} > /dev/null 2>&1 || true
${KUBECTL} create namespace ${PUNCH_ARTEFACT_NAMESPACE} > /dev/null 2>&1 || true

echo ""
echo "Deploying Punch Kube operator and CRDs..."
echo ""


# echo "CRDS:${CHARTS_DIR}/operator-crds-${PUNCH_OPERATOR_VERSION}.tgz"
${HELM} upgrade \
  --install operator-crds \
  --namespace ${PUNCH_SYSTEM_NAMESPACE} \
  ${CHARTS_DIR}/operator-crds-${PUNCH_OPERATOR_VERSION}.tgz \
  --create-namespace \
  --wait

${HELM} upgrade \
  --install operator \
  --namespace ${PUNCH_SYSTEM_NAMESPACE} \
  ${CHARTS_DIR}/operator-${PUNCH_OPERATOR_VERSION}.tgz \
  --values "${HELM_VARSFILE}" \
  --set image.name=${PUNCH_OPERATOR_IMG} \
  --create-namespace \
  --

echo ""
echo "Deploying Punch artifacts server..."
echo ""

${HELM} upgrade \
  --install artifacts \
  --namespace ${PUNCH_ARTEFACT_NAMESPACE} \
  ${CHARTS_DIR}/artifacts-${PUNCH_ARTIFACTS_SERVICE_VERSION}.tgz \
  --set image.name=${PUNCH_ARTIFACT_IMG} \
  --values "${HELM_VARSFILE}" \
  --create-namespace \
  --wait

## In case services are not of type LoadBalancer, patch those to LoadBalancer
patchSVCAndWait svc/artifacts-service ${PUNCH_ARTEFACT_NAMESPACE} 2>&1 > /dev/null


echo ""
echo "Initializing '${PUNCHPLATFORM_TENANT}' namespace and associated configuration items to enable running punchlines..."
echo ""


# Initialize central namespace for 'punch' operator
${KUBECTL} create namespace ${PUNCHPLATFORM_TENANT} > /dev/null 2>&1 || true


${KUBECTL} -n ${PUNCHPLATFORM_TENANT} apply -f- <<EOF
---
apiVersion: platform.gitlab.thalesdigital.io/v2
kind: Platform
metadata:
  name: platform
spec:
  serviceAccount: admin-user
  imagePullPolicy: IfNotPresent
  initContainerImage: ${PUNCH_RESOURCECTL_IMG}
  services:
  - type: dependencies
    url: http://artifacts-service.${PUNCH_ARTEFACT_NAMESPACE}:4245
    secretRefs: []
  transformRules:

    # All kafka_source and kafka_sink nodes bootstrap.servers
    kafka_nodes:
      match: $.spec.dag[?(@.type =~ /kafka_s.*/)].settings
      set:
        - values:
            bootstrap.servers: kafka-kafka-bootstrap.${KAFKA_NAMESPACE}:9092
    
    # Elasticsearch sinks: using kube service + basic auth
    elasticsearch_sinks:
      match: $.spec.dag[?(@.type == elasticsearch_sink)].settings
      set:
        - values:
            http_hosts:
              - host: punchplatform-es-default.${ELASTIC_NAMESPACE}
                port: 9200
            security:
              credentials:
                password: ${ES_USER}
                username: ${ES_PASSWORD}
    # In kube, ltr lumerjack sender should send to lmr-in service
    lumberjack_ltr_out:
      match: $.spec.dag[?(@.type == lumberjack_sink)].settings
      set:
        - values:
            host: lmr-input-service.${PUNCHPLATFORM_TENANT} 
EOF

${KUBECTL} -n ${PUNCHPLATFORM_TENANT} apply -f- <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: admin-user
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "services", "configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
imagePullSecrets:
  - name: admin-secret
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: admin-user
subjects:
- kind: ServiceAccount
  name: admin-user
EOF



echo ""
echo "Finished pushing Punch services descriptors into the cluster"
echo ""