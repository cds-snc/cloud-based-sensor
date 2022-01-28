#
# Satellite bucket and access logging
#
module "satellite_bucket" {
  source            = "github.com/cds-snc/terraform-modules?ref=v1.0.4//S3"
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
  source            = "github.com/cds-snc/terraform-modules?ref=v1.0.4//S3_log_bucket"
  bucket_name       = "${var.satellite_bucket_name}-access"
  billing_tag_value = var.billing_tag_value
  force_destroy     = true
}

resource "aws_s3_bucket_ownership_controls" "satellite_bucket" {
  bucket = module.satellite_bucket.s3_bucket_id

  rule {
    object_ownership = "ObjectWriter"
  }
}
