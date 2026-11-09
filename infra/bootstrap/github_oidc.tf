variable "github_repo" {
  type        = string
  description = "GitHub repository in owner/name form"
}

variable "github_main_branch" {
  type    = string
  default = "main"
}

locals {
  dev_prefix = "${var.project}-dev"
  glue_db_names = "${replace(var.project, "-", "_")}_dev_*"
  glue_arn_base = "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}"
}

resource "aws_iam_openid_connect_provider" "github" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = ["sts.amazonaws.com"]
}

# ---------- Trust policies ----------
data "aws_iam_policy_document" "plan_trust" {
    statement {
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type = "Federated"
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
  name = "${var.project}-gh-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json
}

resource "aws_iam_policy_attachment" "gh_plan_readonly" {
  name       = aws_iam_role.gh_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}