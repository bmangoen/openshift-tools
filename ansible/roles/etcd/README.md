etcd
====

Manage the etcd cluster

Role Variables
--------------

1. Backup

- *backup_srv_path*: extra var for local backup directory

- etcd_config_backup_dir: configuration backup directory (generated name with ansible_date_time facts)

- etcd_data_backup_dir: data backup directory (generated name with ansible_date_time facts)

2. Restore

- *etcd_backup_date*: extra var for etcd restoring of a specific backup date

- etcd_config_restore_dir: configuration restore directory (generated name with etcd_backup_date extra var)

- etcd_data_restore_dir: data restore directory (generated name with etcd_backup_date extra var)

- etcd_initial_cluster_str, etcd_initial_cluster_token_str, etcd_initial_advertise_peer_urls_str: strings to get parameters for restoring etcd

Example Playbook
----------------
```yaml
- hosts: etcd
  roles:
  - name: etcd
```

License
-------

MIT
