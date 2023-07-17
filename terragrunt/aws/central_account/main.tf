locals {
  cbs_admin_role       = "ConfigTerraformAdministratorRole"
  cbs_managed_accounts = var.satellite_account_ids
  trusted_role_arns = [
    for account in local.cbs_managed_accounts : "arn:aws:iam::${account}:role/ConfigTerraformAdminExecutionRole"
  ]
}

# Role used by Terraform to manage all satellite accounts
module "gh_oidc_roles" {
  source = "github.com/cds-snc/terraform-modules//gh_oidc_role?ref=v3.0.20"
  roles = [
    {
      name      = local.cbs_admin_role
      repo_name = "cloud-based-sensor"
      claim     = "*"
    }
  ]
  oidc_exists       = true
  assume_policy     = sensitive(data.aws_iam_policy_document.service_principal.json)
  billing_tag_value = var.billing_tag_value
}

data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = local.cbs_admin_role
  policy_arn = data.aws_iam_policy.admin.arn
  depends_on = [module.gh_oidc_roles]
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
