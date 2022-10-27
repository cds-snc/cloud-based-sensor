resource "aws_sns_topic" "log_archive" {
  name              = "log-archive"
  kms_master_key_id = aws_kms_key.log_archive_encrypt.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_sns_topic_policy" "log_archive" {
  arn    = aws_sns_topic.log_archive.arn
  policy = data.aws_iam_policy_document.log_archive_topic_policy.json
}

data "aws_iam_policy_document" "log_archive_topic_policy" {
  policy_id = "SNS Access Policy"

  # Allow this account to use the topic
  statement {
    sid    = "AllowSelfAccess"
    effect = "Allow"
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:AddPermission",
      "SNS:Subscribe"
    ]
    resources = [
      aws_sns_topic.log_archive.arn
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceOwner"
      values = [
        var.log_archive_account_id,
      ]
    }
  }

  # Allow transport Lambda to consume SNS notifications
  statement {
    sid    = "AllowLambdaAccess"
    effect = "Allow"
    actions = [
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic"
    ]
    resources = [
      aws_sns_topic.log_archive.arn
    ]
    principals {
      type        = "AWS"
      identifiers = [var.log_archive_account_id]
    }
  }

  # Allow S3 log archive bucket to publish SNS notifications
  statement {
    sid    = "AllowS3Access"
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]
    resources = [
      aws_sns_topic.log_archive.arn
    ]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        module.log_archive_bucket.s3_bucket_arn
      ]
    }
  }
}
