variable "gitlab-namespace" {
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

variable "gitlab-db-name" {
  type    = string
  default = "gitlab"
}

variable "gitlab-db-capacity" {
  type    = string
  default = "100Gi"
}

variable "gitlab-pg-service-name" {
  type    = string
  default = "gitlab-pg-svc"
}

variable "postgres-pvc-name" {
  type    = string
  default = "postgres-pvc"
}

resource "kubernetes_namespace" "gitlab-namespace" {
  metadata {
    name = var.gitlab-namespace
  }
}

resource "kubernetes_persistent_volume" "gitlab-db-pv" {
  metadata {
    name = "gitlab-db-pv"
  }
  spec {
    capacity = {
      storage = var.gitlab-db-capacity
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = var.local-storage-class-name
    persistent_volume_source {
      local {
        path = "/home/persistenceVolumes/gitlab-pg-data"
      }
    }
    node_affinity {
      required {
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

resource "kubernetes_service" "gitlab-postgres-svc" {
  metadata {
    name = "gitlab-pg-svc"
    labels = {
      app = "gitlab"
      run = "postgres"
    }
    namespace = var.gitlab-namespace
  }
  spec {
    selector = {
      app = "gitlab"
      run = "postgres"
      pod = "true"
    }
    cluster_ip = "None"
    port {
      port        = 5432
      target_port = 5432
    }
  }
}

resource "kubernetes_stateful_set" "gitlab-postgres" {
  metadata {
    name = "gitlab-pg"
    labels = {
      app = "gitlab"
      run = "postgres"
    }
    namespace = var.gitlab-namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "gitlab"
        run = "postgres"
        pod = "true"
      }
    }
    service_name = var.gitlab-pg-service-name
    template {
      metadata {
        name = "gitlab-pg-pod"
        labels = {
          app = "gitlab"
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
            value = var.gitlab-db-password
          }
          env {
            name  = "POSTGRES_USER"
            value = var.gitlab-db-username
          }
          env {
            name  = "POSTGRES_DB"
            value = var.gitlab-db-name
          }
          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = var.postgres-pvc-name
          }
          resources {
            requests = {
              memory = "512Mi"
              cpu    = "500m"
            }
            limits = {
              memory = "1024Mi"
              cpu    = "1"
            }
          }
          liveness_probe {
            exec {
              command = ["/bin/sh", "-c", "exec pg_isready -U \"postgres\" -h 127.0.0.1 -p 5432"]
            }
            failure_threshold    = 6
            initial_delay_seconds = 30
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 5
          }
          readiness_probe {
            exec {
              command = ["/bin/sh", "-c", "exec pg_isready -U \"postgres\" -h 127.0.0.1 -p 5432"]
            }
            failure_threshold    = 6
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
          app = "gitlab"
          run = "postgres"
        }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.local-storage-class-name
        resources {
          requests = {
            storage = var.gitlab-db-capacity
          }
        }
      }
    }
  }
}