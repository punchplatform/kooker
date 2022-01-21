#!/usr/bin/env bash

set -o errexit
set -o pipefail

source bin/env.sh

# This script imports tar image files into the cluster (except if they are already there and we can detect it using 'jq' )
# Note that currently, image files are called *tar.gz although they are uncompressed (so actually plain tar files)



if [ $# == 0 ]  ; then
    echo "FATAL: '$0' expects images paths as parameters" 1>&2
    exit 1
fi


# Test jq availability for more smart compare (taking into account images changes to avoid unneccessary reimport)


if which jq 1> /dev/null ; then
    JQ_AVAILABLE=1
    # Retrieve images that are already in cluster
    CLUSTER_MASTER_DOCKER_SHA=$(docker ps --quiet --filter "label=k3d.cluster=${CLUSTER_NAME}" --filter 'label=k3d.role=server')
    CLUSTER_IMAGES=$(docker exec "${CLUSTER_MASTER_DOCKER_SHA}" crictl images --no-trunc | sed 's/\s\+/:/1')

    # Here we get something like this:
    #
    #       IMAGE:TAG                            IMAGE ID                                                                  SIZE
    #       docker.elastic.co/eck/eck-operator:1.8.0                          sha256:8f16d19279b45824b5e88b024c2ce6ec046253f81900ebf856493314d75d9d59   167MB
    #       docker.elastic.co/elasticsearch/elasticsearch:7.8.0                          sha256:121454ddad72df47aa5726e7634dc16f5ed764b08b90aed848a48d625fde4d8b   819MB
    #       docker.elastic.co/kibana/kibana:7.8.0                          sha256:df0a0da46dd18969158766dc188988eebd365e9e0150d62679d70812994f5aff   1.41GB
    #       docker.io/altinity/clickhouse-operator:0.16.0                         sha256:25d20cd54d289eb6975fb618ef5a0b716c2add250cf758235be9db7bcc304f0b   135MB
    #       docker.io/altinity/metrics-exporter:0.17.0                         sha256:609bcada6f8636ee40f03ef3804b385ef6248cc6bf35c7cfd17f71835b81c6da   50.2MB
    #       docker.io/grafana/grafana:7.5.2                          sha256:cdd789ccb9ea8c941d008916c02350057379875d56187e95a0d9ee823d3e2f6f   207MB




else
        echo "Warning: 'jq' tool is not available ; will (re)load all images to target cluster" 1>&2
        JQ_AVAILABLE=0
fi




for IMG_FILE in "${@}" ; do

    SKIP_RELOAD=0

    IMG_BASENAME="$(basename "$IMG_FILE")"
    MANIFEST_FILE="$(dirname "${IMG_FILE}")/.${IMG_BASENAME}.manifest"

    if [ ${JQ_AVAILABLE} -eq 1 ] ; then
    

        # If the image file has changed since last successful import, or was never imported (manifest file not saved) re-extract image manifest from archive

        if [ "${IMG_FILE}" -nt "${MANIFEST_FILE}" ] ; then

            # Extract sha256 and image tag from archive manifest
            echo "Extracting manifest from '${IMG_FILE}' archive..."

            # Note that currently, image files are called *tar.gz although they are uncompressed (so actually plain tar files)
            
            IMG_MANIFEST=$(cat "$IMG_FILE" | tar xO   manifest.json | jq -r '.[0]| ( .Config + "," + .RepoTags[0] )')
                # Here we get something like that : 
                #    19f6f42e7062ed6df3bc79bfbc2b3ef060f93ae8e3248f36c540d6a4808a0fe2.json quay.io/minio/minio:RELEASE.2021-10-13T00-23-17Z
        else
            # Re-read the saved manifest from previous success
            IMG_MANIFEST=$(cat "$MANIFEST_FILE")
        fi


        # Now check if this image exist on target cluster, with same hash

        IMG_HASH=$(cut -f1 -d,  <<< "${IMG_MANIFEST}")
        IMG_TAG=$(cut -f2 -d,  <<< "${IMG_MANIFEST}")
        # Here image hash has '.json' at the end, let's remove it to get the hash:
        IMG_HASH=${IMG_HASH%.json} 

        #debug echo "TAG=${IMG_TAG} HASH=${IMG_HASH}"

        # We look for same tag in cluster image list (note: when a repository-less image is imported, 'docker.io' is assumed by cluster)
        CLUSTER_IMG_HASH=$( grep "^\(docker.io/\)\?${IMG_TAG}\s" <<< "${CLUSTER_IMAGES}" 2> /dev/null || true)

        if [ "$CLUSTER_IMG_HASH" == "" ] ; then
            echo "No '${IMG_TAG}' image detected in cluster."
        elif grep "sha256:${IMG_HASH}" <<< "${CLUSTER_IMG_HASH}" > /dev/null ; then
            echo "Image '${IMG_TAG}' already in cluster with same hash."
            SKIP_RELOAD=1
        else
            echo "Image '${IMG_TAG}' in cluster has different hash."
                #debug echo "grep 'sha256:${IMG_HASH}' <<< '${CLUSTER_IMG_HASH}'"
                #debug echo "CLUSTER: ${CLUSTER_IMG_HASH} ::::: $(grep "sha256:${IMG_HASH}" <<< "${CLUSTER_IMG_HASH}")"
                #debug echo "IMG: ${IMG_HASH}"
        fi
    fi


    if [ "$SKIP_RELOAD" -eq 0 ] ; then
        echo "Importing '${IMG_FILE}' ..."
        ${K3D} image import "${IMG_FILE}" --cluster ${CLUSTER_NAME}
    fi

    echo "${IMG_MANIFEST}" > "${MANIFEST_FILE}"

done