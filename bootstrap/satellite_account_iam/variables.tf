variable "account_id" {
  description = "(Required) The account ID to perform actions on."
  type        = string
}

variable "central_account_id" {
  description = "(Required) The account ID to centrally manage all accounts."
  type        = string
  default     = "339850311124"
}

variable "region" {
  description = "The current AWS region"
  type        = string
  default     = "ca-central-1"
}

