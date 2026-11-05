locals {
  cbs_admin_role    = "ConfigTerraformAdministratorRole"
  cbs_readonly_role = "ConfigTerraformReadOnlyRole"
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

# Read-only role used by the plan workflows (pull_request and workflow_dispatch)
module "gh_oidc_roles_readonly" {
  source = "github.com/cds-snc/terraform-modules//gh_oidc_role?ref=v3.0.20"
  roles = [
    {
      name      = local.cbs_readonly_role
      repo_name = "cloud-based-sensor"
      claim     = "*"
    }
  ]
  oidc_exists       = true
  billing_tag_value = var.billing_tag_value
}

data "aws_iam_policy" "readonly" {
  name = "ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "readonly" {
  role       = local.cbs_readonly_role
  policy_arn = data.aws_iam_policy.readonly.arn
  depends_on = [module.gh_oidc_roles_readonly]
}

# State locking requires write access to the lock table only
data "aws_iam_policy_document" "readonly_state_lock" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:${var.region}:${var.account_id}:table/tfstate-lock"]
  }
}

resource "aws_iam_role_policy" "readonly_state_lock" {
  name   = "TerraformStateLock"
  role   = local.cbs_readonly_role
  policy = data.aws_iam_policy_document.readonly_state_lock.json

  depends_on = [module.gh_oidc_roles_readonly]
}
