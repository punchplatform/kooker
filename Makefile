#!/usr/bin/env bash -ec -o pipefail

# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.

# The Punchplatform code is licensed under the outer restricted Tiss license:
#
#   Copyright © [2014]-[2021] Thales Services
#
#   Licensed under the Thales Inner Source Software License
#   (Version 1.0, InnerPublic - OuterRestricted the "License");
#   You may not use this file except in compliance with the License.
#
#   You may obtain a copy of the License at https://ecm.corp.thales/Livelink/livelink.exe?func=ll&objId=126019196&objAction=browse&viewType=1
#
#   See the License for the specific language governing permissions and limitations
#   under the License.

# Variables
DOWNLOAD_DIR ?= $(shell pwd)/downloads
DOWNLOAD_IMG_DIR ?= ${DOWNLOAD_DIR}/images/*
DOWNLOAD_CHART_DIR ?= ${DOWNLOAD_DIR}/charts/*
WITH_COTS ?= true

PROFILE ?= $(shell pwd)/bin/profiles/default_profile.sh
CLUSTER_NAME ?= kooker
SETUP_ENV = . $(shell realpath ${PROFILE})
CONSOLE_ENV = . $(shell pwd)/activate.sh
IMG ?= busybox

# Makefile properties
.DEFAULT_GOAL := help

##@ Start kooker

.PHONY: start

start: download cluster prepare load-images-from-directory deploy-cots network push-templates ## Start and configure PConsole with all required services

##@ Stop and remove kooker

.PHONY: stop

stop: ## kooker uninstall
	-$(K3D) cluster delete ${CLUSTER_NAME}

##@ Download all kooker dependencies locally

.PHONY: download

download: k3d kubectl hostctl helm download-images download-chart download-kube-resources ## Download resources

##@ Deploy services manually

.PHONY: deploy-cots

deploy-cots: prepare ## Download default COTS
ifeq ($(WITH_COTS), true)
		make deploy-monitoring
		make deploy-minio
		make deploy-kafka
		make deploy-kubernetes-dashboard
		make deploy-elastic
		make deploy-clickhouse
endif
		make deploy-punch

.PHONY: deploy-punch

PUNCH_INSTALL = $(shell pwd)/bin/cots/punch.sh
deploy-punch: ## Deploy only Punch services
	$(SETUP_ENV) && $(PUNCH_INSTALL)

.PHONY: deploy-monitoring

MONITORING_INSTALL = $(shell pwd)/bin/cots/monitoring.sh
deploy-monitoring: ## Deploy only monitoring stack
	$(SETUP_ENV) && $(MONITORING_INSTALL)


.PHONY: deploy-clickhouse

CLICKHOUSE_INSTALL = $(shell pwd)/bin/cots/clickhouse.sh
deploy-clickhouse: ## Deploy only clickhouse
	$(SETUP_ENV) && $(CLICKHOUSE_INSTALL)

.PHONY: deploy-opensearch

OPENSEARCH_INSTALL = $(shell pwd)/bin/cots/opensearch.sh
deploy-opensearch: ## Deploy only opensearch and opensearch-dashboard
	$(SETUP_ENV)  && $(OPENSEARCH_INSTALL)

.PHONY: deploy-elastic

ES_KIBANA_INSTALL = $(shell pwd)/bin/cots/elasticsearch_kibana.sh
deploy-elastic: ## Deploy only kibana and elasticsearch
	$(SETUP_ENV) && $(ES_KIBANA_INSTALL)

.PHONY: deploy-kubernetes-dashboard

KUBERNETES_DASHBOARD_INSTALL = $(shell pwd)/bin/cots/kubernetes_dashboard.sh
deploy-kubernetes-dashboard: ## Deploy only kubernetes dashboard
	$(SETUP_ENV) && $(KUBERNETES_DASHBOARD_INSTALL)

.PHONY: deploy-kafka

KAFKA_INSTALL = $(shell pwd)/bin/cots/kafka.sh
deploy-kafka: ## Deploy only kafka
	$(SETUP_ENV) && $(KAFKA_INSTALL)

.PHONY: deploy-minio

MINIO_INSTALL = $(shell pwd)/bin/cots/minio.sh
deploy-minio: ## Install only minio
	$(SETUP_ENV) && $(MINIO_INSTALL)

##@ Platform management

PUSH_TEMPLATES = $(shell pwd)/bin/tools/push_templates.sh
.PHONY: push-templates

push-templates: ## Push Elastic templates
	$(PUSH_TEMPLATES)

.PHONY: cluster

CREATE_CLUSTER = $(shell pwd)/bin/tools/create_cluster.sh
cluster: ## Create kooker cluster
	$(CREATE_CLUSTER)

.PHONY: network

HOSTCTL_SVC_PROFILE = $(shell pwd)/bin/utils/hostctl_svc_profile.sh
HOST_PROFILE = ${CLUSTER_NAME}
network: ## (requires sudo) Configure network aliases for kubernetes services
	@$(SETUP_ENV) && $(HOSTCTL_SVC_PROFILE)
	@cat .dev-hosts | sudo $(HOSTCTL) replace ${HOST_PROFILE} -q
	@rm .dev-hosts

.PHONY: credentials

GET_CREDENTIALS = $(shell pwd)/bin/utils/credentials.sh
credentials: ## Get platform credentials
	$(GET_CREDENTIALS)

COREDNS_PATCH = $(shell pwd)/bin/utils/patch_coredns.sh
patch-coredns: 
	CLUSTER_NAME=${CLUSTER_NAME} $(COREDNS_PATCH)

CONSOLE_INSTALL = $(shell pwd)/bin/install.sh
prepare: 
	$(CONSOLE_INSTALL) \
		--non-interactive \
		--no-environment-patching

OFFLINE_IMAGES = $(shell pwd)/bin/tools/offline_images.sh
download-images:
	$(SETUP_ENV) && $(OFFLINE_IMAGES)

OFFLINE_CHARTS = $(shell pwd)/bin/tools/offline_charts.sh
download-chart: 
	$(SETUP_ENV) && $(OFFLINE_CHARTS)

OFFLINE_KUBE_RESOURCES = $(shell pwd)/bin/tools/offline_kube_resources.sh
download-kube-resources:
	$(SETUP_ENV) && $(OFFLINE_KUBE_RESOURCES)

##@ Image management

.PHONY: fetch-image

FETCH_IMG = $(shell pwd)/bin/tools/docker_save.sh
fetch-image: ## fetch an image locally in downloads/images.
	-IMG=${IMG} $(FETCH_IMG)

.PHONY: load-image-from-docker

IMAGES_DIR = $(shell pwd)/images
load-image-from-docker: ## Deploy an image from your local docker registry to k3d cluster. Ex : make load-image-from-docker IMG=busybox:latest
	mkdir -p ${IMAGES_DIR}
	docker save $(IMG) > ${IMAGES_DIR}/img
	$(K3D) image import ${IMAGES_DIR}/img --cluster $(CLUSTER_NAME)
	rm ${IMAGES_DIR}/img

load-images-from-directory: ## Deploy all images in $DOWNLOAD_IMG_DIR to k3d cluster.
	$(K3D) image import ${DOWNLOAD_IMG_DIR} --cluster $(CLUSTER_NAME)

##@ General

helm: $(DOWNLOAD_DIR)/helm-install

HELM ?= $(shell pwd)/downloads/helm
HELM_DIR = $(shell pwd)/downloads
HELM_INSTALL = $(shell pwd)/bin/tools/install_helm.sh
$(DOWNLOAD_DIR)/helm-install:
	mkdir -p ${HELM_DIR}
	TAG=v3.7.1 USE_SUDO=false HELM_INSTALL_DIR=${HELM_DIR} $(HELM_INSTALL)
	touch $@

.PHONY: k3d

k3d: $(DOWNLOAD_DIR)/k3d-install

K3D = ${DOWNLOAD_DIR}/k3d
K3D_INSTALL = $(shell pwd)/bin/tools/install_k3d.sh
$(DOWNLOAD_DIR)/k3d-install:
	mkdir -p ${DOWNLOAD_DIR}
	K3D_VERSION=v4.4.8 K3D_INSTALL_DIR=${DOWNLOAD_DIR} $(K3D_INSTALL)
	touch $@

hostctl: $(DOWNLOAD_DIR)/hostctl-install

HOSTCTL = $(shell pwd)/downloads/hostctl
HOSTCTL_INSTALL = $(shell pwd)/bin/tools/install_hostctl.sh
$(DOWNLOAD_DIR)/hostctl-install:
	mkdir -p ${DOWNLOAD_DIR}
	$(SETUP_ENV) && INSTALL_DIR=${DOWNLOAD_DIR} $(HOSTCTL_INSTALL)
	touch $@

.PHONY: kubectl

kubectl: $(DOWNLOAD_DIR)/kubectl-install

KUBECTL = ${DOWNLOAD_DIR}/kubectl
KUBECTL_INSTALL = $(shell pwd)/bin/tools/install_kubectl.sh
$(DOWNLOAD_DIR)/kubectl-install:
	mkdir -p ${DOWNLOAD_DIR}
	INSTALL_DIR=${DOWNLOAD_DIR} $(KUBECTL_INSTALL)
	touch $@


.PHONY: help

HELPER = $(shell pwd)/bin/utils/helper.sh
help: ## Display this help message.
	@-$(HELPER)
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m\n"} /^[0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
