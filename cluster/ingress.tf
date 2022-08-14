variable "ingress-namespace" {
  type    = string
  default = "ingress"
}

variable "ingress-class-name" {
  type    = string
  default = "nginx"
}

resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress-controller"
  namespace = var.ingress-namespace

  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"

  create_namespace = true

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

  set {
    name  = "controller.config.entries.proxy-buffers"
    value = "8 16k"
  }

  set {
    name  = "controller.config.entries.proxy-buffer-size"
    value = "16k"
  }

  set {
    name  = "controller.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
    value = "external"
  }

  set {
    name  = "controller.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
    value = "In"
  }

  set {
    name  = "controller.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
    value = ""
  }
}