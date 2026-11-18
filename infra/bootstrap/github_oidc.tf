variable "github_repo" {
  type        = string
  description = "GitHub repository in owner/name form"
}

variable "github_main_branch" {
  type    = string
  default = "main"
}

locals {
  dev_prefix    = "${var.project}-dev"
  glue_db_names = "${replace(var.project, "-", "_")}_dev_*"
  glue_arn_base = "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# ---------- Trust policies ----------
data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:pull_request"]
    }
  }
}

data "aws_iam_policy_document" "apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/${var.github_main_branch}"]
    }
  }
}

# ---------- Plan role (pull requests, read-only) ----------
resource "aws_iam_role" "gh_plan" {
  name               = "${var.project}-gh-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json
}

resource "aws_iam_role_policy_attachment" "gh_plan_readonly" {
  role       = aws_iam_role.gh_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]
  }
  statement {
    sid       = "ReadState"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/envs/dev/*"]
  }

  statement {
    sid       = "LockfileOnly"
    actions   = ["s3:PutObject", "s3:DeleteObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/envs/dev/terraform.tfstate.tflock"]
  }
}

resource "aws_iam_role_policy" "gh_plan_state" {
  name   = "tfstate-access"
  role   = aws_iam_role.gh_plan.id
  policy = data.aws_iam_policy_document.plan_state.json
}

resource "aws_iam_role" "gh_apply" {
  name               = "${var.project}-gh-apply"
  assume_role_policy = data.aws_iam_policy_document.apply_trust.json
}

data "aws_iam_policy_document" "apply" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]
  }
  statement {
    sid       = "ReadWriteDevState"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/envs/dev/*"]
  }
  statement {
    sid     = "LakeBuckets"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.dev_prefix}-*",
      "arn:aws:s3:::${local.dev_prefix}-*/*",
    ]
  }
  statement {
    sid     = "GlueCatalog"
    actions = ["glue:*"]
    resources = [
      "${local.glue_arn_base}:catalog",
      "${local.glue_arn_base}:database/${local.glue_db_names}",
      "${local.glue_arn_base}:table/${local.glue_db_names}/*",
    ]
  }
}

resource "aws_iam_role_policy" "gh_apply" {
  name   = "dev-apply"
  role   = aws_iam_role.gh_apply.id
  policy = data.aws_iam_policy_document.apply.json
}

output "gh_plan_role_arn" {
  value = aws_iam_role.gh_plan.arn
}

output "gh_apply_role_arn" {
  value = aws_iam_role.gh_apply.arn
}