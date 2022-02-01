#!/bin/bash -ue

PUNCH_REPO_DIR=~/punch/punch-ng

SRC_DIR=${PUNCH_REPO_DIR}/applications/punch-punchlinejava-app/src/test/resources

cp $SRC_DIR/*ltr* $SRC_DIR/*lmc* .

sed -i -e '/bootstrap.servers/s/localhost:9092/kafka-kafka-bootstrap.processing:9092/g' \
		-e '/image.*\(punchline-java\|stormline\)/s/:.*/: ghcr.io\/punchplatform\/punchline-java:8.0-dev/g' \
		-e '/^\s*name:/s/_/-/g' \
		-e '/kind:/s/Stormline/StreamJavaPunchline/g' \
	*.y*ml