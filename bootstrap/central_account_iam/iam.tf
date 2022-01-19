locals {
  cbs_managed_accounts = [
    "028051698106"
  ]
  trusted_role_arns = [
    for account in local.cbs_managed_accounts : "arn:aws:iam::${account}:role/ConfigTerraformAdminExecutionRole"
  ]
}

# Role used by Terraform to manage all satellite accounts
resource "aws_iam_role" "config_terraform_role" {
  name               = "ConfigTerraformAdministratorRole"
  assume_role_policy = data.aws_iam_policy_document.service_principal.json
}

data "aws_iam_policy_document" "service_principal" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = local.trusted_role_arns
    }
  }
}


