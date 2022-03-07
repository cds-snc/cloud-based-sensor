#
# SNS: topic, subscription and Lambda that posts to Slack
#
resource "aws_sns_topic" "cloudwatch_alarm_us_east" {
  provider = aws.us-east-1

  name              = "cbs-cloudwatch-alarm"
  kms_master_key_id = aws_kms_key.sns_cloudwatch_us_east.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_sns_topic_subscription" "cloudwatch_alarm_us_east" {
  provider = aws.us-east-1

  topic_arn = aws_sns_topic.cloudwatch_alarm_us_east.arn
  protocol  = "lambda"
  endpoint  = module.notify_slack.lambda_arn
}

module "notify_slack" {
  source = "github.com/cds-snc/terraform-modules?ref=v1.0.10//notify_slack"

  function_name     = "cbs-notify-slack"
  project_name      = var.account_id
  slack_webhook_url = var.slack_webhook_url
  sns_topic_arns    = [aws_sns_topic.cloudwatch_alarm_us_east.arn]

  billing_tag_key   = var.billing_tag_key
  billing_tag_value = var.billing_tag_value
}
