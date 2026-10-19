terraform {
  backend "s3" {
    bucket = "iot-lakehouse-tfstate-550172992026-us-east-1"
    key = "bootstrap/terraform.tfstate"
    encrypt = true
    use_lockfile = true
  }
}