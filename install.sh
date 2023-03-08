#!/bin/bash
# @author: PunchPlatform Team
# @desc: Installer script for Kooker Standalone.


kastctlVersion="2.2.2"
hostctlVersion="1.0.10"
kubectlVersion="1.26.0"
k3dVersion="v5.4.6"
helmVersion="v3.11.1"
yqVersion="v4.30.8"

kookerDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
downloadsDir=${kookerDir}/downloads
binDir=${kookerDir}/bin
chartsDir=${kookerDir}/charts
DEBUG=false
initialDir=$(pwd)
# Load commons functions must work for linux / mac 
. "${binDir}/commons-lib.sh"


###########################
## Pre-requisites checking
###########################
function install_prerequisites() {
  debug "Prerequisites installation..."
  mkdir -p "${downloadsDir}"
  # Install k3d 
  install_k3d
  # Install helm
  install_helm
  # Install helm
  install_yq
  # Install kastctl 
  install_kastctl
  # Install kubectl 
  install_kubectl
  # Install hostctl to expose services 
  install_hostctl
  green "✔ Your platform has all the required packages."
}

function print_next_steps() {
  log ""
  info "Next steps:"
  log "  ${wht}0/ Source your activate.sh ${cyn}source activate.sh${wht}${clrend}"
  log "  ${wht}1/ Start the kooker with ${cyn}kooker --start${wht}${clrend}"
  log "  ${wht}2/ Expose your services locally with ${cyn}kooker --expose${wht}${clrend}"
  log "  ${wht}3/ In case of doubt ${cyn}kooker --status${wht}${clrend}"
  log "  ${wht}4/ Get accessible endpoints ${cyn}kooker --info${wht}${clrend}"
  log ""
}

###########################
## Kastctl setup
###########################
function install_kastctl() {
  debug "Install kastctl..."
  cd ${downloadsDir}
  # get binary
  if [ ! -f "kastctl" ]; then
    # We suppose it is a debian based platform (linux-gnu)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      curl -L "https://punchplatform.com/releases/kast/kastctl_darwin-${kastctlVersion}.tar.gz" > ${downloadsDir}/kastctl.tar.gz
    else
      # We suppose it is a debian based platform (linux-gnu)
      curl -L "https://punchplatform.com/releases/kast/kastctl_amd64-${kastctlVersion}.tar.gz" > ${downloadsDir}/kastctl.tar.gz
    fi
    tar -zxvf kastctl.tar.gz
  fi

  #add helm repo
  ${downloadsDir}/helm repo add punch https://punchplatform.github.io/punch-helm/ --force-update
  ${downloadsDir}/helm repo add elastic https://helm.elastic.co --force-update
  ${downloadsDir}/helm repo add strimzi https://strimzi.io/charts/ --force-update
  ${downloadsDir}/helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/ --force-update
  ${downloadsDir}/helm repo add minio https://charts.min.io/ --force-update
  ${downloadsDir}/helm repo add jetstack https://charts.jetstack.io --force-update

  green "✔ Kastctl and his prerequisites has been installed."
}

function install_hostctl {   
  cd ${downloadsDir}
  if [ ! -f "hostctl" ]; then
    # We suppose it is a debian based platform (linux-gnu)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      curl -L "https://github.com/guumaster/hostctl/releases/download/v${hostctlVersion}/hostctl_${hostctlVersion}_macOS_64-bit.tar.gz" > ${downloadsDir}/hostctl.tar.gz
    else
          # We suppose it is a debian based platform (linux-gnu)
      curl -L "https://github.com/guumaster/hostctl/releases/download/v${hostctlVersion}/hostctl_${hostctlVersion}_linux_64-bit.tar.gz" > ${downloadsDir}/hostctl.tar.gz
    fi
    tar -xvf hostctl.tar.gz
    rm hostctl.tar.gz
    rm LICENSE
    rm README.md
    green "✔ Hostctl has been installed."
  fi
}

function install_kubectl {   
  cd ${downloadsDir}
  if [ ! -f "kubectl" ]; then
    if [[ $OSTYPE == 'darwin'* ]]; then
      curl -L https://storage.googleapis.com/kubernetes-release/release/v${kubectlVersion}/bin/darwin/amd64/kubectl > ${downloadsDir}/kubectl
    else
      curl -L https://storage.googleapis.com/kubernetes-release/release/v${kubectlVersion}/bin/linux/amd64/kubectl > ${downloadsDir}/kubectl
    fi
    chmod +x $downloadsDir/kubectl
    green "✔ Kubectl has been installed."
  fi
}

function install_k3d {   
  cd ${downloadsDir}
  if [ ! -f "k3d" ]; then
      curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=${k3dVersion} K3D_INSTALL_DIR=${downloadsDir} USE_SUDO=false PATH="${downloadsDir}:$PATH" bash 1> /dev/null
      green "✔ K3d has been installed."
  fi
}

function install_helm {   
  cd ${downloadsDir}
  if [ ! -f "helm" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      curl -L "https://get.helm.sh/helm-${helmVersion}-darwin-amd64.tar.gz" > ${downloadsDir}/helm.tar.gz
    else
          # We suppose it is a debian based platform (linux-gnu)
      curl -L "https://get.helm.sh/helm-${helmVersion}-linux-amd64.tar.gz" > ${downloadsDir}/helm.tar.gz
    fi
    tar -xvf helm.tar.gz
    mv *-amd64/helm .
    rm -r *-amd64/
    chmod +x $downloadsDir/helm
    green "✔ Helm has been installed."
  fi
}

function install_yq {   
  cd ${downloadsDir}
  if [ ! -f "yq" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      curl -L "https://github.com/mikefarah/yq/releases/download/${yqVersion}/yq_darwin_amd64" > ${downloadsDir}/yq
    else
          # We suppose it is a debian based platform (linux-gnu)
      curl -L "https://github.com/mikefarah/yq/releases/download/${yqVersion}/yq_linux_amd64" > ${downloadsDir}/yq
    fi
    chmod +x $downloadsDir/yq
    green "✔ Yq has been installed."
  fi
}

log "${wht}kooker installation${clrend}"

install_prerequisites

activateShell="${kookerDir}/activate.sh"
cat > "${activateShell}" << EOF
export KOOKER_CLUSTER_NAME=kooker
export KOOKER_DIR=${kookerDir}
export KOOKER_DOWNLOADS_DIR=${downloadsDir}
export KOOKER_CHARTS_DIR=${chartsDir}
export PATH=\${KOOKER_DIR}/bin:\${KOOKER_DOWNLOADS_DIR}:\${PATH}
export PS1='\[\e[1;32m\]kooker:\[\e[0m\][\W]\$ '

# These are the credentials for Opensearch/Elasticsearch APIS (see kesapi)
export KESAPI_ESC="no:auth"

# Loading standard k8s help functions (kesapi, kcurl, kkafka...)
VERBOSE_FUNC=0 . \${KOOKER_DIR}/bin/kube_functions.sh

if [[ ! -f \${KOOKER_DIR}/kpack/.kpack ]]
then
  ln -s \${KOOKER_DIR}/kpack/kpack.yaml \${KOOKER_DIR}/kpack/.kpack
fi

code=\$(kooker --bashComplete 2> /dev/null | sed s/_bashComplete/_kooker_bashComplete/g)
eval "\$code"
complete -F _kooker_bashComplete kooker

EOF
chmod ugo+x "$activateShell"

print_next_steps
green "✓ Installation completed"
cd "${initialDir}"
