#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -ex
: ${WORK_DIR:="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."}
source ${WORK_DIR}/tools/gate/vars.sh
source ${WORK_DIR}/tools/gate/funcs/helm.sh
source ${WORK_DIR}/tools/gate/funcs/kube.sh
source ${WORK_DIR}/tools/gate/funcs/network.sh

if [ "x$PVC_BACKEND" == "xceph" ]; then
  kubectl label nodes ceph-mon=enabled --all --overwrite
  kubectl label nodes ceph-osd=enabled --all --overwrite
  kubectl label nodes ceph-mds=enabled --all --overwrite
  kubectl label nodes ceph-rgw=enabled --all --overwrite
  kubectl label nodes ceph-mgr=enabled --all --overwrite
fi

if [ "x$SDN_PLUGIN" == "xovs" ]; then
  kubectl label nodes openvswitch=enabled --all --overwrite
elif [ "x$SDN_PLUGIN" == "xlinuxbridge" ]; then
  # first unlabel nodes with 'openvswitch' tag, which is applied by default
  # by kubeadm-aio docker image
  kubectl label nodes openvswitch- --all --overwrite
  kubectl label nodes linuxbridge=enabled --all --overwrite
fi

#FIXME(portdirect): Ensure RBAC rules are essentially open until support added
# to all charts and helm-toolkit.
kubectl replace -f ${WORK_DIR}/tools/kubeadm-aio/assets/opt/rbac/dev.yaml

helm install --namespace=openstack ${WORK_DIR}/dns-helper --name=dns-helper
kube_wait_for_pods openstack ${POD_START_TIMEOUT_OPENSTACK}
