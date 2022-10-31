#
# SNS: topic, subscription and Lambda that posts to Slack
#
resource "aws_sns_topic" "cloudwatch_alarm" {
  name              = "cbs-cloudwatch-alarm"
  kms_master_key_id = aws_kms_key.sns_cloudwatch.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_sns_topic_subscription" "cloudwatch_alarm" {
  topic_arn = aws_sns_topic.cloudwatch_alarm.arn
  protocol  = "lambda"
  endpoint  = module.notify_slack.lambda_arn
}

module "notify_slack" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.19//notify_slack"

  function_name     = "cbs-notify-slack"
  project_name      = var.account_id
  slack_webhook_url = var.slack_webhook_url
  sns_topic_arns = [
    aws_sns_topic.cloudwatch_alarm.arn
  ]

  billing_tag_key   = var.billing_tag_key
  billing_tag_value = var.billing_tag_value
}
