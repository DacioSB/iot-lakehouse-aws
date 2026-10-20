variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "iot-lakehouse"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "force_destroy" {
  type    = bool
  default = true
}