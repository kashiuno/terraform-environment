variable "gitlab-namespace" {
  type    = string
  default = "gitlab"
}

variable "gitlab-redis-capacity" {
  type    = string
  default = "8Gi"
}

variable "gitlab-redis-service-name" {
  type    = string
  default = "gitlab-redis-svc"
}

variable "redis-pvc-name" {
  type    = string
  default = "redis-pvc"
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

resource "kubernetes_service" "gitlab-redis-svc" {
  metadata {
    name = "gitlab-redis-svc"
    labels = {
      app = "gitlab"
      run = "redis"
    }
    namespace = var.gitlab-namespace
  }
  spec {
    selector = {
      app = "gitlab"
      run = "redis"
      pod = "true"
    }
    cluster_ip = "None"
    port {
      port        = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_stateful_set" "gitlab-redis" {
  metadata {
    name = "gitlab-redis"
    labels = {
      app = "gitlab"
      run = "redis"
    }
    namespace = var.gitlab-namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "gitlab"
        run = "redis"
        pod = "true"
      }
    }
    service_name = var.gitlab-redis-service-name
    template {
      metadata {
        name = "gitlab-redis-pod"
        labels = {
          app = "gitlab"
          run = "redis"
          pod = "true"
        }
      }
      spec {
        container {
          name  = "redis"
          image = "redis:6.2.6"
          volume_mount {
            mount_path = "/data"
            name       = var.redis-pvc-name
          }
          resources {
            requests = {
              memory = "4Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "8Gi"
              cpu    = "1"
            }
          }
          liveness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            failure_threshold     = 6
            initial_delay_seconds = 30
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 5
          }
          readiness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            failure_threshold     = 6
            initial_delay_seconds = 5
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 5
          }
        }
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "isStorage"
                  operator = "In"
                  values   = ["true"]
                }
              }
            }
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = var.redis-pvc-name
        labels = {
          app = "gitlab"
          run = "redis"
        }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.nfs-storage-class-name
        resources {
          requests = {
            storage = var.gitlab-redis-capacity
          }
        }
      }
    }
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