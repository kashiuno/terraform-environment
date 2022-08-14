variable "cert-manager-namespace" {
  type    = string
  default = "cert-manager"
}

resource "helm_release" "cert-manager" {
  name      = "cert-manager"
  namespace = var.cert-manager-namespace

  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.8.2"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = true
  }

  set {
    name  = "prometheus.enabled"
    value = false
  }
}