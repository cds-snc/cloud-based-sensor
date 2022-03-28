variable "slack_webhook_url" {
  description = "Slack webhook used by the Notify Slack Lambda function when an alarm triggers."
  type        = string
  sensitive   = true
}
