resource "aws_kms_key" "log_archive_encrypt" {
  description         = "Encrypt objects in the log-archive S3 bucket"
  enable_key_rotation = "true"
  policy              = sensitive(data.aws_iam_policy_document.log_archive_encrypt.json)
}

data "aws_iam_policy_document" "log_archive_encrypt" {
  # checkov:skip=CKV_AWS_109: false-positive,`resources = ["*"]` references KMS key policy is attached to
  # checkov:skip=CKV_AWS_111: false-positive,`resources = ["*"]` references KMS key policy is attached to

  # Allow log-archive account to use the key
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [var.account_id]
    }
  }

  # Allow CBS principal to decrypt using the key
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [var.cbs_principal_arn]
    }
  }

  # Allow satellite accounts to use the key for encryption
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = local.trusted_replicate_role_arns
    }
    principals {
      type        = "AWS"
      identifiers = [var.core_replicate_role_arn]
    }
  }
}
