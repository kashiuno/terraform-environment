variable "ingress-namespace" {
  type    = string
  default = "ingress"
}

variable "ingress-class-name" {
  type    = string
  default = "nginx"
}

resource "kubernetes_namespace" "ingress" {
  metadata {
    name = var.ingress-namespace
  }
}

resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress-controller"
  namespace = var.ingress-namespace

  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.setAsDefaultIngress"
    value = "true"
  }

  set {
    name  = "controller.service.httpPort.nodePort"
    value = "30080"
  }

  set {
    name  = "controller.service.httpsPort.nodePort"
    value = "30443"
  }

  set {
    name  = "controller.ingressClass"
    value = var.ingress-class-name
  }
}