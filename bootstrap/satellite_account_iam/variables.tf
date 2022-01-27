variable "central_account_id" {
  description = "(Required) The account ID to centrally manage all accounts."
  type        = string
  default     = "871282759583"
}

variable "region" {
  description = "The current AWS region"
  type        = string
  default     = "ca-central-1"
}

