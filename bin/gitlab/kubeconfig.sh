#!/usr/bin/env bash

set -o errexit
set -o pipefail

ip route|awk '/default/'
REAL_IP=$(ip route|awk '/default/ { print $3 }' | sed 's/'\''//')
echo $REAL_IP docker >> /etc/hosts
sed -i -E -e 's/localhost|0\.0\.0\.0/docker/g' "$HOME/.kube/config"
