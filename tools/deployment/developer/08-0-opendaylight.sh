#!/bin/bash
set -xe
WORK_DIR=$(pwd)
helm install --namespace=openstack ${WORK_DIR}/opendaylight --name=opendaylight
./tools/deployment/developer/wait-for-pods.sh openstack

helm status opendaylight

