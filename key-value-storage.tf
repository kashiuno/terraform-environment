variable "key-value-storage-namespace" {
  type    = string
  default = "key-value"
}

variable "redis-capacity" {
  type    = string
  default = "30Gi"
}

variable "redis-service-name" {
  type    = string
  default = "redis-svc"
}

variable "redis-pvc-name" {
  type    = string
  default = "redis-pvc"
}

variable "redis-password" {
  type      = string
  sensitive = true
}

resource "kubernetes_namespace" "key-value-storage-namespace" {
  metadata {
    name = var.key-value-storage-namespace
  }
}

resource "kubernetes_service" "redis-svc" {
  metadata {
    name = var.redis-service-name
    labels = {
      app = "key-value-storage"
      run = "redis"
    }
    namespace = var.key-value-storage-namespace
  }
  spec {
    selector = {
      app = "key-value-storage"
      run = "redis"
      pod = "true"
    }
    cluster_ip = "None"
    port {
      port        = 6379
      target_port = 6379
    }
  }
  depends_on = [
    kubernetes_namespace.key-value-storage-namespace
  ]
}

resource "kubernetes_stateful_set" "redis" {
  metadata {
    name = "redis"
    labels = {
      app = "key-value-storage"
      run = "redis"
    }
    namespace = var.key-value-storage-namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "key-value-storage"
        run = "redis"
        pod = "true"
      }
    }
    service_name = var.redis-service-name
    template {
      metadata {
        name = "key-value-storage"
        labels = {
          app = "key-value-storage"
          run = "redis"
          pod = "true"
        }
      }
      spec {
        container {
          name    = "redis"
          image   = "redis:6.2.7-alpine"
          command = ["/usr/local/bin/redis-server", "--requirepass", var.redis-password]
          volume_mount {
            mount_path = "/data"
            name       = var.redis-pvc-name
          }
          resources {
            requests = {
              memory = "4Gi"
              cpu    = "250m"
            }
            limits = {
              memory = "8Gi"
              cpu    = "500m"
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
          app = "key-value-storage"
          run = "redis"
        }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.nfs-storage-class-name
        resources {
          requests = {
            storage = var.redis-capacity
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_namespace.key-value-storage-namespace
  ]
}