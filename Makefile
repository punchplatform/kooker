#!/usr/bin/env bash -ec -o pipefail

# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.

include INFO
include bin/makefiles/PLATFORM
include bin/makefiles/TOOLS
include bin/makefiles/DEPLOYMENT

export

##@ Start kooker

.PHONY: start

start: ## Start and configure PConsole with all required services
	$(MAKE) \
		download \
		cluster \
		prepare \
		deploy-cots \
		network
#		load-images-from-directory \

##@ Stop and remove kooker

.PHONY: stop

stop: k3d ## stop the cluster without uninstalling it
	-$(K3D) cluster stop ${CLUSTER_NAME}
	-echo "Your cluster is stopped and has retained its data. For full destruction, use 'destroy' or 'clean' with make."


.PHONY: destroy

destroy: k3d ## kooker cluster uninstall (WARNING : removes all data !!!)
	-$(K3D) cluster delete ${CLUSTER_NAME}
	rm -rf build activate.sh

##@ Reset repository

.PHONY: clean

clean: ## destroys the kooker cluster, all its data and flush all downloaded artifacts
	-@$(MAKE) destroy > /dev/null 2>&1
	rm -rf ${DOWNLOAD_DIR}

##@ Download all kooker dependencies locally

.PHONY: download

download: ## Download resources
	$(MAKE) \
		k3d \
		kubectl \
		hostctl \
		helm \
		download-images \
		download-chart \
		download-kube-resources

##@ Image management

.PHONY: fetch-image

fetch-image: ## fetch an image locally in downloads/images.
	IMG=${IMG} $(FETCH_IMG)

.PHONY: load-image-from-docker

load-image-from-docker: ## Deploy an image from your local docker registry to k3d cluster. Ex : make load-image-from-docker IMG=busybox:latest
	mkdir -p ${IMAGES_DIR}
	docker save $(IMG) > ${IMAGES_DIR}/img
	$(K3D) image import ${IMAGES_DIR}/img --cluster $(CLUSTER_NAME)
	rm ${IMAGES_DIR}/img

load-images-from-directory: ## Deploy all images in $DOWNLOAD_IMG_DIR to k3d cluster.
	$(LOAD_IMAGE_FROM_DIRECTORY) ${DOWNLOAD_IMG_DIR}

.PHONY: help

help:
	@-$(HELPER)
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m\n"} /^[0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
