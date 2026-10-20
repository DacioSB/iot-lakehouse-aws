data "aws_caller_identity" "current" {}

locals {
  prefix = "${var.project}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id

  bucket_layers = toset(["bronze", "silver", "gold", "quarantine", "artifacts"])
  db_layers = toset(["bronze", "silver", "gold"])
}