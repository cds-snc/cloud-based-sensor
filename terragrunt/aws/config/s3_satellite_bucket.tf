#
# Lambda function used by the ConfigRule
#
data "archive_file" "cbs_s3_satellite_bucket_rule" {
  count       = var.config_rules_ff ? 1 : 0
  type        = "zip"
  source_file = "config_rules/s3_satellite_bucket/s3_satellite_bucket_rule.py"
  output_path = "/tmp/cbs_s3_satellite_bucket_rule.zip"
}

resource "aws_lambda_function" "cbs_s3_satellite_bucket_rule" {
  count         = var.config_rules_ff ? 1 : 0
  filename      = "/tmp/cbs_s3_satellite_bucket_rule.zip"
  function_name = "CbsS3SatelliteBucketRule"
  role          = aws_iam_role.cbs_s3_satellite_bucket_rule.arn
  handler       = "s3_satellite_bucket_rule.lambda_handler"

  source_code_hash = data.archive_file.cbs_s3_satellite_bucket_rule.output_base64sha256
  runtime          = "python3.9"

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_permission" "cbs_s3_satellite_bucket_rule" {

  count         = var.config_rules_ff ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cbs_s3_satellite_bucket_rule.arn
  principal     = "config.amazonaws.com"
  statement_id  = "AllowExecutionFromConfig"
}

resource "aws_cloudwatch_log_group" "cbs_s3_satellite_bucket_rule" {
  count             = var.config_rules_ff ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.cbs_s3_satellite_bucket_rule.function_name}"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Lambda execution role
#
resource "aws_iam_role" "cbs_s3_satellite_bucket_rule" {
  count              = var.config_rules_ff ? 1 : 0
  name               = "CbsS3SatelliteBucketRule"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_iam_role_policy_attachment" "cbs_s3_satellite_bucket_rule_basic_execution" {
  count      = var.config_rules_ff ? 1 : 0
  role       = aws_iam_role.cbs_s3_satellite_bucket_rule.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cbs_s3_satellite_bucket_rule_s3_list_buckets" {
  role       = aws_iam_role.cbs_s3_satellite_bucket_rule.name
  policy_arn = aws_iam_policy.s3_list_buckets.arn
}

resource "aws_iam_policy" "s3_list_buckets" {
  name        = "CbsS3ListBuckets"
  path        = "/"
  description = "IAM policy for listing all S3 buckets"
  policy      = data.aws_iam_policy_document.s3_list_buckets.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "s3_list_buckets" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
}
