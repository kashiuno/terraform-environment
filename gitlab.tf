variable "gitlab-namespace" {
  type    = string
  default = "gitlab"
}

variable "gitlab-database" {
  type    = string
  default = "gitlab"
}

variable "gitlab-db-username" {
  type      = string
  sensitive = true
}

variable "gitlab-db-password" {
  type      = string
  sensitive = true
}

variable "gitlab-db-secret-name" {
  type    = string
  default = "db-secret"
}

variable "gitlab-redis-secret-name" {
  type    = string
  default = "redis-secret"
}

variable "gitlab-object-storage-secret-name" {
  type    = string
  default = "object-storage-secret"
}

variable "gitlab-minio-username" {
  type      = string
  sensitive = true
}

variable "gitlab-minio-password" {
  type      = string
  sensitive = true
}

variable "gitlab-host" {
  type    = string
  default = "git.kashiuno.com"
}

variable "gitlab-service-name" {
  type    = string
  default = "gitlab"
}

variable "gitlab-email" {
  type      = string
  sensitive = true
}

variable "gitlab-email-password" {
  type      = string
  sensitive = true
}

variable "gitlab-email-password-secret-name" {
  type    = string
  default = "email-pass"
}

resource "kubernetes_secret" "gitlab-email-secret" {
  metadata {
    name = var.gitlab-email-password-secret-name
    namespace = var.gitlab-namespace
  }
  data = {
    password = var.gitlab-email-password
  }
}

resource "kubernetes_secret" "db-secret" {
  metadata {
    name      = var.gitlab-db-secret-name
    namespace = var.gitlab-namespace
  }
  data = {
    password = var.gitlab-db-password
  }
}

resource "kubernetes_secret" "redis-secret" {
  metadata {
    name      = var.gitlab-redis-secret-name
    namespace = var.gitlab-namespace
  }
  data = {
    password = var.redis-password
  }
}

resource "kubernetes_secret" "object-storage-secret" {
  metadata {
    name      = var.gitlab-object-storage-secret-name
    namespace = var.gitlab-namespace
  }
  data = {
    connection = jsonencode({
      provider              = "AWS"
      aws_access_key_id     = var.gitlab-minio-username
      aws_secret_access_key = var.gitlab-minio-password
      endpoint              = "minio-svc.object-storage:9000"
    })
  }
}

resource "helm_release" "gitlab" {
  name      = "gitlab"
  namespace = var.gitlab-namespace

  repository = "https://charts.gitlab.io/"
  chart      = "gitlab"

  create_namespace = true

  set {
    name  = "global.edition"
    value = "ce"
  }

  # Object storage
  set {
    name  = "global.minio.enabled"
    value = false
  }

  # Registry
  set {
    name  = "registry.enabled"
    value = false
  }

  # Shell
  set {
    name  = "gitlab.gitlab-shell.service.type"
    value = "NodePort"
  }

  set {
    name  = "gitlab.gitlab-shell.service.nodePort"
    value = 30022
  }

  # Grafana
  set {
    name  = "global.grafana.enabled"
    value = false
  }

  # Hosts
  set {
    name  = "global.hosts.domain"
    value = var.external-domain
  }

  set {
    name  = "global.hosts.gitlab.serviceName"
    value = var.gitlab-service-name
  }

  set {
    name  = "global.hosts.gitlab.name"
    value = var.gitlab-host
  }

  set {
    name  = "global.hosts.gitlab.https"
    value = true
  }

  set {
    name  = "global.hosts.externalIP"
    value = var.external-ip
  }

  # Ingress
  set {
    name  = "global.ingress.class"
    value = var.ingress-class-name
  }

  set {
    name  = "global.ingress.enabled"
    value = true
  }

  set {
    name  = "nginx-ingress.enabled"
    value = false
  }

  set {
    name  = "global.ingress.configureCertmanager"
    value = false
  }

  set {
    name  = "global.ingress.annotations.\"cert-manager\\.io/cluster-issuer\""
    value = var.lets-encrypt-issuer-name
  }

  set {
    name  = "global.ingress.annotations.\"acme\\.cert-manager\\.io/http01-edit-in-place\""
    value = "true"
  }

  set {
    name  = "global.ingress.annotations.\"cert-manager\\.io/issue-temporary-certificate\""
    value = "true"
  }

  set {
    name  = "gitlab.webservice.ingress.tls.secretName"
    value = var.lets-encrypt-secret-name
  }

  # Database
  set {
    name  = "postgresql.install"
    value = false
  }

  set {
    name  = "global.psql.host"
    value = "postgres-external-service.database"
  }

  set {
    name  = "global.psql.database"
    value = var.gitlab-database
  }

  set {
    name  = "global.psql.username"
    value = var.gitlab-db-username
  }

  set {
    name  = "global.psql.password.secret"
    value = var.gitlab-db-secret-name
  }

  set {
    name  = "global.psql.password.key"
    value = "password"
  }

  # Redis
  set {
    name  = "redis.install"
    value = false
  }

  set {
    name  = "global.redis.host"
    value = "redis-svc.key-value"
  }

  set {
    name  = "global.redis.password.enabled"
    value = true
  }

  set {
    name  = "global.redis.password.secret"
    value = var.gitlab-redis-secret-name
  }

  set {
    name  = "global.redis.password.key"
    value = "password"
  }

  # Cert manager
  set {
    name  = "certmanager.install"
    value = false
  }

  set {
    name  = "global.ingress.configureCertmanager"
    value = false
  }

  # Sidekiq, WebService, Gitaly
  set {
    name  = "global.appConfig.object_store.enabled"
    value = true
  }

  set {
    name  = "global.appConfig.object_store.connection.secret"
    value = var.gitlab-object-storage-secret-name
  }

  set {
    name  = "global.appConfig.object_store.connection.key"
    value = "connection"
  }

  # WebService
  set {
    name  = "gitlab.webservice.image.repository"
    value = "registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ce"
  }

  set {
    name  = "gitlab.webservice.workhorse.image"
    value = "registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce"
  }

  set {
    name  = "gitlab.webservice.hpa.cpu.targetAverageValue"
    value = "500m"
  }

  # Gitaly
  set {
    name  = "global.gitaly.enabled"
    value = true
  }

  set {
    name  = "gitlab.gitaly.tolerations[0].key"
    value = "storage"
  }

  set {
    name  = "gitlab.gitaly.tolerations[0].operator"
    value = "Exists"
  }

  set {
    name  = "gitlab.gitaly.tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "gitlab.gitaly.persistence.storageClass"
    value = var.nfs-storage-class-name
  }

  # Prometheus
  set {
    name  = "prometheus.install"
    value = false
  }

  # Email
  set {
    name  = "global.email.display_name"
    value = "Git"
  }

  set {
    name  = "global.email.from"
    value = "gitlab@kashiuno.com"
  }

  set {
    name  = "global.smtp.enabled"
    value = true
  }

  set {
    name  = "global.smtp.address"
    value = "smtp.yandex.ru"
  }

  set {
    name  = "global.smtp.tls"
    value = true
  }

  set {
    name  = "global.smtp.authentication"
    value = "login"
  }

  set {
    name  = "global.smtp.user_name"
    value = var.gitlab-email
  }

  set {
    name  = "global.smtp.password.secret"
    value = var.gitlab-email-password-secret-name
  }

  set {
    name  = "global.smtp.password.key"
    value = "password"
  }

  set {
    name  = "global.smtp.port"
    value = 465
  }

  set {
    name  = "global.smtp.starttls_auto"
    value = true
  }

  depends_on = [
    minio_user.gitlab-minio-user,
    kubernetes_secret.object-storage-secret,
    postgresql_database.gitlab-database
  ]
}

resource "postgresql_role" "gitlab-user" {
  name     = var.gitlab-db-username
  login    = true
  password = var.gitlab-db-password
}

resource "postgresql_database" "gitlab-database" {
  name  = var.gitlab-database
  owner = var.gitlab-db-username
  depends_on = [
    postgresql_role.gitlab-user
  ]
}

resource "minio_user" "gitlab-minio-user" {
  access_key = var.gitlab-minio-username
  secret_key = var.gitlab-minio-password
  policies   = ["readwrite"]
}