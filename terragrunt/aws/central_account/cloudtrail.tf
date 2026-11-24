#
# CloudTrail trail that logs S3 PutObject data events on the log archive bucket
# so the EventBridge rule (replication -> remote event bus) keeps firing.
#
# Kept separate from Control Tower's aws-controltower-BaselineCloudTrail so
# landing zone updates/resets don't remove it.
#

locals {
  trail_name = "cbs-audit-replication-data-events"
  trail_arn  = "arn:aws:cloudtrail:${var.region}:${var.account_id}:trail/${local.trail_name}"
}

# ---------------------------------------------------------------------------
# Log delivery bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "cloudtrail_logs" {
  # checkov:skip=CKV_AWS_144:cross-region replication not needed for ephemeral data
  # checkov:skip=CKV_AWS_18:access logging is set in aws_s3_bucket_logging; older checkov can't link it
  # checkov:skip=CKV_AWS_19:encryption is set in aws_s3_bucket_server_side_encryption_configuration; older checkov can't link it
  # checkov:skip=CKV_AWS_21:versioning is set in aws_s3_bucket_versioning; older checkov can't link it
  bucket = "${local.trail_name}-cloudtrail-logs"
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "cloudtrail_logs" {
  bucket        = aws_s3_bucket.cloudtrail_logs.id
  target_bucket = module.log_archive_access_bucket.s3_bucket_id
  target_prefix = "${aws_s3_bucket.cloudtrail_logs.id}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail.arn
    }
    bucket_key_enabled = true
  }
}

# ---------------------------------------------------------------------------
# KMS key for the trail's log files and delivery bucket
# ---------------------------------------------------------------------------
resource "aws_kms_key" "cloudtrail" {
  description         = "Encrypt CloudTrail log files for ${local.trail_name}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudtrail_kms.json
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/${local.trail_name}"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

data "aws_iam_policy_document" "cloudtrail_kms" {
  # checkov:skip=CKV_AWS_109: false-positive,`resources = ["*"]` references KMS key policy is attached to
  # checkov:skip=CKV_AWS_111: false-positive,`resources = ["*"]` references KMS key policy is attached to
  # checkov:skip=CKV_AWS_356: false-positive,`resources = ["*"]` references KMS key policy is attached to

  statement {
    sid       = "EnableAccountAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowCloudTrailEncrypt"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${var.account_id}:trail/*"]
    }
  }

  # Required with an S3 Bucket Key when creating or updating a trail with SSE-KMS.
  statement {
    sid       = "AllowCloudTrailDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "AllowCloudTrailDescribeKey"
    effect    = "Allow"
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = local.trail_arn
          }
        }
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${var.account_id}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = local.trail_arn
            "s3:x-amz-acl"  = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Trail: S3 object-level PutObject data events for the log-archive bucket
# ---------------------------------------------------------------------------
resource "aws_cloudtrail" "audit_replication_data_events" {
  # checkov:skip=CKV2_AWS_10:trail only feeds EventBridge; CloudWatch Logs delivery would add ingestion cost with no consumer
  name           = local.trail_name
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id
  kms_key_id     = aws_kms_key.cloudtrail.arn

  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  is_organization_trail         = false
  enable_logging                = true

  advanced_event_selector {
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
    field_selector {
      field  = "eventName"
      equals = ["PutObject"]
    }
    field_selector {
      field       = "resources.ARN"
      starts_with = ["arn:aws:s3:::${var.log_archive_bucket_name}/"]
    }
    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs,
    aws_s3_bucket_public_access_block.cloudtrail_logs,
    aws_kms_key.cloudtrail,
  ]
}