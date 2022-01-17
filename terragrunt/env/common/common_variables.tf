variable "account_id" {
  description = "Source account id"
  type        = string
}

variable "bucket_name" {
  description = "Name of satellite S3 bucket to send to cloud based sensor account"
  type        = string
}

variable "cbs_central_bucket_arn" {
  description = "Cloud based sensor destination collector S3 arn"
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

variable "billing_tag_value" {
  description = "The default tagging value"
  type        = string
}

variable "env" {
  description = "The current running environment"
  type        = string
  default     = "test"
}



