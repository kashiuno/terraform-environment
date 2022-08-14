variable "lets-encrypt-email" {
  type      = string
  sensitive = true
}

variable "lets-encrypt-acme-server" {
  type    = string
  default = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "lets-encrypt-acme-server-staging" {
  type    = string
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "lets-encrypt-issuer-name-staging" {
  type    = string
  default = "lets-encrypt-issuer-staging"
}

variable "lets-encrypt-issuer-name" {
  type    = string
  default = "lets-encrypt-issuer"
}

variable "lets-encrypt-secret-name" {
  type    = string
  default = "letsencrypt"
}

variable "lets-encrypt-secret-name-staging" {
  type    = string
  default = "letsencrypt-staging"
}

resource "kubernetes_manifest" "lets-encrypt-issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.lets-encrypt-issuer-name
    }
    spec = {
      acme = {
        server = var.lets-encrypt-acme-server
        email  = var.lets-encrypt-email
        privateKeySecretRef = {
          name = var.lets-encrypt-secret-name
        }

        solvers = [
          {
            http01 = {
              ingress = {
                class       = var.ingress-class-name
                serviceType = "ClusterIP"
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "lets-encrypt-issuer-staging" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.lets-encrypt-issuer-name-staging
    }
    spec = {
      acme = {
        server = var.lets-encrypt-acme-server-staging
        email  = var.lets-encrypt-email
        privateKeySecretRef = {
          name = var.lets-encrypt-secret-name-staging
        }

        solvers = [
          {
            http01 = {
              ingress = {
                class       = var.ingress-class-name
                serviceType = "ClusterIP"
              }
            }
          }
        ]
      }
    }
  }
}