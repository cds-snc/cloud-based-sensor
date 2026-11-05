data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# Assume role policy for the central cbs account to manage config rules via Terraform
resource "aws_iam_role" "config_terraform_role" {
  name               = "ConfigTerraformAdminExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.config_execution_role.json
}

data "aws_iam_policy_document" "config_execution_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.central_account_id}:role/ConfigTerraformAdministratorRole"]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values = [
        "CBSGitHubActions",
      ]
    }
  }
}

data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.config_terraform_role.name
  policy_arn = data.aws_iam_policy.admin.arn
}

# Read-only role assumed by the central account plan workflows
resource "aws_iam_role" "config_terraform_readonly_role" {
  name               = "ConfigTerraformReadOnlyExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.config_readonly_execution_role.json
}

data "aws_iam_policy_document" "config_readonly_execution_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.central_account_id}:role/ConfigTerraformReadOnlyRole"]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values   = ["CBSGitHubActions"]
    }
  }
}

data "aws_iam_policy" "readonly" {
  name = "ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.config_terraform_readonly_role.name
  policy_arn = data.aws_iam_policy.readonly.arn
}

# State locking requires write access to the lock table only
data "aws_iam_policy_document" "readonly_state_lock" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:ca-central-1:${local.account_id}:table/tfstate-lock"]
  }
}

resource "aws_iam_role_policy" "readonly_state_lock" {
  name   = "TerraformStateLock"
  role   = aws_iam_role.config_terraform_readonly_role.name
  policy = data.aws_iam_policy_document.readonly_state_lock.json
}

#
# Role used by satellite account S3 buckets to replicate objects to
# the CbsCentral log archive S3 bucket.
#
resource "aws_iam_role" "s3_replicate" {
  name               = "CbsSatelliteReplicateToLogArchive"
  assume_role_policy = data.aws_iam_policy_document.s3_replicate_assume.json
}

data "aws_iam_policy_document" "s3_replicate_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}
