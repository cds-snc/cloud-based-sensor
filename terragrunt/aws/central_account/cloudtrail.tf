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
  bucket = "${local.trail_name}-cloudtrail-logs"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
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
  name           = local.trail_name
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id

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
  ]
}