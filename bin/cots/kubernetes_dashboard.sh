#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

if [ $DEBUG = true ] ; then
  set -x
fi

cat << EOF

####################################################################################
#
#  KUBERNETES DASHBOARD deployment ...
#
####################################################################################

EOF

IMG_PATTERN='kubernetesui|rancher' make load-images-from-directory


# install dashboard (not necessary)
${KUBECTL} apply \
  -f ${KUBE_RESOURCES_DIR}/dashboard \
  -n ${KUBERNETES_DASHBOARD_NAMESPACE}

${KUBECTL} apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${KUBERNETES_DASHBOARD_NAMESPACE}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: ${KUBERNETES_DASHBOARD_NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: ${KUBERNETES_DASHBOARD_NAMESPACE}
---
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: ${KUBERNETES_DASHBOARD_NAMESPACE}
spec:
  ports:
  - port: 8443
    targetPort: 8443
    protocol: TCP
  selector:
    k8s-app: kubernetes-dashboard
  type: LoadBalancer
EOF

source bin/utils/libs.sh
kubectlWait 360 ${KUBERNETES_DASHBOARD_NAMESPACE}