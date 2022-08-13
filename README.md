# Environment

There are infrastructure for some services. Some of them for development, other for infrastructure.

## NFS provisioner

It's needed for getting persistance volumes for db instances, redis and other.

## Ingress

There is a nginx implementation of ingress. Node ports are used for get traffic from external network, because configuration is working on single machine in the wardrobe.

## Style

1. All names for terraform resources have to be splitted by dash.

## Improvements

1. Pack all sensitive information to k8s secrets
2. Check places and pack values to variabe where needed
3. Come up with backups for databases

## Terraform variables

### Obligatory

1. postgres-admin-username - database superuser
2. postgres-admin-password - database superuser password
3. nfs-host - host for connecting to nfs for PV provision
4. identity-provider-db-username - identity provider database user
5. identity-provider-db-password - identity provider database user password
6. identity-provider-admin-password - identity provider initial admin password
7. identity-provider-admin-login - identity provider initial admin login
8. lets-encrypt-email - email for certificates provision
9. gitlab-db-username - gitlab database user
10. gitlab-db-password - gitlab database password
11. database-host - external host of database(almost external - router don't have port-forwarding to it)
12. redis-password - password for connections to redis
13. minio-admin-user - minio initial user login
14. minio-admin-pass - minio initial user password

## Cluster

Container runtime - containerd

### Versions
1. Flannel - 0.14.1 - https://raw.githubusercontent.com/flannel-io/flannel/v0.14.1/Documentation/kube-flannel.yml
2. kubectl - 1.22.4
3. kubeadm - 1.22.4
4. kubelet - 1.22.4
