variable "slack_webhook_url" {
  description = "Slack webhook used by the Notify Slack Lambda function."
  type        = string
  sensitive   = true
}
