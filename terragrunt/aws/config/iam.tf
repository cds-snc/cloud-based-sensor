resource "aws_iam_role" "security_config" {
  name = "security_config"

  assume_role_policy = data.aws_iam_policy_document.aws_config_assume_role_policy.json
}

resource "aws_iam_policy_attachment" "managed_policy" {
  name = "aws_config_managed_policy"
  roles = [
    aws_iam_role.security_config.name,
    aws_iam_role.cbs_s3_satellite_bucket_rule.name
  ]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_iam_policy" "aws_config_policy" {
  name   = "aws_config_policy"
  policy = data.aws_iam_policy_document.aws_config_policy.json
}

resource "aws_iam_policy_attachment" "aws-aws_config_policy-policy" {
  name       = "aws_config_policy"
  roles      = ["${aws_iam_role.security_config.name}"]
  policy_arn = aws_iam_policy.aws_config_policy.arn
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
