variable "database-host" {
  type = string
}

variable "database-port" {
  type    = number
  default = 30432
}

terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.16.0"
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