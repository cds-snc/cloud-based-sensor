provider "aws" {
  region              = var.REGION
  allowed_account_ids = [var.ACCOUNT_ID]
}
