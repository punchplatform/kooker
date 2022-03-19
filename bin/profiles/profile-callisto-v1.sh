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
export ELASTIC_VERSION=7.8.0
# export ELASTIC_IMG=docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}
export KIBANA_VERSION=7.8.0
# export KIBANA_IMG=docker.elastic.co/kibana/kibana:${KIBANA_VERSION}

### KAFKA ENV 

# export KAFKA_NAMESPACE=processing
# export STRIMZI_OPERATOR_IMG=quay.io/strimzi/operator:0.26.0
# export KAFKA_IMG=quay.io/strimzi/kafka:0.26.0-kafka-3.0.0

### MINIO ENV 

# export MINIO_NAMESPACE=object-store
# export MINIO_IMG=quay.io/minio/minio:RELEASE.2020-12-18T03:27:42Z
# export MINIO_CLI_IMG=minio/mc:RELEASE.2021-10-07T04-19-58Z
# export MINIO_SECRET_KEY=password
# export MINIO_ACCESS_KEY=minio

## PUNCH ENV 

# export PUNCHPLATFORM_DEFAULT_NAMESPACE=default
export PUNCH_VERSION=7.0.1-SNAPSHOT
export PUNCH_OPERATOR_VERSION=1.0.7
# export PUNCH_SYSTEM_NAMESPACE=punchoperator-system
# export PUNCH_ARTIFACTS_NAMESPACE=punch-artifacts
# export PUNCH_OPERATOR_IMG=ghcr.io/punchplatform/operator:${PUNCH_OPERATOR_VERSION}
# export PUNCH_ARTIFACT_IMG=ghcr.io/punchplatform/artifacts-server:${PUNCH_VERSION}
# export PUNCH_RESOURCECTL_IMG=ghcr.io/punchplatform/resourcectl:${PUNCH_VERSION}
# export PUNCH_STORMLINE_IMG=ghcr.io/punchplatform/stormline:${PUNCH_VERSION}
# export PUNCH_SPARKLINE_IMG=ghcr.io/punchplatform/sparkline:${PUNCH_VERSION}
# export PUNCH_ES_HOUSEKEEPING_IMG=ghcr.io/punchplatform/es-housekeeping:${PUNCH_VERSION}
# export PUNCH_S3_HOUSEKEEPING_IMG=ghcr.io/punchplatform/archive-housekeeping:${PUNCH_VERSION}
