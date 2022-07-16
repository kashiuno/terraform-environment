variable "identity-provider-namespace" {
  type    = string
  default = "identity-provider"
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
            value = "postgres-external-service.database"
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
          path      = "/realms/Bookkeeping"
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

resource "postgresql_role" "keycloak-user" {
  name     = var.identity-provider-db-username
  login    = true
  password = var.identity-provider-db-password
}

resource "postgresql_database" "keycloak-database" {
  name  = var.identity-provider-db-name
  owner = var.identity-provider-db-username
  depends_on = [
    postgresql_role.keycloak-user
  ]
}