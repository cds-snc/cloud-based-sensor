variable "account_id" {
  description = "(Required) The account ID to perform actions on."
  type        = string
}

variable "region" {
  description = "The current AWS region"
  type        = string
  default     = "ca-central-1"
}

