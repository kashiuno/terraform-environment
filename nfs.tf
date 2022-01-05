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

resource "kubernetes_namespace" "nfs-provisioner-namespace" {
  metadata {
    name = var.nfs-provisioner-namespace
  }
}

resource "helm_release" "nfs-provisioner" {
  name      = "nfs-provisioner"
  namespace = var.nfs-provisioner-namespace

  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  chart      = "nfs-subdir-external-provisioner"

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
}

