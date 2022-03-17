#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

if [ ${OFFLINE} = false ] ; then
  

  for IMG in "${K3_IMGS[@]}" "${KUBE_SYSTEM_IMGS[@]}" ; 
  do
    make fetch-image
  done


  make fetch-image IMG=${KUBERNETES_DASHBOARD_IMG}
  
  make fetch-image IMG=${CERT_MANAGER_CONTROLLER_IMG}
  make fetch-image IMG=${CERT_MANAGER_WEBHOOK_IMG}
  make fetch-image IMG=${CERT_MANAGER_CAINJECTOR_IMG}
  


  make fetch-image IMG=${METRICS_SCRAPER_IMG}

  make fetch-image IMG=${GRAFANA_IMG}
  
  make fetch-image IMG=${STRIMZI_OPERATOR_IMG}
  

  make fetch-image IMG=${MINIO_IMG}
  make fetch-image IMG=${MINIO_CLI_IMG}
  
  for IMG in "${PROMETHEUS_IMGS[@]}" "${CLICKHOUSE_IMGS[@]}" "${KAFKA_IMGS[@]}" ; 
  do
    make fetch-image
  done

  make fetch-image IMG=${ELASTIC_OPERATOR_IMG}
  make fetch-image IMG=${ELASTIC_IMG}
  make fetch-image IMG=${KIBANA_IMG}
  make fetch-image IMG=${OPENSEARCH_IMG}
  make fetch-image IMG=${OPENSEARCH_DASHBOARD_NO_SECURITY_IMG}
  
  make fetch-image IMG=${PUNCH_OPERATOR_IMG}
  make fetch-image IMG=${PUNCH_ARTIFACT_IMG}
  make fetch-image IMG=${PUNCH_RESOURCECTL_IMG}
  
  make fetch-image IMG=${PUNCH_JAVASTREAM_IMG}
  #make fetch-image IMG=${PUNCH_SPARKLINE_IMG}
  make fetch-image IMG=${PUNCH_SIMULATOR_IMG}

  #make fetch-image IMG=${PUNCH_ES_HOUSEKEEPING_IMG}
  #make fetch-image IMG=${PUNCH_S3_HOUSEKEEPING_IMG}
fi

