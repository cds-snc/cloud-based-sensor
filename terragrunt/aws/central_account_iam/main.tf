locals {
  cbs_admin_role = "ConfigTerraformAdministratorRole"
  cbs_managed_accounts = [
    "028051698106"
  ]
  trusted_role_arns = [
    for account in local.cbs_managed_accounts : "arn:aws:iam::${account}:role/ConfigTerraformAdminExecutionRole"
  ]
}

# Role used by Terraform to manage all satellite accounts
module "gh_oidc_roles" {
  source = "github.com/cds-snc/terraform-modules?ref=v1.0.0//gh_oidc_role"
  roles = [
    {
      name      = local.cbs_admin_role
      repo_name = "cloud-based-sensor"
      claim     = "ref:refs/heads/main"
    }
  ]

  billing_tag_value = var.billing_code
}

data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = local.cbs_admin_role
  policy_arn = data.aws_iam_policy.admin.arn
}

resource "aws_iam_role_policy_attachment" "config_terraform_policy" {
  role       = local.cbs_admin_role
  policy_arn = aws_iam_policy.service_principal.arn
  depends_on = [module.gh_oidc_roles]
}

resource "aws_iam_policy" "service_principal" {
  name   = "cbs-central-assume-role-terraform"
  path   = "/"
  policy = data.aws_iam_policy_document.config_terraform_policy.json
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


