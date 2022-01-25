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
      identifiers = ["${var.central_account_id}"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "config_terraform_policy" {
  role       = aws_iam_role.config_terraform_role.name
  policy_arn = aws_iam_policy.config_terraform_policy.arn
}

resource "aws_iam_policy" "config_terraform_policy" {
  name   = "cbs-config-terraform"
  path   = "/"
  policy = data.aws_iam_policy_document.config_terraform_policy.json
}

data "aws_iam_policy_document" "config_terraform_policy" {
  statement {

    effect = "Allow"

    actions = [
      "dynamodb:*",
    ]
    resources = ["arn:aws:dynamodb:${var.region}:${local.account_id}:table/tfstate-lock"]
  }

  statement {

    effect = "Allow"

    actions = [
      "config:*",
      "iam:*",
      "s3:*",
    ]
    resources = ["*"]
  }
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
