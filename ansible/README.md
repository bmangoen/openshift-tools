# Ansible

## Install cluster logging

Deployment of [Cluster Logging](https://docs.openshift.com/container-platform/4.2/logging/cluster-logging.html) by installing Elasticsearch and ClusterLogging operators.

### Requirements

- OpenShift Container Platform 4.X up&running.

- `Ansible` has to be installed on a server that can access to the OCP cluster API.

- Configuration file to authenticate to the OCP cluster via the client `oc` (by default, using `~/.kube/config`).

### Usage

- clone this git repository

```shell
git clone https://github.com/bmangoen/openshift-tools.git
```

- go to the `openshift-tools/ansible` directory and execute the playbook

```shell
cd openshift-tools/ansible && ansible-playbook playbooks/ocp4_deploy_cluster_logging.yaml
```

**NB**: You can also overwrite default variables to customize the deployment (cf. [role default variables](./roles/deploy_cluster_logging/))
