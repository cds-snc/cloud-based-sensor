locals {
  trusted_replicate_role_arns = [
    for account_id in var.satellite_account_ids : "arn:aws:iam::${account_id}:role/${var.satellite_s3_replicate_role_name}"
  ]
}

#
# Log archive bucket and access logging
#
module "log_archive_bucket" {
  source            = "github.com/cds-snc/terraform-modules?ref=v1.0.4//S3"
  bucket_name       = var.log_archive_bucket_name
  billing_tag_value = var.billing_tag_value
  kms_key_arn       = aws_kms_key.log_archive_encrypt.arn

  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = module.log_archive_access_bucket.s3_bucket_id
  }

  lifecycle_rule = [
    {
      id      = "delete-old-objects"
      enabled = true
      expiration = {
        days = 14
      }
    }
  ]
}

module "log_archive_access_bucket" {
  source            = "github.com/cds-snc/terraform-modules?ref=v1.0.4//S3_log_bucket"
  bucket_name       = "${var.log_archive_bucket_name}-access"
  billing_tag_value = var.billing_tag_value
  force_destroy     = true
}

#
# Bucket policy that allows satellite buckets to
# replicate content
#
resource "aws_s3_bucket_policy" "log_archive_bucket" {
  bucket = module.log_archive_bucket.s3_bucket_id
  policy = sensitive(data.aws_iam_policy_document.log_archive_bucket.json)
}

data "aws_iam_policy_document" "log_archive_bucket" {
  statement {
    principals {
      type        = "AWS"
      identifiers = local.trusted_replicate_role_arns
    }
    actions = [
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateObject",
      "s3:ReplicateDelete"
    ]
    resources = [
      "${module.log_archive_bucket.s3_bucket_arn}/*",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = local.trusted_replicate_role_arns
    }
    actions = [
      "s3:List*",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [
      module.log_archive_bucket.s3_bucket_arn
    ]
  }
}
