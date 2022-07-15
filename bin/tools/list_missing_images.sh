#!/bin/bash -ue

KDIR=$(realpath $(dirname $0)/../..)
KUBECTL=$KDIR/downloads/kubectl 

$KUBECTL get pods -A  | grep -vi running | tail -n +2 | awk '{print $1,$2}' | xargs -n 2 $KUBECTL describe pod -n  | grep -i image | grep -i pull | sed -n 's/.*image "\([^"]*\)".*/\1/p' | sort -u

