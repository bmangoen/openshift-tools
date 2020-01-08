# Ansible

Ansible plays to manage OCP cluster

## Backup

### Requirements

Ansible has to be installed (>2.4) on a server that can access to all the Openshift cluster nodes.

If you have the inventory hosts file used for OCP installation, you can use it to backup and restore the cluster. 

You can mount a local directory on the Ansible server for the backup.

To set the variables for the backup, you can use:

```shell
INVENTORY_HOSTS=<your inventory hosts file>
LOCAL_MOUNT_BACKUP_PATH=<your local directory for backup>
```

### All-in-one

Execute the following ansible command to backup all OCP components

```shell
ansible-playbook playbooks/backup_cluster.yml \
                 -i ${INVENTORY_HOSTS} \
                 -e backup_srv_path=${LOCAL_MOUNT_BACKUP_PATH}
```

### OCP configuration files

Add the tag `node-config`  to backup only /etc/origin directory (and subdirectories)

```shell
ansible-playbook playbooks/backup_cluster.yml \
                 -i ${INVENTORY_HOSTS} \
                 -e backup_srv_path=${LOCAL_MOUNT_BACKUP_PATH} \
                 -t node-config
```

### etcd

Add the tag `etcd`  to backup only etcd

```shell
ansible-playbook playbooks/backup_cluster.yml \
                 -i ${INVENTORY_HOSTS} \
                 -e backup_srv_path=${LOCAL_MOUNT_BACKUP_PATH} \
                 -t etcd
```

## Restore

### Requirements

Ansible has to be installed (>2.4) on a server that can access to all the Openshift cluster nodes.

If you have the inventory hosts file used for OCP installation, you can use it to backup and restore the cluster. 

You have to mount the local directory on the Ansible server where the backup objects are stored.

To set the variables for the backup, you can use:

```shell
INVENTORY_HOSTS=<your inventory hosts file>
LOCAL_MOUNT_BACKUP_PATH=<your local directory of backup>
BACKUP_DATE=<date of your backup>
```

### All-in-one

Execute the following ansible command to backup all OCP components

```shell
ansible-playbook playbooks/restore_cluster.yml \
                 -i ${INVENTORY_HOSTS} \
                 -e backup_srv_path=${LOCAL_MOUNT_BACKUP_PATH} \
                 -e openshift_restore_date=${BACKUP_DATE}
```

### etcd

Add the tag `etcd`  to restore only etcd

```shell
ansible-playbook playbooks/restore_cluster.yml \
                 -i ${INVENTORY_HOSTS} \
                 -e backup_srv_path=${LOCAL_MOUNT_BACKUP_PATH} \
                 -e openshift_restore_date=${BACKUP_DATE} \
                 -t etcd
```
