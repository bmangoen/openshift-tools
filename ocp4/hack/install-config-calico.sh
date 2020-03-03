#!/usr/bin/env bash

export CLUSTER_NAME=${CLUSTER_NAME:-"ocp-cluster"}
export INSTALL_CONFIG_DIR=${INSTALL_CONFIG_DIR:-"$HOME/$CLUSTER_NAME"}
export CALICO_MANIFESTS_URL=${CALICO_MANIFESTS_URL:-"https://docs.projectcalico.org/manifests/ocp"}

export OPENSHIFT_INSTALL_CMD=${OPENSHIFT_INSTALL_CMD:-"openshift-install"}

command -v sed >/dev/null 2>&1 || { echo >&2 "can't find sed command.  Aborting."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "can't find curl command.  Aborting."; exit 1; }
command -v declare >/dev/null 2>&1 || { echo >&2 "can't find declare command.  Aborting."; exit 1; }
command -v ${OPENSHIFT_INSTALL_CMD} >/dev/null 2>&1 || { echo >&2 "can't find openshift-install command.  Aborting."; exit 1; }

function download:calico:manifests() {
    if [ $# -ne 2 ];
      then
        echo "Usage: download:calico:manifest directory manifests"
        return 1
    fi

    local directory=$1
    local manifests=$2

    for manifest in ${manifests}; do
       curl -s ${CALICO_MANIFESTS_URL}/${directory}/${manifest} -o ${INSTALL_CONFIG_DIR}/manifests/${manifest}
    done
}

sed -i 's/OpenShiftSDN/Calico/' ${INSTALL_CONFIG_DIR}/install-config.yaml

${OPENSHIFT_INSTALL_CMD} create manifests --dir ${INSTALL_CONFIG_DIR}

#declare -A manifests=( [crds]="01-crd-installation.yaml 01-crd-tigerastatus.yaml" \
#                       [tigera-operator]="00-namespace-tigera-operator.yaml 02-rolebinding-tigera-operator.yaml 02-role-tigera-operator.yaml 02-serviceaccount-tigera-operator.yaml 02-tigera-operator.yaml" )

crds_directory="crds"
crds_manifests="01-crd-installation.yaml 01-crd-tigerastatus.yaml"

download:calico:manifests "${crds_directory}" "${crds_manifests}"

operator_directory="tigera-operator"
operator_manifests="00-namespace-tigera-operator.yaml 02-rolebinding-tigera-operator.yaml 02-role-tigera-operator.yaml 02-serviceaccount-tigera-operator.yaml 02-tigera-operator.yaml"

download:calico:manifests "${operator_directory}" "${operator_manifests}"

curl -s ${CALICO_MANIFESTS_URL}/01-cr-installation.yaml -o ${INSTALL_CONFIG_DIR}/manifests/01-cr-installation.yaml
