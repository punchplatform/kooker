## DEFAULT PROFILE

### DEPLOY ENV

# export OFFLINE=false
# export DEBUG=false

### CLICKHOUSE ENV

# export CLICKHOUSE_NAMESPACE=clickhouse
# export CLICKHOUSE_OPERATOR_IMG=altinity/clickhouse-operator:0.16.0
# export CLICKHOUSE_VERSION=21.7
# export CLICKHOUSE_IMG=yandex/clickhouse-server:${CLICKHOUSE_VERSION}

### OPENSEARCH ENV

# export OPENSEARCH_URL_FOR_DASHBOARD=http://opensearch-node1.opensearch:9200
# export OPENSEARCH_NAMESPACE=opensearch
# export OPENSEARCH_VERSION=1.1.0
# export OPENSEARCH_DASHBOARD_NO_SECURITY_IMG=opensearch-dashboard-nosecurity:${OPENSEARCH_VERSION}
# export OPENSEARCH_IMG=opensearchproject/opensearch:${OPENSEARCH_VERSION}
# export OPENSEARCH_DASHBOARD_BIND_PORT=5602

### ELASTIC ENV 

# export ELASTIC_NAMESPACE=doc-store
# export ELASTIC_OPERATOR_VERSION=1.8.0
# export ELASTIC_OPERATOR_IMG=docker.elastic.co/eck/eck-operator:${ELASTIC_OPERATOR_VERSION}
# export ELASTIC_VERSION=7.8.0
# export ELASTIC_IMG=docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}
# export KIBANA_VERSION=7.8.0
# export KIBANA_IMG=docker.elastic.co/kibana/kibana:${KIBANA_VERSION}

### KAFKA ENV 

# export KAFKA_NAMESPACE=processing
# export STRIMZI_OPERATOR_IMG=quay.io/strimzi/operator:0.26.0
# export KAFKA_IMG=quay.io/strimzi/kafka:0.26.0-kafka-3.0.0

### MINIO ENV 

# export MINIO_NAMESPACE=object-store
# export MINIO_IMG=quay.io/minio/minio:RELEASE.2021-10-13T00-23-17Z
# export MINIO_CLI_IMG=minio/mc:RELEASE.2021-10-07T04-19-58Z
# export MINIO_SECRET_KEY=password
# export MINIO_ACCESS_KEY=minio

## PUNCH ENV 

# export PUNCHPLATFORM_DEFAULT_NAMESPACE=default

export PUNCH_VERSION=8.0-dev
export PUNCH_IMAGES_TAG=8.0-dev
export PUNCH_OPERATOR_VERSION=${PUNCH_IMAGES_TAG}

#export PUNCH_HELM_VERSION=7.0.2-SNAPSHOT
#export PUNCH_INJECTOR_VERSION=7.0.2-SNAPSHOT
#export PUNCH_ARTIFACTS_SERVICE_VERSION=7.0.2-SNAPSHOT

# export PUNCH_SYSTEM_NAMESPACE=punchoperator-system
# export PUNCH_ARTIFACTS_NAMESPACE=punch-artifacts

# Target :m 8.0-DEV . Pour l'instant operateur 7.
# export PUNCH_OPERATOR_IMG=ghcr.io/punchplatform/operator:1.1.0   

#export PUNCH_ARTIFACT_IMG=ghcr.io/punchplatform/artifacts-server:${PUNCH_IMAGES_TAG}
#export PUNCH_RESOURCECTL_IMG=ghcr.io/punchplatform/resourcectl:${PUNCH_IMAGES_TAG}
export PUNCH_PUNCHLINE_JAVA_IMG=ghcr.io/punchplatform/punchline-java:${PUNCH_IMAGES_TAG}
export PUNCH_PUNCHLINE_SPARK_IMG=ghcr.io/punchplatform/punchline-spark:${PUNCH_IMAGES_TAG}

