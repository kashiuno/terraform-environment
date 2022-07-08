variable "identity-provider-namespace" {
  type    = string
  default = "identity-provider"
}

variable "identity-provider-pg-service-name" {
  type    = string
  default = "identity-provider-pg-svc"
}

variable "identity-provider-keycloak-service-name" {
  type    = string
  default = "identity-provider-keycloak-svc"
}

variable "identity-provider-db-password" {
  type      = string
  sensitive = true
}

variable "identity-provider-db-username" {
  type      = string
  sensitive = true
}

variable "identity-provider-db-name" {
  type    = string
  default = "identity-provider"
}

variable "identity-provider-db-capacity" {
  type    = string
  default = "20Gi"
}

variable "identity-provider-postgres-pvc-name" {
  type    = string
  default = "identity-provider-pvc"
}

variable "identity-provider-admin-password" {
  type      = string
  sensitive = true
}

variable "identity-provider-admin-login" {
  type      = string
  sensitive = true
}

variable "identity-provider-host" {
  type    = string
  default = "auth.kashiuno.com"
}

resource "kubernetes_namespace" "identity-provider-namespace" {
  metadata {
    name = var.identity-provider-namespace
  }
}

resource "kubernetes_service" "identity-provider-postgres-svc" {
  metadata {
    name = "identity-provider-pg-svc"
    labels = {
      app = "identity-provider"
      run = "postgres"
    }
    namespace = var.identity-provider-namespace
  }
  spec {
    selector = {
      app = "identity-provider"
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

resource "kubernetes_stateful_set" "identity-provider-postgres" {
  metadata {
    name = "identity-provider-pg"
    labels = {
      app = "identity-provider"
      run = "postgres"
    }
    namespace = var.identity-provider-namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "identity-provider"
        run = "postgres"
        pod = "true"
      }
    }
    service_name = var.identity-provider-pg-service-name
    template {
      metadata {
        name = "identity-provider-pg-pod"
        labels = {
          app = "identity-provider"
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
            value = var.identity-provider-db-password
          }
          env {
            name  = "POSTGRES_USER"
            value = var.identity-provider-db-username
          }
          env {
            name  = "POSTGRES_DB"
            value = var.identity-provider-db-name
          }
          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = var.identity-provider-postgres-pvc-name
          }
          resources {
            requests = {
              memory = "256Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "250m"
            }
          }
          liveness_probe {
            exec {
              command = ["/bin/sh", "-c", "exec pg_isready -U \"postgres\" -h 127.0.0.1 -p 5432"]
            }
            failure_threshold     = 6
            initial_delay_seconds = 30
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 5
          }
          readiness_probe {
            exec {
              command = ["/bin/sh", "-c", "exec pg_isready -U \"postgres\" -h 127.0.0.1 -p 5432"]
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
        name = var.identity-provider-postgres-pvc-name
        labels = {
          app = "identity-provider"
          run = "postgres"
        }
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.nfs-storage-class-name
        resources {
          requests = {
            storage = var.identity-provider-db-capacity
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "identity-provider-keycloak-svc" {
  metadata {
    name = var.identity-provider-keycloak-service-name
    labels = {
      app = "identity-provider"
      run = "keycloak"
    }
    namespace = var.identity-provider-namespace
  }
  spec {
    selector = {
      app = "identity-provider"
      run = "keycloak"
      pod = "true"
    }
    cluster_ip = "None"
    port {
      port        = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_deployment" "identity-provider" {
  metadata {
    name = "identity-provider"
    labels = {
      app = "identity-provider"
      run = "keycloak"
    }
    namespace = var.identity-provider-namespace
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "identity-provider"
        run = "keycloak"
        pod = "true"
      }
    }
    template {
      metadata {
        name = "identity-provider-pod"
        labels = {
          app = "identity-provider"
          run = "keycloak"
          pod = "true"
        }
      }
      spec {
        container {
          name  = "keycloak"
          image = "quay.io/keycloak/keycloak:18.0.1"
          args  = ["start-dev"]

          env {
            name  = "KEYCLOAK_ADMIN"
            value = var.identity-provider-admin-login
          }

          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = var.identity-provider-admin-password
          }

          env {
            name  = "KC_DB_URL_HOST"
            value = var.identity-provider-pg-service-name
          }

          env {
            name  = "KC_DB"
            value = "postgres"
          }

          env {
            name  = "KC_DB_PASSWORD"
            value = var.identity-provider-db-password
          }

          env {
            name  = "KC_DB_USERNAME"
            value = var.identity-provider-db-username
          }

          env {
            name  = "KC_DB_URL_DATABASE"
            value = var.identity-provider-db-name
          }

          env {
            name  = "KC_PROXY"
            value = "edge"
          }

          readiness_probe {
            http_get {
              path = "/realms/master"
              port = "8080"
            }
          }

          port {
            name           = "http"
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "identity-provider-ingress" {
  metadata {
    name = "identity-provider-ingress"
    labels = {
      app = "identity-provider"
      run = "keycloak"
    }
    annotations = {
      "cert-manager.io/cluster-issuer"              = "lets-encrypt-issuer"
      "acme.cert-manager.io/http01-edit-in-place"   = "true"
      "cert-manager.io/issue-temporary-certificate" = "true"
    }
    namespace = var.identity-provider-namespace
  }

  spec {
    ingress_class_name = var.ingress-class-name

    tls {
      hosts = [
        var.identity-provider-host
      ]
      secret_name = "letsencrypt"
    }
    rule {
      host = var.identity-provider-host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = var.identity-provider-keycloak-service-name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}