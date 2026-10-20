variable "bucket_name" {
  type = string
}

variable "force_destroy" {
  type = bool
  default = false
}

variable "versioning" {
  type = bool
  default = false
}

variable "expiration_days" {
  type = number
  default = null
  description = "Expire all objects after N days. null means never expire."
}