# deploy_cluster_logging

Role that deploys the Cluster Logging on OpenShift 4.

## Requirements

The below requirements are needed on the host that executes the module `k8s`:

- python >= 2.7
- openshift >= 0.6
- PyYAML >= 3.11


## Role Variables

### OpenShift general variables

- `openshift_kubeconfig_path`: kubeconfig path

- `openshift_marketplace_namespace`: OpenShift marketplace namespace

```yaml
openshift_kubeconfig_path: "{{ ansible_env.HOME }}/.kube/config"
openshift_marketplace_namespace: "openshift-marketplace"
```

### OpenShift cluster logging variables

These variables are initialized by default for the setting of OpenShift Cluster logging

- `openshift_cluster_logging_manifests_dir_path`: directory path of cluster logging manifests

```yaml
openshift_cluster_logging_manifests_dir_path: "{{ ansible_env.HOME }}/cluster_logging_manifests"
```

- `openshift_cluster_logging_manifest_filenames`: list of manifests for creating required namespaces

```yaml
openshift_cluster_logging_manifest_filenames:
  - "elasticsearch_operator-namespace"
  - "openshift_logging-namespace"
```

### Elasticsearch operator variables

- `elasticsearch_operator_manifest_filenames`: list of manifests to create required OpenShift objects for Elasticsearch operator

```yaml
elasticsearch_operator_manifest_filenames:
  - "elasticsearch_operator-operatorgroup"
  - "elasticsearch_operator-subscription"
  - "elasticsearch_operator-role"
  - "elasticsearch_operator-rolebinding"
```

- `elasticsearch_operator_namespace`: Elasticsearch operator `Namespace` definition

```yaml
elasticsearch_operator_namespace:
  name: "elasticsearch-operator"
  labels:
    - 'openshift.io/cluster-logging: "true"'
    - 'openshift.io/cluster-monitoring: "true"'
```

- `elasticsearch_operator_operatorgroup`: Elasticsearch operator `OperatorGroup` definition

```yaml
elasticsearch_operator_operatorgroup:
  name: elasticsearch-operator
```

- `elasticsearch_operator_subscription`: Elasticsearch operator `Subscription` definition

```yaml
elasticsearch_operator_subscription:
  name: elasticsearch-subscription
```

### Cluster logging operator variables

- `cluster_logging_operator_manifest_filenames`: list of manifests to create required OpenShift objects for Cluster Logging operator

```yaml
cluster_logging_operator_manifest_filenames:
  - "cluster_logging_operator-operatorgroup"
  - "cluster_logging_operator-subscription"
  - "cluster_logging_operator-role"
  - "cluster_logging_operator-rolebinding"
```

- `cluster_logging_operator_namespace`: Cluster logging operator `Namespace` definition

```yaml
cluster_logging_operator_namespace:
  name: "openshift-logging"
  labels:
    - 'openshift.io/cluster-logging: "true"'
    - 'openshift.io/cluster-monitoring: "true"'
```

- `cluster_logging_operator_operatorgroup`: Cluster logging operator `OperatorGroup` definition

```yaml
cluster_logging_operator_operatorgroup:
  name: "{{ cluster_logging_operator_namespace.name }}-operatorgroup"
  spec:
    targetNamespaces:
    - "{{ cluster_logging_operator_namespace.name }}"
```

- `cluster_logging_operator_subscription`: Cluster logging operator `Subscription` definition

```yaml
cluster_logging_operator_subscription:
  name: "{{ cluster_logging_operator_namespace.name }}-subscription"
```

### Cluster logging instance variables

- `cluster_logging_instance_manifest_filename`: Cluster logging instance manifest filename

- `cluster_logging_instance_name`: Cluster logging instance instance name

```yaml
cluster_logging_instance_manifest_filename: "cluster_logging_instance"
cluster_logging_instance_name: "instance"
```

- Elasticsearch instance definition

```yaml
elasticsearch_resources:
  limits_memory: "6Gi"
  requests_memory: "6Gi"
elasticsearch_nodecount: 1
elasticsearch_nodeselector:
  - "node-role.kubernetes.io/infra: ''"
elasticsearch_redundancypolicy: "ZeroRedundancy"
elasticsearch_storage:
  storageclassname: "gp2"
  size: "50Gi"
```

- Kibana instance definition

```yaml
kibana_replicas: 1
kibana_nodeselector:
  - "node-role.kubernetes.io/infra: ''"
```
- Curator instance definition

```yaml
curator_schedule: "30 3 * * *"
curator_nodeselector:
  - "node-role.kubernetes.io/infra: ''"
```

## Dependencies

N/A

## Example Playbook

```yaml
- hosts: localhost
  roles:
     - role: deploy_cluster_logging
```
