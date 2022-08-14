variable "database-port" {
  type    = number
  default = 30432
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}