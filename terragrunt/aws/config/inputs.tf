// variable for AWS Config rule 
variable "config_max_execution_frequency" {
  description = "The maximum frequency with which AWS Config runs evaluations for a rule."
  default     = "TwentyFour_Hours"
  type        = string
}

variable "config_rules_ff" {
  description = "A feature flag to turn off config rules, turn off for Control Tower Accounts"
  default     = true
  type        = string
}