variable "lets-encrypt-email" {
  type      = string
  sensitive = true
}

variable "lets-encrypt-acme-server" {
  type    = string
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

resource "kubernetes_manifest" "lets-encrypt-issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "lets-encrypt-issuer"
    }
    spec = {
      acme = {
        server = var.lets-encrypt-acme-server
        email  = var.lets-encrypt-email
        privateKeySecretRef = {
          name = "letsencrypt"
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