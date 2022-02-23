variable "account_id" {
  description = "Source account id"
  type        = string
}

variable "region" {
  description = "Resource region"
  type        = string
  default     = "ca-central-1"
}

variable "billing_tag_key" {
  description = "The default tagging key"
  type        = string
}

variable "log_archive_account_id" {
  description = "Account ID of the log archive account"
  type        = string
}

variable "log_archive_bucket_name" {
  description = "Name of the S3 log archive account bucket.  Follows the pattern 'cbs-log-archive-$ACCOUNT_ID'"
  type        = string
}

variable "billing_tag_value" {
  description = "The default tagging value"
  type        = string
}

variable "satellite_account_ids" {
  description = "List of all the satellite account IDs"
  type        = list(string)
}

variable "satellite_bucket_name" {
  description = "Name of the S3 satellite account bucket.  Follows the pattern 'cbs-satellite-$ACCOUNT_ID'"
  type        = string
}

variable "satellite_s3_replicate_role_name" {
  description = "Name of the IAM role in each satellite account used to replicate objects to the log archive bucket."
  type        = string
}

variable "core_replicate_role_arn" {
  description = "arn of the role used to replicate objects from the core log archive bucket to the CBS archive bucket."
  type        = string
}

variable "core_log_archive_bucket_arn" {
  description = "arn of the bucket in core log archive account accepting logs from the CBS bucket."
  type        = string
}

variable "sentinel_cloudtrail_bucket_arn" {
  description = "arn of the bucket used to collect core logs and funnel to sentinel"
  type        = string
}
