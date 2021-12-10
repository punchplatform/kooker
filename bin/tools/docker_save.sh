#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

IMG_STRIP_FORWARD_SLASH=$(echo ${IMG} | sed 's/^\///;s/\///g')
TARGET_ARCHIVE_PATH=${IMAGES_DIR}/${IMG_STRIP_FORWARD_SLASH}.tar.gz

if [ ! -f ${TARGET_ARCHIVE_PATH} ]; then
    mkdir -p ${IMAGES_DIR}
    docker pull ${IMG}
    docker save ${IMG} > ${TARGET_ARCHIVE_PATH}
else
    echo "Image already cached: ${IMG}; skipping"
fi