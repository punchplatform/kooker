#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

if [ $DEBUG = true ] ; then
  set -x
fi

${KUBECTL} create ns ${MINIO_NAMESPACE} > /dev/null 2>&1 || true

${KUBECTL} -n ${MINIO_NAMESPACE} apply -f- <<EOF
apiVersion: v1
kind: Service
metadata:
  name: minio
spec:
  selector:
    app: minio
  ports:
    - port: ${MINIO_EXPOSURE_PORT}
      targetPort: 9002
      name: "9002"
    - port: 9001
      targetPort: 9001
      name: "9001"
  type: LoadBalancer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  labels:
    app: minio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: ${MINIO_IMG}
        args:
        - server
        - /data
        - --address
        - ":9002"
        - --console-address 
        - ":9001"
        ports:
        - containerPort: 9002
        - containerPort: 9001
        env:
        # MinIO access key and secret key
        - name: MINIO_ACCESS_KEY
          value: ${MINIO_ACCESS_KEY}
        - name: MINIO_SECRET_KEY
          value: ${MINIO_SECRET_KEY}
EOF

${KUBECTL} wait deployments --all --for=condition=available --timeout=300s -n ${MINIO_NAMESPACE}

${KUBECTL} -n ${MINIO_NAMESPACE} apply -f- <<EOF
---
apiVersion: batch/v1
kind: Job
metadata:
  name: create-bucket
spec:
  template:
    spec:
      containers:
        - name: create-bucket-tenant
          image: ${MINIO_CLI_IMG}
          command:
            - sh
            - -c
            - |
              set -e
              /usr/bin/mc config host add myminio http://minio.${MINIO_NAMESPACE}:9002 ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY}
              /usr/bin/mc mb myminio/${PUNCHPLATFORM_TENANT}
      restartPolicy: Never
EOF
