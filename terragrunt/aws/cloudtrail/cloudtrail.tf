locals {
  satellite_bucket_arn = "arn:aws:s3:::${var.satellite_bucket_name}"
  trail_prefix         = "cloudtrail_logs"
  trail_arn            = "arn:aws:cloudtrail:${var.region}:${var.account_id}:trail/CbsSatelliteTrail"
}

#
# CloudTrail: deliver all events from all regions
# to the S3 satellite bucket
#
resource "aws_cloudtrail" "satellite_trail" {
  name                          = "CbsSatelliteTrail"
  s3_bucket_name                = var.satellite_bucket_name
  s3_key_prefix                 = local.trail_prefix
  include_global_service_events = true
  is_multi_region_trail         = true

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }

  depends_on = [
    aws_s3_bucket_policy.satellite_trail
  ]
}

#
# Bucket policy allowing CloudTrail to write logs
# to the satellite bucket
#
resource "aws_s3_bucket_policy" "satellite_trail" {
  bucket = var.satellite_bucket_name
  policy = data.aws_iam_policy_document.satellite_trail.json
}

data "aws_iam_policy_document" "satellite_trail" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      local.satellite_bucket_arn
    ]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${local.satellite_bucket_arn}/${local.trail_prefix}/AWSLogs/${var.account_id}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}
