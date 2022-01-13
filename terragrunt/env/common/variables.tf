variable "ACCOUNT_ID" {
  description = "Source account id"
  type        = string
}

variable "BUCKET_NAME" {
  description = "Name of satellite S3 bucket to send to cloud based sensor account"
  type        = string
}

variable "CBS_ACCOUNT_ID" {
  description = "Cloud based sensor S3 logs collector account"
  type        = string
}

variable "CBS_CENTRAL_BUCKET_ARN" {
  description = "Cloud based sensor destination collector S3 arn"
  type        = string
}

variable "REGION" {
  description = "Resource region"
  type        = string
  default     = "ca-central-1"
}

variable "COST_CENTER_CODE" {
  description = "Random tag for the moment"
  type        = string
}
