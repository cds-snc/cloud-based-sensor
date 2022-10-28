variable "slack_webhook_url" {
  description = "Slack webhook used by the Notify Slack Lambda function when an alarm triggers."
  type        = string
  sensitive   = true
}

variable "transport_lambda_log_group_name" {
  description = "Name of the CBS transport lambda's CloudWatch log group"
  type        = string
  default     = ""
}
