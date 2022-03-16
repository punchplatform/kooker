#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

if [ ${OFFLINE} = false ] ; then
  

  for IMG in "${K3_IMGS[@]}" ; 
  do
    make fetch-image
  done



  make fetch-image IMG=${KUBERNETES_DASHBOARD_IMG}
  
  make fetch-image IMG=${CERT_MANAGER_CONTROLLER_IMG}
  make fetch-image IMG=${CERT_MANAGER_WEBHOOK_IMG}
  make fetch-image IMG=${CERT_MANAGER_CAINJECTOR_IMG}
  


  make fetch-image IMG=${METRICS_SCRAPER_IMG}
  make fetch-image IMG=${PROMETHEUS_OPERATOR_IMG}
  make fetch-image IMG=${PROMETHEUS_IMG}

  make fetch-image IMG=prom/pushgateway:v1.4.2
  make fetch-image IMG=${GRAFANA_IMG}
  
  make fetch-image IMG=${KAFKA_IMG}
  make fetch-image IMG=${STRIMZI_OPERATOR_IMG}
  

  make fetch-image IMG=${MINIO_IMG}
  make fetch-image IMG=${MINIO_CLI_IMG}
  
  make fetch-image IMG=${CLICKHOUSE_OPERATOR_IMG}
  make fetch-image IMG=${CLICKHOUSE_IMG}
  make fetch-image IMG=${ELASTIC_OPERATOR_IMG}
  make fetch-image IMG=${ELASTIC_IMG}
  make fetch-image IMG=${KIBANA_IMG}
  make fetch-image IMG=${OPENSEARCH_IMG}
  make fetch-image IMG=${OPENSEARCH_DASHBOARD_NO_SECURITY_IMG}
  
  make fetch-image IMG=${PUNCH_OPERATOR_IMG}
  make fetch-image IMG=${PUNCH_ARTIFACT_IMG}
  make fetch-image IMG=${PUNCH_RESOURCECTL_IMG}
  
  make fetch-image IMG=${PUNCH_JAVASTREAM_IMG}
  make fetch-image IMG=${PUNCH_SIMULATOR_IMG}

  #make fetch-image IMG=${PUNCH_ES_HOUSEKEEPING_IMG}
  #make fetch-image IMG=${PUNCH_S3_HOUSEKEEPING_IMG}
fi

