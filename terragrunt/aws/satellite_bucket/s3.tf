#
# Satellite bucket and access logging
#
module "satellite_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=v9.2.7"
  bucket_name       = var.satellite_bucket_name
  billing_tag_value = var.billing_tag_value

  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = module.satellite_access_bucket.s3_bucket_id
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

  replication_configuration = {
    role = data.aws_iam_role.s3_replicate.arn

    rules = [
      {
        id       = "cbs-log-archive"
        priority = 100

        destination = {
          bucket             = local.log_archive_bucket_arn
          account_id         = var.log_archive_account_id
          replica_kms_key_id = var.log_archive_kms_key_arn
          access_control_translation = {
            owner = "Destination"
          }
        }

        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }
      }
    ]
  }
}

module "satellite_access_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3_log_bucket?ref=v9.2.7"
  bucket_name       = "${var.satellite_bucket_name}-access"
  billing_tag_value = var.billing_tag_value
  versioning_status = "Disabled"
  force_destroy     = true

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

resource "aws_s3_bucket_ownership_controls" "satellite_bucket" {
  bucket = module.satellite_bucket.s3_bucket_id

  rule {
    object_ownership = "ObjectWriter"
  }
}

#
# Bucket policy allowing AWS services to write
# to the satellite bucket
#
resource "aws_s3_bucket_policy" "satellite_bucket" {
  bucket = module.satellite_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.combined.json
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.cloudtrail_write_logs.json,
    data.aws_iam_policy_document.log_delivery_write_logs.json,
    data.aws_iam_policy_document.load_balancer_write_logs.json,
    data.aws_iam_policy_document.deny_insecure_transport.json
  ]
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
      module.satellite_bucket.s3_bucket_arn
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
      "${module.satellite_bucket.s3_bucket_arn}/cloudtrail_logs/AWSLogs/${var.account_id}/*"
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

data "aws_iam_policy_document" "log_delivery_write_logs" {

  statement {
    sid    = "LogDeliveryGetAcl"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      module.satellite_bucket.s3_bucket_arn
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${var.region}:${var.account_id}:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }

  statement {
    sid    = "LogDeliveryPutObject"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.satellite_bucket.s3_bucket_arn}/*/AWSLogs/${var.account_id}/*"
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${var.region}:${var.account_id}:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

data "aws_elb_service_account" "main" {}
data "aws_iam_policy_document" "load_balancer_write_logs" {

  statement {
    sid    = "ELBLogDeliveryPutObject"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${module.satellite_bucket.s3_bucket_arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "deny_insecure_transport" {

  statement {
    sid    = "denyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      module.satellite_bucket.s3_bucket_arn,
      "${module.satellite_bucket.s3_bucket_arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}
