variable "local-storage-class-name" {
  type    = string
  default = "local"
}

resource "kubernetes_storage_class" "local-pv" {
  metadata {
    name = var.local-storage-class-name
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = true
    }
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}