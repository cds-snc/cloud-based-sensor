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
      identifiers = ["arn:aws:iam::652919170451:root"]
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
    resources = ["arn:aws:dynamodb:${var.region}:${var.account_id}:table/tfstate-lock"]
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
