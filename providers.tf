variable "database-host" {
  type = string
}

variable "database-port" {
  type    = number
  default = 30432
}

variable "minio-endpoint" {
  type = string
}

terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.16.0"
    }
    minio = {
      source  = "refaktory/minio"
      version = "0.1.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "postgresql" {
  host     = var.database-host
  port     = var.database-port
  username = var.postgres-admin-username
  password = var.postgres-admin-password
  sslmode  = "disable"
}

provider "minio" {
  endpoint   = var.minio-endpoint
  access_key = var.minio-admin-user
  secret_key = var.minio-admin-pass
  ssl        = false
}