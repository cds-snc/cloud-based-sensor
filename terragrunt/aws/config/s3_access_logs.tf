#
# Lambda function used by the ConfigRule
#
data "archive_file" "cbs_s3_access_logs_rule" {
  type        = "zip"
  source_file = "config_rules/s3_access_logs/s3_access_logs_rule.py"
  output_path = "/tmp/cbs_s3_access_logs_rule.zip"
}

resource "aws_lambda_function" "cbs_s3_access_logs_rule" {
  filename      = "/tmp/cbs_s3_access_logs_rule.zip"
  function_name = "CbsS3AccessLogsRule"
  role          = aws_iam_role.cbs_s3_access_logs_rule.arn
  handler       = "s3_access_logs_rule.lambda_handler"

  source_code_hash = data.archive_file.cbs_s3_access_logs_rule.output_base64sha256
  runtime          = "python3.9"

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_permission" "cbs_s3_access_logs_rule" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cbs_s3_access_logs_rule.arn
  principal     = "config.amazonaws.com"
  statement_id  = "AllowExecutionFromConfig"
}

resource "aws_cloudwatch_log_group" "cbs_s3_access_logs_rule" {
  name              = "/aws/lambda/${aws_lambda_function.cbs_s3_access_logs_rule.function_name}"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Lambda execution role
#
resource "aws_iam_role" "cbs_s3_access_logs_rule" {
  name               = "CbsS3AccessLogsRule"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_iam_role_policy_attachment" "cbs_s3_access_logs_rule_basic_execution" {
  role       = aws_iam_role.cbs_s3_access_logs_rule.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cbs_s3_access_logs_rule_policy" {
  role       = aws_iam_role.cbs_s3_access_logs_rule.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_policy" "policy" {
  name        = "CbsS3AccessLogsPolicy"
  path        = "/"
  description = "IAM policy for listing all S3 buckets and their logging configuration"
  policy      = data.aws_iam_policy_document.policy.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"
    actions = [
      "config:PutEvaluations",
      "s3:GetBucketAcl",
      "s3:GetBucketLogging",
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }
}
