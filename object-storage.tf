variable "object-storage-namespace" {
  type    = string
  default = "object-storage"
}

variable "minio-service-name" {
  type    = string
  default = "minio-svc"
}

variable "minio-admin-user" {
  type      = string
  sensitive = true
}

variable "minio-admin-pass" {
  type      = string
  sensitive = true
}

variable "minio-pvc-name" {
  type    = string
  default = "minio-pvc"
}

variable "minio-capacity" {
  type    = string
  default = "50Gi"
}

resource "kubernetes_namespace" "object-storage-namespace" {
  metadata {
    name = var.object-storage-namespace
  }
}

resource "kubernetes_service" "minio-svc" {
  metadata {
    name = var.minio-service-name
    labels = {
      app = "object-storage"
      run = "minio"
    }
    namespace = var.object-storage-namespace
  }
  spec {
    selector = {
      app = "object-storage"
      run = "minio"
      pod = "true"
    }
    type = "ClusterIP"
    port {
      port        = 9000
      target_port = 9000
    }
  }
}

resource "kubernetes_stateful_set" "minio" {
  metadata {
    name = "minio-stateful-set"
    labels = {
      app = "object-storage"
      run = "minio"
    }
    namespace = var.object-storage-namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "object-storage"
        run = "minio"
        pod = "true"
      }
    }
    service_name = var.minio-service-name
    template {
      metadata {
        name = "minio-pod"
        labels = {
          app = "object-storage"
          run = "minio"
          pod = "true"
        }
      }
      spec {
        container {
          name  = "minio"
          image = "quay.io/minio/minio:RELEASE.2022-07-08T00-05-23Z.fips"
          command = ["/bin/bash", "-c"]
          args = [ "minio server /data " ]
          env {
            name  = "MINIO_ROOT_USER"
            value = var.minio-admin-user
          }
          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = var.minio-admin-pass
          }
          volume_mount {
            mount_path = "/data"
            name       = var.minio-pvc-name
          }
          resources {
            requests = {
              memory = "128Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            http_get {
              path = "/minio/health/live"
              port = 9000
            }
            failure_threshold     = 6
            initial_delay_seconds = 30
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path = "/minio/health/live"
              port = 9000
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
        name = var.minio-pvc-name
        labels = {
          app = "object-storage"
          run = "minio"
        }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.nfs-storage-class-name
        resources {
          requests = {
            storage = var.minio-capacity
          }
        }
      }
    }
  }
}