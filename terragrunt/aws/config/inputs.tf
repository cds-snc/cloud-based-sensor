// variable for AWS Config rule 
variable "config_max_execution_frequency" {
  description = "The maximum frequency with which AWS Config runs evaluations for a rule."
  default     = "TwentyFour_Hours"
  type        = string
}

variable "aws_waf_log_bucket" {
  description = "S3 bucket to store WAF logs"
  type        = string
}

variable "billing_code" {
  description = "The billing code to tag our resources with"
  type        = string
  default     = "cbs-central"
}
