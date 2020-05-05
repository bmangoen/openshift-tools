#!/usr/bin/env bash

: "${CLUSTER_NAME:-"ocp-cluster"}"
: "${INSTALL_CONFIG_DIR:-"$HOME/$CLUSTER_NAME"}"

: "${CALICO_MANIFESTS_URL:-"https://docs.projectcalico.org/manifests/ocp"}"

: "${CALICO_REGISTRY:=quay.io}"

: "${SED:=sed}"
: "${CAT:=cat}"
: "${CURL:=curl}"

: "${OPENSHIFT_INSTALL_CMD:=openshift-install}"

command -v ${SED} >/dev/null 2>&1 || { echo >&2 "can't find ${SED} command.  Aborting."; exit 1; }
command -v ${CAT} >/dev/null 2>&1 || { echo >&2 "can't find ${CAT} command.  Aborting."; exit 1; }
command -v ${CURL} >/dev/null 2>&1 || { echo >&2 "can't find ${CURL} command.  Aborting."; exit 1; }
command -v ${OPENSHIFT_INSTALL_CMD} >/dev/null 2>&1 || { echo >&2 "can't find ${OPENSHIFT_INSTALL_CMD} command.  Aborting."; exit 1; }

function calico:download:manifests() {
  if [ $# -ne 2 ];
    then
      echo "Usage: calico:download:manifests <directory> <manifests>"
      return 1
  fi

  local directory=$1
  local manifests=$2

  for manifest in ${manifests}; do
      curl -s ${CALICO_MANIFESTS_URL}/${directory}/${manifest} -o ${INSTALL_CONFIG_DIR}/manifests/${manifest}
  done
}

function get_calico_network_encapsulation() {
  if [ ! -z ${CALICO_VXLAN_CLUSTER_CIDR} ]
    then
      ${CAT} << EOF
  calicoNetwork:
    ipPools:
    - cidr: ${CALICO_VXLAN_CLUSTER_CIDR}
      encapsulation: VXLAN
EOF
  fi
}

function calico:installation:customresource() {
  ${CAT} << EOF > ${INSTALL_CONFIG_DIR}/manifests/01-cr-installation.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  variant: Calico
  registry: ${CALICO_REGISTRY}
$(get_calico_network_encapsulation)
EOF
}

## MAIN BEGIN

sed -i 's/OpenShiftSDN/Calico/' ${INSTALL_CONFIG_DIR}/install-config.yaml

${OPENSHIFT_INSTALL_CMD} create manifests --dir ${INSTALL_CONFIG_DIR}

#TODO: get dynamically the manifests to download

crds_directory="crds"
crds_manifests="01-crd-installation.yaml 01-crd-tigerastatus.yaml"

calico:download:manifests "${crds_directory}" "${crds_manifests}"

kdd_directory="crds/calico/kdd"
kdd_manifests="02-crd-bgpconfiguration.yaml 02-crd-bgppeer.yaml 02-crd-blockaffinity.yaml 02-crd-clusterinformation.yaml 02-crd-felixconfiguration.yaml 02-crd-globalnetworkpolicy.yaml 02-crd-globalnetworkset.yaml 02-crd-hostendpoint.yaml 02-crd-ipamblock.yaml 02-crd-ipamconfig.yaml 02-crd-ipamhandle.yaml 02-crd-ippool.yaml 02-crd-networkpolicy.yaml 02-crd-networkset.yaml"

calico:download:manifests "${kdd_directory}" "${kdd_manifests}"

operator_directory="tigera-operator"
operator_manifests="00-namespace-tigera-operator.yaml 02-rolebinding-tigera-operator.yaml 02-role-tigera-operator.yaml 02-serviceaccount-tigera-operator.yaml 02-configmap-calico-resources.yaml 02-configmap-tigera-install-script.yaml 02-tigera-operator.yaml"

calico:download:manifests "${operator_directory}" "${operator_manifests}"

calico:installation:customresource

## MAIN END