# Environment

There are infrastructure for some services. Some of them for development, other for infrastructure.

## NFS provisioner

It's needed for getting persistance volumes for db instances, redis and other.

## Ingress

There is a nginx implementation of ingress. Node ports are used for get traffic from external network, because configuration is working on single machine in the wardrobe.

## Style

1. All names for terraform resources have to be splitted by dash.

## Problems

1. There is a problem with deleting resource with PVC. PV don't want to be deleted.
2. There is a problem with connecting to web interface of keycloak

## Improvements

1. Pack all sensitive information to k8s secrets
2. Check places and pack values to variabe where needed

## Terraform variables

### Obligatory

1. gitlab-db-username - gitlab database superuser
2. gitlab-db-password - gitlab database superuser password
3. nfs-host - host for connecting to nfs for PV provision
4. identity-provider-db-username - identity provider database superuser
5. identity-provider-db-password - identity provider database superuser password
6. identity-provider-admin-password - identity provider initial admin password
7. identity-provider-admin-login - identity provider initial admin login
8. lets-encrypt-email - email for certificates provision