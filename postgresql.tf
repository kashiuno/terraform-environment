variable "database-namespace" {
  type    = string
  default = "database"
}

variable "postgres-svc-name" {
  type    = string
  default = "postgres-svc"
}

variable "postgres-admin-password" {
  type      = string
  sensitive = true
}

variable "postgres-admin-username" {
  type      = string
  sensitive = true
}

variable "postgres-pvc-name" {
  type    = string
  default = "postgres-pvc"
}

variable "postgres-capacity" {
  type    = string
  default = "100Gi"
}

resource "kubernetes_namespace" "database-namespace" {
  metadata {
    name = var.database-namespace
  }
}

resource "kubernetes_service" "postgres-svc" {
  metadata {
    name = "postgres-external-service"
    labels = {
      app      = "database"
      run      = "postgres"
      external = "true"
    }
    namespace = var.database-namespace
  }
  spec {
    selector = {
      app = "database"
      run = "postgres"
      pod = "true"
    }
    type = "NodePort"
    port {
      port        = 5432
      target_port = 5432
      node_port   = var.database-port
    }
  }
}

resource "kubernetes_stateful_set" "postgres-stateful-set" {
  metadata {
    name = "postgres-stateful-set"
    labels = {
      app = "database"
      run = "postgres"
    }
    namespace = var.database-namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "database"
        run = "postgres"
        pod = "true"
      }
    }
    service_name = var.postgres-svc-name
    template {
      metadata {
        name = "postgres-pod"
        labels = {
          app = "database"
          run = "postgres"
          pod = "true"
        }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:13"
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.postgres-admin-password
          }
          env {
            name  = "POSTGRES_USER"
            value = var.postgres-admin-username
          }
          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = var.postgres-pvc-name
          }
          resources {
            requests = {
              memory = "256Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }
          liveness_probe {
            exec {
              command = ["/bin/sh", "-c", format("exec pg_isready -U \"%s\" -h 127.0.0.1 -p 5432", var.postgres-admin-username)]
            }
            failure_threshold     = 6
            initial_delay_seconds = 30
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 5
          }
          readiness_probe {
            exec {
              command = ["/bin/sh", "-c", format("exec pg_isready -U \"%s\" -h 127.0.0.1 -p 5432", var.postgres-admin-username)]
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
        name = var.postgres-pvc-name
        labels = {
          app = "database"
          run = "postgres"
        }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.nfs-storage-class-name
        resources {
          requests = {
            storage = var.postgres-capacity
          }
        }
      }
    }
  }
}