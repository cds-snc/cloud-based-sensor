#
# Lambda function used by the ConfigRule
#
data "archive_file" "cbs_wafv2_logs_rule" {
  type        = "zip"
  source_file = "config_rules/wafv2_logs/webacl_logs_rule.py"
  output_path = "/tmp/cbs_wafv2_logs_rule.zip"
}

resource "aws_lambda_function" "cbs_wafv2_logs_rule" {
  filename      = "/tmp/cbs_wafv2_logs_rule.zip"
  function_name = "cbs-wafv2-logs-rule"
  role          = aws_iam_role.cbs_wafv2_logs_rule.arn
  handler       = "webacl_logs_rule.lambda_handler"

  source_code_hash = data.archive_file.cbs_wafv2_logs_rule.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      FIREHOSE_ARN = aws_kinesis_firehose_delivery_stream.cbs_default_stream.arn
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_permission" "cbs_wafv2_logs_rule" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cbs_wafv2_logs_rule.arn
  principal     = "config.amazonaws.com"
  statement_id  = "AllowExecutionFromConfig"
}

resource "aws_cloudwatch_log_group" "cbs_wafv2_logs_rule" {
  name              = "/aws/lambda/${aws_lambda_function.cbs_wafv2_logs_rule.function_name}"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Lambda execution role
#
resource "aws_iam_role" "cbs_wafv2_logs_rule" {
  name               = "cbs-wafv2-logs-rule"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_iam_role_policy_attachment" "cbs_wafv2_logs_rule_basic_execution" {
  role       = aws_iam_role.cbs_wafv2_logs_rule.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cbs_wafv2_logs_rule_wafv2_list_web_acls" {
  role       = aws_iam_role.cbs_wafv2_logs_rule.name
  policy_arn = aws_iam_policy.wafv2_list_web_acls.arn
}

resource "aws_iam_policy" "wafv2_list_web_acls" {
  name        = "cbs-wafv2-acls-policy"
  path        = "/"
  description = "IAM policy for listing all WAFv2 ACLs"
  policy      = data.aws_iam_policy_document.wafv2_list_web_acls.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "wafv2_list_web_acls" {
  statement {
    effect = "Allow"
    actions = [
      "wafv2:GetWebACL",
      "wafv2:GetLoggingConfiguration",
      "wafv2:ListWebACLs",
      "wafv2:ListLoggingConfigurations",
      "config:PutEvaluations",
      "iam:CreateServiceLinkedRole",
    ]
    resources = ["*"]
  }
}
