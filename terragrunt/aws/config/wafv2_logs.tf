#
# Lambda function used by the ConfigRule
#
data "archive_file" "cbs_wafv2_logs_rule" {
  count       = var.config_rules_ff ? 1 : 0
  type        = "zip"
  source_file = "config_rules/wafv2_logs/webacl_logs_rule.py"
  output_path = "/tmp/cbs_wafv2_logs_rule.zip"
}

resource "aws_lambda_function" "cbs_wafv2_logs_rule" {
  count         = var.config_rules_ff ? 1 : 0
  filename      = "/tmp/cbs_wafv2_logs_rule.zip"
  function_name = "cbs-wafv2-logs-rule"
  role          = aws_iam_role.cbs_wafv2_logs_rule[0].arn
  handler       = "webacl_logs_rule.lambda_handler"

  source_code_hash = data.archive_file.cbs_wafv2_logs_rule[0].output_base64sha256
  runtime          = "python3.9"

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_permission" "cbs_wafv2_logs_rule" {
  count         = var.config_rules_ff ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cbs_wafv2_logs_rule[0].arn
  principal     = "config.amazonaws.com"
  statement_id  = "AllowExecutionFromConfig"
}

resource "aws_cloudwatch_log_group" "cbs_wafv2_logs_rule" {
  count             = var.config_rules_ff ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.cbs_wafv2_logs_rule[0].function_name}"
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
  count              = var.config_rules_ff ? 1 : 0
  name               = "cbs-wafv2-logs-rule"
  assume_role_policy = data.aws_iam_policy_document[0].lambda_assume.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_iam_role_policy_attachment" "cbs_wafv2_logs_rule_basic_execution" {
  count      = var.config_rules_ff ? 1 : 0
  role       = aws_iam_role.cbs_wafv2_logs_rule[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cbs_wafv2_logs_rule_wafv2_list_web_acls" {
  count      = var.config_rules_ff ? 1 : 0
  role       = aws_iam_role.cbs_wafv2_logs_rule[0].name
  policy_arn = aws_iam_policy.wafv2_list_web_acls[0].arn
}

resource "aws_iam_policy" "wafv2_list_web_acls" {
  count       = var.config_rules_ff ? 1 : 0
  name        = "cbs-wafv2-acls-policy"
  path        = "/"
  description = "IAM policy for listing all WAFv2 ACLs"
  policy      = data.aws_iam_policy_document.wafv2_list_web_acls[0].json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "wafv2_list_web_acls" {
  count = var.config_rules_ff ? 1 : 0
  # checkov:skip=CKV_AWS_109: TODO tighten down resource access
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
