variable "external-ip" {
  type    = string
  default = "178.44.114.168"
}

variable "external-domain" {
  type    = string
  default = "kashiuno.com"
}

variable "ingress-class-name" {
  type    = string
  default = "nginx"
}

variable "nfs-storage-class-name" {
  type    = string
  default = "main-storage"
}