#!/bin/bash

CLOUD_PROVIDER="${1:?USAGE: generate-install-config.sh <cloud_provider>}"

: "${CLUSTER_NAME:=ocp4-cluster}"
: "${CLUSTER_INSTALL_DIR:=${HOME}/${CLUSTER_NAME}}"

## GCP specific vars
: "${GCP_PROJECTID:=ocp-project}"
: "${GCP_CONTROL_PLANE_VM_TYPE:=n1-standard-4}"
: "${GCP_WORKER_VM_TYPE:=n1-standard-4}"

## Azure specific vars
: "${AZURE_RESOURCE_GROUP:=ocp-rg}"
: "${AZURE_NETWORK_RESOURCE_GROUP:=${AZURE_RESOURCE_GROUP}}"
### Control plane vars
: "${AZURE_CONTROL_PLANE_VM_TYPE:=Standard_D8s_v3}"
: "${AZURE_CONTROL_PLANE_OS_DISK:=1024}"
### Worker vars
: "${AZURE_WORKER_VM_TYPE:=Standard_D2s_v3}"
: "${AZURE_WORKER_OS_DISK:=128}"

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
: "${PUBLISH_METHOD:=Internal}"

: "${IS_REGISTRY_PROXY_CACHE:=false}"
: "${SOURCE_REGISTRY_URL:=quay.io}"
: "${SOURCE_REGISTRY_REPO:=openshift-release-dev}"

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

function get_control_plane_platform() {
  case ${CLOUD_PROVIDER} in
    gcp)
      if [ -z ${CONTROL_PLANE_VM_TYPE} ]; then
        CONTROL_PLANE_VM_TYPE="${GCP_CONTROL_PLANE_VM_TYPE}"
      fi
      ${CAT} << EOF
  platform:
    gcp:
      type: ${CONTROL_PLANE_VM_TYPE}
EOF
      ;;
    azure)
      if [ -z ${CONTROL_PLANE_VM_TYPE} ]; then
        CONTROL_PLANE_VM_TYPE="${AZURE_CONTROL_PLANE_VM_TYPE}"
      fi
      ${CAT} << EOF
  platform:
    azure:
      type: ${CONTROL_PLANE_VM_TYPE}
      osDisk:
        diskSizeGB: ${AZURE_CONTROL_PLANE_OS_DISK}
EOF
      ;;
    *)
      ${CAT} << EOF
  platform: {}
EOF
  esac
}

function get_worker_platform() {
  case ${CLOUD_PROVIDER} in
    gcp)
      if [ -z ${WORKER_VM_TYPE} ]; then
        WORKER_VM_TYPE="${GCP_WORKER_VM_TYPE}"
      fi
      ${CAT} << EOF
  platform:
    gcp:
      type: ${WORKER_VM_TYPE}
EOF
      ;;
    azure)
      if [ -z ${WORKER_VM_TYPE} ]; then
        WORKER_VM_TYPE="${AZURE_WORKER_VM_TYPE}"
      fi
      ${CAT} << EOF
  platform:
    azure:
      type: ${WORKER_VM_TYPE}
      osDisk:
        diskSizeGB: ${AZURE_WORKER_OS_DISK}
EOF
      ;;
    *)
      ${CAT} << EOF
  platform: {}
EOF
  esac
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
    # If the private registry can manage the proxy/cache registry of quay.io
    if [ ! -z ${IS_REGISTRY_PROXY_CACHE} ] && [ ${IS_REGISTRY_PROXY_CACHE} = true ]; then
      ${CAT} << EOF
imageContentSources:
- mirrors:
  - ${PRIVATE_REGISTRY_URL}/${PRIVATE_REGISTRY_REPO}
  source: ${SOURCE_REGISTRY_URL}/${SOURCE_REGISTRY_REPO}
EOF
      return
    else
      ${CAT} << EOF
imageContentSources:
- mirrors:
  - ${PRIVATE_REGISTRY_URL}/${PRIVATE_REGISTRY_REPO}
  source: ${SOURCE_REGISTRY_URL}/${SOURCE_REGISTRY_REPO}/ocp-release
- mirrors:
  - ${PRIVATE_REGISTRY_URL}/${PRIVATE_REGISTRY_REPO}
  source: ${SOURCE_REGISTRY_URL}/${SOURCE_REGISTRY_REPO}/ocp-v4.0-art-dev
EOF
    fi
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
metadata:
  name: ${CLUSTER_NAME}
baseDomain: ${BASE_DOMAIN}
controlPlane:
  hyperthreading: Enabled
  name: master
$(get_control_plane_platform)
  replicas: 3
compute:
- hyperthreading: Enabled
  name: worker
$(get_worker_platform)
  replicas: 3
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
publish: ${PUBLISH_METHOD}
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