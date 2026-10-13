data "aws_caller_identity" "current" {}

locals {
    state_bucket = "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "tfstate" {
    bucket = local.state_bucket
    lifecycle {
      prevent_destroy = true
    }
}