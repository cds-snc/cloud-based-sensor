variable "billing_code" {
  description = "The billing code to tag our resources with"
  type        = string
}

variable "cbs_managed_accounts" {
  description = "List of accounts managed by the CBS central account"
  type        = list(string)
}
