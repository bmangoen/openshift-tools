#!/usr/bin/env bash

export CLUSTER_NAME=${CLUSTER_NAME:-"ocp-cluster"}
export INSTALL_CONFIG_DIR=${INSTALL_CONFIG_DIR:-"$HOME/$CLUSTER_NAME"}

export CALICO_MANIFESTS_URL=${CALICO_MANIFESTS_URL:-"https://docs.projectcalico.org/manifests/ocp"}
export CALICO_INSTALLATION_CR_MANIFEST=${CALICO_INSTALLATION_CR_MANIFEST:-"${CALICO_MANIFESTS_URL}/01-cr-installation.yaml"}

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

function calico:installation:customresource() {
  if [ ! -z ${CALICO_VXLAN_CLUSTER_CIDR} ]
    then
      ${CAT} << EOF > ${INSTALL_CONFIG_DIR}/manifests/01-cr-installation.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  variant: Calico
  calicoNetwork:
    ipPools:
    - cidr: ${CALICO_VXLAN_CLUSTER_CIDR}
      encapsulation: VXLAN
EOF
      return
  fi
  
  curl -s ${CALICO_INSTALLATION_CR_MANIFEST} -o ${INSTALL_CONFIG_DIR}/manifests/01-cr-installation.yaml
}

# MAIN

sed -i 's/OpenShiftSDN/Calico/' ${INSTALL_CONFIG_DIR}/install-config.yaml

${OPENSHIFT_INSTALL_CMD} create manifests --dir ${INSTALL_CONFIG_DIR}

crds_directory="crds"
crds_manifests="01-crd-installation.yaml 01-crd-tigerastatus.yaml"

calico:download:manifests "${crds_directory}" "${crds_manifests}"

operator_directory="tigera-operator"
operator_manifests="00-namespace-tigera-operator.yaml 02-rolebinding-tigera-operator.yaml 02-role-tigera-operator.yaml 02-serviceaccount-tigera-operator.yaml 02-tigera-operator.yaml"

calico:download:manifests "${operator_directory}" "${operator_manifests}"

calico:installation:customresource