#!/usr/bin/bash

source "common.sh"

CLUSTER_NAME="${1:?USAGE: hive-deploy-cluster.sh <cluster_name>}"

: "${OCP_VERSION:=4.3.8}"
: "${OCP_REGISTRY:=quay.io}"
: "${OCP_SSH_KEY_PATH:=${HOME}/.ssh/id_rsa}"
: "${OCP_INSTALL_CONFIG_PATH:=${HOME}/${CLUSTER_NAME}/install-config.yaml}"

: "${CAT:=cat}"
: "${AWK:=awk}"
: "${BASE64:=base64}"
: "${OC:=oc}"

command -v ${CAT} >/dev/null 2>&1 || { echo >&2 "can't find ${CAT} command.  Aborting."; exit 1; }
command -v ${AWK} >/dev/null 2>&1 || { echo >&2 "can't find ${AWK} command.  Aborting."; exit 1; }
command -v ${BASE64} >/dev/null 2>&1 || { echo >&2 "can't find ${BASE64} command.  Aborting."; exit 1; }
command -v ${OC} >/dev/null 2>&1 || { echo >&2 "can't find ${OC} command.  Aborting."; exit 1; }

function hive:secret:pullsecret() {
  if [ ! -z ${PULL_SECRET_FILE_PATH} ];
    then
      ${OC} create secret generic ${CLUSTER_NAME}-pull-secret \
        --from-file=.dockerconfigjson=${PULL_SECRET_FILE_PATH} \
        --type=kubernetes.io/dockerconfigjson \
        --namespace ${CLUSTER_NAME}
      return 0
    else
      ocp:log:info "Variable PULL_SECRET_FILE_PATH is not set. Attempting to use PULL_SECRET"
  fi

  [ ! -z ${PULL_SECRET} ] || { ocp:log:error "Variable PULL_SECRET is not set either. Please set PULL_SECRET_FILE_PATH or PULL_SECRET variable. Aborting."; exit 1; }

  ${CAT} << EOF | ${OC} apply -f -
apiVersion: v1
data:
  .dockerconfigjson: $(echo ${PULL_SECRET} | ${BASE64} -w0)
kind: Secret
metadata:
  name: ${CLUSTER_NAME}-pull-secret
  namespace: ${CLUSTER_NAME}
type: kubernetes.io/dockerconfigjson
EOF
}

function hive:secret:serviceaccount:gcp() {
  if [ ! -z ${CLOUD_SERVICE_ACCOUNT_CREDS_FILE_PATH} ];
    then
      ${OC} create secret generic ${CLUSTER_NAME}-gcp-creds \
        --from-file=osServiceAccount.json=${CLOUD_SERVICE_ACCOUNT_CREDS_FILE_PATH} \
        --namespace ${CLUSTER_NAME}
      return 0
    else
      ocp:log:info "Variable CLOUD_SERVICE_ACCOUNT_CREDS_FILE_PATH is not set. Attempting to use CLOUD_SERVICE_ACCOUNT_CREDS"
  fi

  [ ! -z ${CLOUD_SERVICE_ACCOUNT_CREDS} ] 
  \|| { ocp:log:error "Variable CLOUD_SERVICE_ACCOUNT_CREDS is not set either. Please set CLOUD_SERVICE_ACCOUNT_CREDS_FILE_PATH or CLOUD_SERVICE_ACCOUNT_CREDS variable. Aborting."; exit 1; }

  ${CAT} << EOF | ${OC} apply -f -
apiVersion: v1
data:
  osServiceAccount.json: $(echo ${CLOUD_SERVICE_ACCOUNT_CREDS} | ${BASE64} -w0)
kind: Secret
metadata:
  name: ${CLUSTER_NAME}-gcp-creds
  namespace: ${CLUSTER_NAME}
type: Opaque
EOF
}

function hive:secret:sshkeys() {
  [ -f ${OCP_SSH_KEY_PATH} ] || { ocp:log:error "${OCP_SSH_KEY_PATH} file does not exist. Aborting."; exit 1; }
  [ -f ${OCP_SSH_KEY_PATH}.pub ] || { ocp:log:error "${OCP_SSH_KEY_PATH}.pub file does not exist. Aborting."; exit 1; }

  ${OC} create secret generic ${CLUSTER_NAME}-ssh-key \
    --from-file=ssh-privatekey=${OCP_SSH_KEY_PATH} \
    --from-file=ssh-publickey=${OCP_SSH_KEY_PATH}.pub \
    --namespace ${CLUSTER_NAME}
}

function hive:clusterimageset() {
  ${CAT} << EOF | ${OC} apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: openshift-v${OCP_VERSION}
  namespace: ${CLUSTER_NAME}
spec:
  releaseImage: ${OCP_REGISTRY}/openshift-release-dev/ocp-release:${OCP_VERSION}-x86_64
EOF
}

function hive:secret:installconfig() {

  [ -f ${OCP_INSTALL_CONFIG_PATH} ] || { ocp:log:error "${OCP_INSTALL_CONFIG_PATH} file does not exist. Aborting."; exit 1; }
  
  ${OC} create secret generic ${CLUSTER_NAME}-install-config \
    --from-file=install-config.yaml=${OCP_INSTALL_CONFIG_PATH} \
    --namespace ${CLUSTER_NAME}
}

function get_domain() {
  [ -f ${OCP_INSTALL_CONFIG_PATH} ] || { ocp:log:error "No baseDomain because ${OCP_INSTALL_CONFIG_PATH} file does not exist. Aborting."; exit 1; }
  
  echo "$(${AWK} -F": " '/baseDomain/{print $2}' ${OCP_INSTALL_CONFIG_PATH})"
}

function get_region() {
  [ -f ${OCP_INSTALL_CONFIG_PATH} ] || { ocp:log:error "No region because ${OCP_INSTALL_CONFIG_PATH} file does not exist. Aborting."; exit 1; }
  
  echo "$(${AWK} -F": " '/region/{print $2}' ${OCP_INSTALL_CONFIG_PATH})"
}

function hive:clusterdeployment:gcp() {
  [ ! -z ${OCP_BASE_DOMAIN} ] || { ocp:log:error "Variable OCP_BASE_DOMAIN is not set. Aborting."; exit 1; }

  ${CAT} << EOF | ${OC} apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: ${CLUSTER_NAME}-cluster-deployment
  namespace: ${CLUSTER_NAME}
spec:
  baseDomain: ${OCP_BASE_DOMAIN}
  clusterName: ${CLUSTER_NAME}
  platform:
    gcp:
      credentialsSecretRef:
        name: ${CLUSTER_NAME}-gcp-creds
      region: ${OCP_REGION}
  provisioning:
    imageSetRef:
      name: openshift-v${OCP_VERSION}
    installConfigSecretRef:
      name: ${CLUSTER_NAME}-install-config
    sshPrivateKeySecretRef:
      name: ${CLUSTER_NAME}-ssh-key
  pullSecretRef:
    name: ${CLUSTER_NAME}-pull-secret
EOF
}

## MAIN

# Create the project for the cluster deployment via Hive
${OC} new-project ${CLUSTER_NAME}

hive:secret:pullsecret

hive:secret:serviceaccount:gcp

hive:secret:sshkeys

hive:clusterimageset

hive:secret:installconfig

OCP_BASE_DOMAIN=$(get_domain)
OCP_REGION=$(get_region)

hive:clusterdeployment:gcp

## END MAIN