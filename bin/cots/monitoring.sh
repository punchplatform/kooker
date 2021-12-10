#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh
source bin/utils/libs.sh

if [ $DEBUG = true ] ; then
  set -x
fi

# create monitoring namespace
${KUBECTL} create ns ${MONITORING_NAMESPACE} 2>/dev/null || true

sed -i "s/namespace: default/namespace: ${MONITORING_NAMESPACE}/g" ${KUBE_RESOURCES_DIR}/prometheus/bundle.yaml

# install prometheus operator and it's related CRDs
${KUBECTL} apply \
  -f ${KUBE_RESOURCES_DIR}/prometheus \
  -n ${MONITORING_NAMESPACE}

kubectlWait 360 ${MONITORING_NAMESPACE}

## Install needed rbac and prometheus backend

${KUBECTL} -n ${MONITORING_NAMESPACE} apply -f- <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/metrics
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources:
  - configmaps
  verbs: ["get"]
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: ${MONITORING_NAMESPACE}
---
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus
  labels:
    app: prometheus
spec:
  image: ${PROMETHEUS_IMG}
  nodeSelector:
    kubernetes.io/os: linux
  replicas: 2
  resources:
    requests:
      memory: 400Mi
  securityContext:
    fsGroup: 2000
    runAsNonRoot: true
    runAsUser: 1000
  serviceAccountName: prometheus
  version: v2.22.1
  serviceMonitorSelector: {}
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  labels:
    app: prometheus
spec:
  ports:
  - name: web
    port: 9090
    targetPort: web
  selector:
    app: prometheus
  type: LoadBalancer
EOF

kubectlWait 240 ${MONITORING_NAMESPACE}

# install grafana

${KUBECTL} -n ${MONITORING_NAMESPACE} apply -f- << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: grafana
  name: grafana
spec:
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      securityContext:
        fsGroup: 472
        supplementalGroups:
          - 0
      containers:
        - name: grafana
          image: ${GRAFANA_IMG}
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 3000
              name: http-grafana
              protocol: TCP
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /robots.txt
              port: 3000
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 30
            successThreshold: 1
            timeoutSeconds: 2
          livenessProbe:
            failureThreshold: 3
            initialDelaySeconds: 30
            periodSeconds: 10
            successThreshold: 1
            tcpSocket:
              port: 3000
            timeoutSeconds: 1
          resources:
            requests:
              cpu: 250m
              memory: 750Mi
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
spec:
  ports:
    - port: 3000
      protocol: TCP
      targetPort: http-grafana
  selector:
    app: grafana
  type: LoadBalancer
EOF

kubectlWait 240 ${MONITORING_NAMESPACE}

${KUBECTL} -n ${MONITORING_NAMESPACE} apply -f- << EOF
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: punchoperator-servicemonitor
  labels:
    control-plane: controller-manager
spec:
  namespaceSelector:
    any: true
  endpoints:
  - interval: 1s
    port: "8443"
    path: "/metrics"
  selector:
    matchLabels:
      control-plane: controller-manager
EOF