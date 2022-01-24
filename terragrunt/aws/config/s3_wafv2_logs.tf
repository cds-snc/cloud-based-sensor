#
# Config Rule
#
resource "aws_config_config_rule" "cbs_s3_wafv2_logs_rule" {
  name        = "cbs_s3_wafv2_logs_rule"
  description = "Checks that the WAFV2 ACL's are logging to either S3 or Kinesis."

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.cbs_s3_wafv2_logs_rule.arn

    source_detail {
      message_type                = "ScheduledNotification"
      maximum_execution_frequency = var.config_max_execution_frequency
    }
  }

  scope {
    compliance_resource_types = ["AWS::WAFv2::WebACL"]
  }

  depends_on = [
    aws_lambda_permission.cbs_s3_wafv2_logs_rule,
  ]
}

#
# Lambda function used by the ConfigRule
#
data "archive_file" "cbs_s3_wafv2_logs_rule" {
  type        = "zip"
  source_file = "config_rules/s3_wafv2_logs/compliance/s3_wafv2_logs_rule.py"
  output_path = "/tmp/cbs_s3_wafv2_logs_rule.zip"
}

resource "aws_lambda_function" "cbs_s3_wafv2_logs_rule" {
  filename      = "/tmp/cbs_s3_wafv2_logs_rule.zip"
  function_name = "cbs_s3_wafv2_logs_rule"
  role          = aws_iam_role.cbs_s3_wafv2_logs_rule.arn
  handler       = "s3_wafv2_logs_rule.lambda_handler"

  source_code_hash = data.archive_file.cbs_s3_wafv2_logs_rule.output_base64sha256
  runtime          = "python3.9"

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_permission" "cbs_s3_wafv2_logs_rule" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cbs_s3_wafv2_logs_rule.arn
  principal     = "config.amazonaws.com"
  statement_id  = "AllowExecutionFromConfig"
}

resource "aws_cloudwatch_log_group" "cbs_s3_wafv2_logs_rule" {
  name              = "/aws/lambda/${aws_lambda_function.cbs_s3_wafv2_logs_rule.function_name}"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Lambda execution role
#
resource "aws_iam_role" "cbs_s3_wafv2_logs_rule" {
  name               = "cbs_s3_wafv2_logs_rule"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_iam_role_policy_attachment" "cbs_s3_wafv2_logs_rule_basic_execution" {
  role       = aws_iam_role.cbs_s3_wafv2_logs_rule.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cbs_s3_wafv2_logs_rule_wafv2_list_web_acls" {
  role       = aws_iam_role.cbs_s3_wafv2_logs_rule.name
  policy_arn = aws_iam_policy.wafv2_list_web_acls.arn
}

resource "aws_iam_policy" "wafv2_list_web_acls" {
  name        = "wafv2_list_web_acls"
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
    effect    = "Allow"
    actions   = ["wafv2:ListWebACLs"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["wafv2:ListLoggingConfigurations"]
    resources = ["*"]
  }
}

module "waf_logs" {
  source            = "github.com/cds-snc/terraform-modules?ref=v1.0.4//S3"
  bucket_name       = var.aws_waf_log_bucket
  billing_tag_value = var.billing_tag_value

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      enabled = true
      expiration = {
        days = 14
      }
    }
  ]
}
