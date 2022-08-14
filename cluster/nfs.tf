variable "nfs-provisioner-namespace" {
  type    = string
  default = "nfs-provisioner"
}

variable "nfs-host" {
  type = string
}

variable "nfs-path" {
  type    = string
  default = "/home/data"
}

variable "nfs-storage-class-name" {
  type    = string
  default = "main-storage"
}

resource "helm_release" "nfs-provisioner" {
  name      = "nfs-provisioner"
  namespace = var.nfs-provisioner-namespace

  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  chart      = "nfs-subdir-external-provisioner"

  create_namespace = true

  set {
    name  = "nfs.server"
    value = var.nfs-host
  }

  set {
    name  = "nfs.path"
    value = var.nfs-path
  }

  set {
    name  = "storageClass.name"
    value = var.nfs-storage-class-name
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
    value = "storage"
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
    value = "In"
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
    value = ""
  }

  set {
    name  = "tolerations[0].key"
    value = "storage"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }

  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }
}

