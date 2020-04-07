#!/bin/bash

CLOUD_PROVIDER="${1:?USAGE: generate-install-config.sh <cloud_provider>}"

: "${CLUSTER_NAME:=ocp4-cluster}"
: "${CLUSTER_INSTALL_DIR:=${HOME}/${CLUSTER_NAME}}"

## GCP specific vars
: "${GCP_PROJECTID:=ocp-project}"

## Azure specific vars
: "${AZURE_RESOURCE_GROUP:=ocp-rg}"
: "${AZURE_NETWORK_RESOURCE_GROUP:=${AZURE_RESOURCE_GROUP}}"

## Common vars
: "${BASE_DOMAIN:=ocp4.example.com}"

: "${NETWORK:=ocp4-network}"
: "${CONTROL_PLANE_SUBNET:=ocp-nodes-net}"
: "${COMPUTE_SUBNET:=ocp-nodes-net}"
: "${MACHINE_CIDR:=192.168.0.0/24}"
: "${CLUSTER_CIDR:=10.128.0.0/14}"
: "${HOST_PREFIX:=23}"
: "${SERVICE_CIDR:=172.30.0.0/16}"

: "${SSH_PUB_KEY_PATH:=$HOME/.ssh/id_rsa.pub}"
: "${OCP_ADDITIONAL_TRUST_BUNDLE_PATH:=$HOME/additionaltrustbundle.cert}"

: "${CAT:=cat}"
: "${AWK:=awk}"
: "${MKDIR:=mkdir}"

command -v ${CAT} >/dev/null 2>&1 || { echo >&2 "can't find ${CAT} command.  Aborting."; exit 1; }
command -v ${MKDIR} >/dev/null 2>&1 || { echo >&2 "can't find ${MKDIR} command.  Aborting."; exit 1; }

## Functions

function get_default_region() {
  if [ -z ${REGION} ]; then
    case ${CLOUD_PROVIDER} in
      gcp)
        echo "europe-west1"
        ;;
      azure)
        echo "westeurope"
        ;;
    esac
  else
    echo "${REGION}"
  fi
}

function get_install_config_platform() {
  local REGION="$(get_default_region)"

  case ${CLOUD_PROVIDER} in
    gcp)
      ${CAT} << EOF
  gcp:
    projectID: ${GCP_PROJECTID}
    region: ${REGION}
    network: ${NETWORK}
    controlPlaneSubnet: ${CONTROL_PLANE_SUBNET}
    computeSubnet: ${COMPUTE_SUBNET}
EOF
      ;;
    azure)
      ${CAT} << EOF
  azure:
    baseDomainResourceGroupName: ${AZURE_RESOURCE_GROUP}
    region: ${REGION}
    networkResourceGroupName: ${AZURE_NETWORK_RESOURCE_GROUP}
    virtualNetwork: ${NETWORK}
    controlPlaneSubnet: ${CONTROL_PLANE_SUBNET}
    computeSubnet: ${COMPUTE_SUBNET}
EOF
      ;;
  esac
}

function get_additional_trust_bundle() {
  if [ -f ${OCP_ADDITIONAL_TRUST_BUNDLE_PATH} ]; then
    ${CAT} << EOF
additionalTrustBundle: |
$(${CAT} ${OCP_ADDITIONAL_TRUST_BUNDLE_PATH} | ${AWK} '{print "  " $0}')
EOF
  fi
}

function get_image_mirrors() {
  if [ ! -z ${PRIVATE_REGISTRY_URL} ] && [ ! -z ${PRIVATE_REGISTRY_REPO} ]; then
    ${CAT} << EOF
imageContentSources:
- mirrors:
  - ${PRIVATE_REGISTRY_URL}/${PRIVATE_REGISTRY_REPO}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${PRIVATE_REGISTRY_URL}/${PRIVATE_REGISTRY_REPO}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF
  fi
}

function ocp:install:config() {   
  [ ! -z ${PULL_SECRET} ] || { echo "Variable PULL_SECRET is not set. Aborting."; exit 1; }

  [ -f ${SSH_PUB_KEY_PATH} ] || { echo "${SSH_PUB_KEY_PATH} file does not exist. Aborting."; exit 1; }

  [ ! -f ${CLUSTER_INSTALL_DIR}/install-config.yaml ] || { echo "${CLUSTER_INSTALL_DIR}/install-config.yaml file already exists. Please remove it. Aborting"; exit 1; }

  local SSHPUBKEY=$(${CAT} ${SSH_PUB_KEY_PATH})

  if [ ! -d ${CLUSTER_INSTALL_DIR} ];
    then
      ${MKDIR} ${CLUSTER_INSTALL_DIR}
  fi

    ${CAT} << EOF > ${CLUSTER_INSTALL_DIR}/install-config.yaml
apiVersion: v1
baseDomain: ${BASE_DOMAIN}
compute:
- hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 3
controlPlane:
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 3
metadata:
  name: ${CLUSTER_NAME}
networking:
  clusterNetwork:
  - cidr: ${CLUSTER_CIDR}
    hostPrefix: ${HOST_PREFIX}
  machineCIDR: ${MACHINE_CIDR}
  networkType: OpenShiftSDN
  serviceNetwork:
  - ${SERVICE_CIDR}
platform:
$(get_install_config_platform)
publish: Internal
pullSecret: '${PULL_SECRET}'
sshKey: |
  ${SSHPUBKEY}
$(get_image_mirrors)
$(get_additional_trust_bundle)
EOF
}

## MAIN BEGIN

ocp:install:config

## MAIN END