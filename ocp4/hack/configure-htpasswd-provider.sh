#!/usr/bin/env bash

export HTPASSWD_PATH=${HTPASSWD_PATH:-"$HOME/users.htpasswd"}
export HTPASSWD_PROVIDER_NAME=${HTPASSWD_PROVIDER_NAME:-"htpasswd"}
export OC_CMD=${OC_CMD:-"oc"}

command -v grep >/dev/null 2>&1 || { echo >&2 "can't find grep command.  Aborting."; exit 1; }
command -v cat >/dev/null 2>&1 || { echo >&2 "can't find cat command.  Aborting."; exit 1; }
command -v awk >/dev/null 2>&1 || { echo >&2 "can't find awk command.  Aborting."; exit 1; }
command -v ${OC_CMD} >/dev/null 2>&1 || { echo >&2 "can't find oc command.  Aborting."; exit 1; }

## check if there is still an oauth conf
${OC_CMD} get oauth cluster -o template --template {{.spec}} | grep "map\[\]" >/dev/null 2>&1 || { echo >&2 "Already an existant OAuth configuration.  Aborting."; exit 1; }

${OC_CMD} -n openshift-config create secret generic htpass-secret --from-file=htpasswd=${HTPASSWD_PATH} 

cat <<EOF | ${OC_CMD} apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: ${HTPASSWD_PROVIDER_NAME} 
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF

## give cluster-admin to users
USERS=$(awk -F":" '{print $1}' ${HTPASSWD_PATH})

for user in ${USERS}; do
    ${OC_CMD} adm policy add-cluster-role-to-user cluster-admin ${user};
done