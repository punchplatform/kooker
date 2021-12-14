#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

if [ ${OFFLINE} = false ] ; then

mkdir -p ${CHARTS_DIR}

${HELM} repo add punchplatform https://punchplatform.github.io/punch-helm || true
${HELM} repo add jetstack https://charts.jetstack.io || true
${HELM} repo update

${HELM} pull punchplatform/${PUNCH_OPERATOR_CHART} --version ${PUNCH_OPERATOR_VERSION} --devel --destination ${CHARTS_DIR}
${HELM} pull punchplatform/${PUNCH_OPERATOR_CRD_CHART} --version ${PUNCH_OPERATOR_VERSION} --devel --destination ${CHARTS_DIR}
${HELM} pull punchplatform/${PUNCH_INJECTOR_CHART} --version ${PUNCH_VERSION} --devel --destination ${CHARTS_DIR}
${HELM} pull punchplatform/${PUNCH_ARTIFACT_CHART} --version ${PUNCH_VERSION} --devel --destination ${CHARTS_DIR}
${HELM} pull punchplatform/${PUNCH_ES_HOUSEKEEPING_CHART} --version ${PUNCH_VERSION} --devel --destination ${CHARTS_DIR}
${HELM} pull punchplatform/${PUNCH_S3_HOUSEKEEPING_CHART} --version ${PUNCH_VERSION} --devel --destination ${CHARTS_DIR}
${HELM} pull punchplatform/${PUNCH_EXTRACTION_SERVER_CHART} --version ${PUNCH_VERSION} --devel --destination ${CHARTS_DIR}
${HELM} pull punchplatform/${PUNCH_ELASTALERT_SERVER_CHART} --version ${PUNCH_VERSION} --devel --destination ${CHARTS_DIR}

${HELM} pull jetstack/${CERT_MANAGER_CHART} --version ${CERT_MANAGER_VERSION} --destination ${CHARTS_DIR}

fi