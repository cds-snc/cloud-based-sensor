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
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}
