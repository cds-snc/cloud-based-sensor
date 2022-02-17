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
        days = 90
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
  policy = data.aws_iam_policy_document.combined.json
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.cloudtrail_write_logs.json,
    sensitive(data.aws_iam_policy_document.log_archive_bucket.json)
  ]
}

data "aws_iam_policy_document" "log_archive_bucket" {
  statement {
    principals {
      type        = "AWS"
      identifiers = local.trusted_replicate_role_arns
    }
    principals {
      type        = "AWS"
      identifiers = var.core_replicate_role_arn
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
    principals {
      type        = "AWS"
      identifiers = var.core_replicate_role_arn
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

data "aws_iam_policy_document" "cloudtrail_write_logs" {

  statement {
    sid    = "CloudTrailGetAcl"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      module.log_archive_bucket.s3_bucket_arn
    ]
  }

  statement {
    sid    = "CloudTrailPutObject"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.log_archive_bucket.s3_bucket_arn}/cloudtrail_logs/AWSLogs/${var.account_id}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region}:${var.account_id}:trail/CbsSatelliteTrail"]
    }
  }
}

#
# Notify the CBS transport Lambda when a new object is created
#
data "aws_lambda_function" "cbs_transport_lambda" {
  function_name = var.cbs_transport_lambda_name
}

resource "aws_s3_bucket_notification" "cbs_transport_lambda" {
  bucket = module.log_archive_bucket.s3_bucket_id

  lambda_function {
    id                  = "CbsEvent"
    lambda_function_arn = data.aws_lambda_function.cbs_transport_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}
