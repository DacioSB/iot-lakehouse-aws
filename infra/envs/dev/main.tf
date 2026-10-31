data "aws_caller_identity" "current" {}

locals {
  prefix = "${var.project}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id

  bucket_layers = toset(["bronze", "silver", "gold", "quarantine", "artifacts"])
  db_layers = toset(["bronze", "silver", "gold"])
}

module "bucket" {
  for_each = local.bucket_layers
  source = "../../modules/s3"

  bucket_name = "${local.prefix}-${each.key}-${local.account_id}"
  force_destroy = var.force_destroy
  expiration_days = each.key == "quarantine" ? 30 : null
}

resource "aws_glue_catalog_database" "layer" {
  for_each = local.db_layers
  name         = "${replace(local.prefix, "-", "_")}_${each.key}"
  location_uri = "s3://${module.bucket[each.key].id}"
}