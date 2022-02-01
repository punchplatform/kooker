#!/bin/bash -ue

echo "Killing previous local grafana container..."
docker rm grafana --force 2>/dev/null 1>&2 || echo Could not kill any previous grafana


# Configuration of image : https://grafana.com/docs/grafana/latest/administration/configure-docker/
echo "Starting new grafana container..."
docker run -d --name grafana \
	-p 3000:3000 \
	-e DS_PROMETHEUS=Prometheus \
	--network=host \
	--mount type=bind,source=$(pwd)/local_provisionning,target=/etc/grafana/provisioning \
 	grafana/grafana-oss 

echo "grafana is running on localhost:3000 !"