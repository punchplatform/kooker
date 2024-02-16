#!/bin/bash
# @author: PunchPlatform Team
# @desc: Update script to refresh only the punch images.

VERSION=8.1-dev
RLINE_VERSION=0.1-dev

kooker load-image ghcr.io/punchplatform/punch-board:${VERSION}
kubectl rollout restart deployment punch-board --namespace punch-board
kooker load-image ghcr.io/punchplatform/artifacts-server:${VERSION}
kubectl rollout restart deployment artifacts-server --namespace artifacts-server
kooker load-image ghcr.io/punchplatform/punchline-java:${VERSION}
kooker load-image ghcr.io/punchplatform/punch-converter:${VERSION}
kooker load-image ghcr.io/punchplatform/punch-compiler:${VERSION}
kooker load-image ghcr.io/punchplatform/rline:${RLINE_VERSION}
kooker load-image ghcr.io/punchplatform/punchline-python:${VERSION}
kooker load-image ghcr.io/punchplatform/jupypunch:${VERSION}

