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

variable "redis-password" {
  type      = string
  sensitive = true
}

variable "lets-encrypt-issuer-name-staging" {
  type    = string
  default = "lets-encrypt-issuer-staging"
}

variable "lets-encrypt-secret-name-staging" {
  type    = string
  default = "letsencrypt-staging"
}

variable "lets-encrypt-issuer-name" {
  type    = string
  default = "lets-encrypt-issuer"
}

variable "lets-encrypt-secret-name" {
  type    = string
  default = "letsencrypt"
}