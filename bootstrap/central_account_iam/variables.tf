variable "region" {
  description = "The current AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "billing_code" {
  description = "The billing code to tag our resources with"
  type        = string
  default     = "cbs-central"
}
