# Openshift tools

## Backup

### Requirements

- Ansible installed (>2.4)

- inventory hosts file (used for OCP installation)

- local mount directory on Ansible server for the backup (NFS mount, etc...)

### All-in-one

Execute the following ansible command to backup all OCP components

```shell
ansible-playbook -i inventory_hosts_file_location playbooks/backup_cluster.yml \
                 -e backup_srv_path=local_mount_backup_path \
```

### OCP configuration files

Add the tag **node-config**  to backup only /etc/origin directory (and subdirectories)

```shell
ansible-playbook -i inventory_hosts_file_location playbooks/backup_cluster.yml \
                 -e backup_srv_path=local_mount_backup_path \
                 -t node-config
```

### etcd

Add the tag **etcd**  to backup only etcd

```shell
ansible-playbook -i inventory_hosts_file_location playbooks/backup_cluster.yml \
                 -e backup_srv_path=local_mount_backup_path \
                 -t etcd
```
