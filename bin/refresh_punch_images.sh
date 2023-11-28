kooker load-image ghcr.io/punchplatform/punch-board:8.1-dev
kubectl rollout restart deployment punch-board --namespace punch-board
kooker load-image ghcr.io/punchplatform/artifacts-server:8.1-dev
kubectl rollout restart deployment artifacts-server --namespace artifacts-server
kooker load-image ghcr.io/punchplatform/punchline-java:8.1-dev
kooker load-image ghcr.io/punchplatform/punch-converter:8.1-dev
kooker load-image ghcr.io/punchplatform/punch-compiler:8.1-dev


