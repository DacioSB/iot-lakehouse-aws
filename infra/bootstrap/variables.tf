variable "region" {
    type = string
    default = "us-east-1"
}
variable "project" {
    type = string
    default = "iot-lakehouse"
}
variable "budget_limit_usd" {
    type = number
    description = "Monthly cost budget for the AWS account"
}
variable "alert_email" {
  type        = string
  description = "Where budget alerts are sent"
}