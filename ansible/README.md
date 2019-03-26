# Openshift tools

## Backup

### Requirements

- Ansible installed (>2.4)

- inventory hosts file (used for OCP installation)

- local mount directory on Ansible server for the backup (NFS mount, etc...)

### All-in-one

Execute the following ansible command to backup all OCP components

```shell
ansible-playbook playbooks/backup_cluster.yml \
                 -i inventory_hosts_file_location \
                 -e backup_srv_path=local_mount_backup_path
```

### OCP configuration files

Add the tag **node-config**  to backup only /etc/origin directory (and subdirectories)

```shell
ansible-playbook playbooks/backup_cluster.yml \
                 -i inventory_hosts_file_location \
                 -e backup_srv_path=local_mount_backup_path \
                 -t node-config
```

### etcd

Add the tag **etcd**  to backup only etcd

```shell
ansible-playbook playbooks/backup_cluster.yml \
                 -i inventory_hosts_file_location \
                 -e backup_srv_path=local_mount_backup_path \
                 -t etcd
```

## Restore

### Requirements

- Ansible installed (>2.4)

- inventory hosts file (used for OCP installation)

- local mount directory on Ansible server with backup objects

### All-in-one

Execute the following ansible command to backup all OCP components

```shell
ansible-playbook playbooks/restore_cluster.yml \
                 -i inventory_hosts_file_location \
                 -e backup_srv_path=local_mount_restore_path \
                 -e openshift_restore_date=backup_date
```

### etcd

Add the tag **etcd**  to restore only etcd

```shell
ansible-playbook playbooks/restore_cluster.yml \
                 -i inventory_hosts_file_location \
                 -e backup_srv_path=local_mount_restore_path \
                 -e openshift_restore_date=backup_date \
                 -t etcd
```
