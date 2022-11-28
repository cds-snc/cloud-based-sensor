resource "aws_cloudwatch_metric_alarm" "no_transport_lambda_logs" {
  alarm_name          = "NoTransportLambdaNoLogs"
  alarm_description   = "CBS Transport lambda is sending logs to CCCS over a 30 minute period"
  comparison_operator = "LessThanThreshold"

  metric_name        = "IncomingLogEvents"
  namespace          = "AWS/Logs"
  period             = "300"
  evaluation_periods = "6"
  statistic          = "Sum"
  threshold          = "100"
  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.cloudwatch_alarm.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_alarm.arn]

  dimensions = {
    LogGroupName = var.transport_lambda_log_group_name
  }
}

locals {
  error_logged    = "TransportLambdaErrorLogged"
  error_namespace = "CloudBasedSensor"
}

resource "aws_cloudwatch_log_metric_filter" "transport_lambda_error" {
  name           = local.error_logged
  pattern        = "ERROR"
  log_group_name = var.transport_lambda_log_group_name

  metric_transformation {
    name      = local.error_logged
    namespace = local.error_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "transport_lambda_error" {
  alarm_name          = local.error_logged
  alarm_description   = "Errors logged by the CBS transport lambda"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  metric_name        = aws_cloudwatch_log_metric_filter.transport_lambda_error.metric_transformation[0].name
  namespace          = aws_cloudwatch_log_metric_filter.transport_lambda_error.metric_transformation[0].namespace
  period             = "60"
  evaluation_periods = "1"
  statistic          = "Sum"
  threshold          = "1"
  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.cloudwatch_alarm.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_alarm.arn]
}
