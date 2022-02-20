variable "billing_change_percent_threshold" {
  description = "Maximum billing percentage change between current and previous period."
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack webhook used by the Notify Slack Lambda function."
  type        = string
  sensitive   = true
}
