locals {
  calculated_replicate_role_arns = [
    for account_id in var.satellite_account_ids : "arn:aws:iam::${account_id}:role/${var.satellite_s3_replicate_role_name}"
  ]
  trusted_replicate_role_arns = concat(
    local.calculated_replicate_role_arns,
    ["arn:aws:iam::274536870005:role/service-role/s3crr_role_for_aws-controltower-logs-274536870005-ca-central-1"]
  )
}

#
# Log archive bucket and access logging
#
module "log_archive_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=v8.0.0"
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
        days = 90
      }
    }
  ]
}

module "log_archive_access_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3_log_bucket?ref=v8.0.0"
  bucket_name       = "${var.log_archive_bucket_name}-access"
  billing_tag_value = var.billing_tag_value
  versioning_status = "Disabled"
  force_destroy     = true
}

#
# Bucket policy that allows satellite buckets to
# replicate content
#
resource "aws_s3_bucket_policy" "log_archive_bucket" {
  bucket = module.log_archive_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.combined.json
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    sensitive(data.aws_iam_policy_document.log_archive_bucket.json)
  ]
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

#
# Bucket Policy that allows the specified principal to get objects
#

resource "aws_s3_bucket_policy" "log-archive-bucket-get-objects" {
  bucket = module.log_archive_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.log-archive--bucket-get-objects.json
}

data "aws_iam_policy_document" "log-archive-bucket-get-objects" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [sensitive(var.cbs_principal_role_arn)]
    }
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${module.log_archive_bucket.s3_bucket_arn}",
      "${module.log_archive_bucket.s3_bucket_arn}/*",
    ]
  }
}

#
# Publish a notification to the SNS topic when objects are created
#
resource "aws_s3_bucket_notification" "cbs_transport_lambda" {
  bucket = module.log_archive_bucket.s3_bucket_id

  topic {
    id        = "CbsEvent"
    topic_arn = aws_sns_topic.log_archive.arn
    events    = ["s3:ObjectCreated:*"]
  }
}
