#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh
source bin/utils/libs.sh

if [ $DEBUG = true ] ; then
  set -x
fi

cat << EOF

####################################################################################
#
#  PROMETHEUS/GRAFANA monitoring stack deployment ...
#
####################################################################################

EOF

IMG_PATTERN='prom|kube-state|configmap-reload|klipper-lb|grafana' make load-images-from-directory


# create monitoring namespace
${KUBECTL} create ns ${MONITORING_NAMESPACE} 2>/dev/null || true

if [ ${PROMETHEUS_USE_OPERATOR} == false ] ; then
  # Here we install the community chart, providing standard config with old-school prometheus scraping based on annotations

    if [ $OFFLINE == true ] ; then

    ${HELM} upgrade --install prometheus ${CHARTS_DIR}/prometheus-${PROMETHEUS_HELM_CHART_VERSION}.tgz \
      --namespace ${MONITORING_NAMESPACE} \
      --set alertmanager.enabled=false --set server.persistentVolume.enabled=false \
      --wait

    else 
    ${HELM} upgrade --install prometheus prometheus-community/prometheus \
      --namespace ${MONITORING_NAMESPACE} \
      --version ${PROMETHEUS_HELM_CHART_VERSION} \
      --set alertmanager.enabled=false --set server.persistentVolume.enabled=false \
      --wait
    fi




## Install service exposure

${KUBECTL} -n ${MONITORING_NAMESPACE} apply -f- <<EOF
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
    targetPort: 9090
  selector:
    app: prometheus
    component: server
  type: LoadBalancer
EOF



else

    # Here we install the operator-based deployment of prometheus stack, with scraping based on manifests and labels


    sed -i -e "s/namespace: default/namespace: ${MONITORING_NAMESPACE}/g" ${KUBE_RESOURCES_DIR}/prometheus/bundle.yaml 
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
  podMonitorSelector: {}
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

${KUBECTL} -n ${MONITORING_NAMESPACE} apply -f- << EOF
---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: punchlines-pods-monitoring
  labels:
    control-plane: controller-manager
spec:
  namespaceSelector:
    any: true
  podMetricsEndpoints:
  - interval: 10s
    port: "metrics-http"
    path: "/metrics"
  - interval: 10s
    targetPort: 7770
    path: "/metrics"
  selector:
    matchLabels:
      punchplatform/metrics-scraping-group: punchlines
EOF

fi


kubectlWait 240 ${MONITORING_NAMESPACE}

# install grafana



function createOrReplaceCm () {
  CM_NAME=$1
  shift
  # A configmap cannot be updated, just replaced, so either we can create it or we should replace it:


  if ! ${KUBECTL} get cm -n ${MONITORING_NAMESPACE} $CM_NAME 1>/dev/null 2>/dev/null ; then
    echo "Creating configmap '$CM_NAME '..."
    ${KUBECTL} create configmap $CM_NAME -n ${MONITORING_NAMESPACE} $*
    return $?
  else
    echo "Updating configmap '$CM_NAME' ..."
    ${KUBECTL} create configmap --dry-run=client -o yaml $CM_NAME -n ${MONITORING_NAMESPACE}  $* | ${KUBECTL} replace -n ${MONITORING_NAMESPACE} -f -
    return $?
  fi
}


# Create grafana datasource and dashboards configmaps

createOrReplaceCm  grafana-datasources --from-file dashboards/grafana/datasources
createOrReplaceCm  grafana-dashboards-loaders --from-file dashboards/grafana/dashboards-loaders
createOrReplaceCm  grafana-community-dashboards --from-file dashboards/grafana/community 
createOrReplaceCm  grafana-punch-dashboards --from-file dashboards/grafana/punch 



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
          volumeMounts:
            - mountPath: /var/lib/grafana/dashboards/community
              name: community-dashboards-volume
            - mountPath: /var/lib/grafana/dashboards/punch
              name: punch-dashboards-volume
            - mountPath: /etc/grafana/provisioning/dashboards
              name: dashboards-loaders-volume
            - mountPath: /etc/grafana/provisioning/datasources
              name: datasources-volume

      volumes:
        - configMap:
            defaultMode: 420
            name: grafana-community-dashboards
          name: community-dashboards-volume
        - configMap:
            defaultMode: 420
            name: grafana-punch-dashboards
          name: punch-dashboards-volume
        - configMap:
            defaultMode: 420
            name: grafana-dashboards-loaders
          name: dashboards-loaders-volume
        - configMap:
            defaultMode: 420
            name: grafana-datasources
          name: datasources-volume
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
