#!/usr/bin/env bash

set -o errexit
set -o pipefail


if [ -z ${IMG:-} ] ; then

    if [ $# -ne 1 ] ; then
        echo "FATAL: please provide image tag:version to download as first parameter or IMG environment variable" 1>&2
        exit 1
    fi
    IMG=$1
fi

source bin/env.sh

IMG_STRIP_FORWARD_SLASH=$(echo ${IMG} | sed 's/^\///;s/\///g')
TARGET_ARCHIVE_PATH=${IMAGES_DIR}/${IMG_STRIP_FORWARD_SLASH}.tar.gz


## If tag does not end with a digit or with a 'Z' (timezone) , then we always pull, to allow refresh of 'floating' tag images

if [[ $IMG =~ [0-9]Z?$ ]] && [ -f ${TARGET_ARCHIVE_PATH} ] ; then
    echo "Release image already cached: ${IMG}; skipping"
else
    echo "Pulling image '${IMG}"
    mkdir -p ${IMAGES_DIR}
    docker pull ${IMG}
    docker save ${IMG} > ${TARGET_ARCHIVE_PATH}
fi