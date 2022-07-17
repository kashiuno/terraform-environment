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

resource "kubernetes_namespace" "gitlab-namespace" {
  metadata {
    name = var.gitlab-namespace
  }
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