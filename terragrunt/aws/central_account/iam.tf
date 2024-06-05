#
# Role used to read objects from the log archive bucket
#
resource "aws_iam_role" "log_archive_read" {
  name               = "CbsASEAReaderRole"
  assume_role_policy = sensitive(data.aws_iam_policy_document.log_archive_read_assume.json)
}

data "aws_iam_policy_document" "log_archive_read_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.cbs_principal_arn]
    }
  }
}

resource "aws_iam_policy" "log_archive_read" {
  name   = "CbsASEAReaderRole"
  path   = "/"
  policy = data.aws_iam_policy_document.log_archive_read.json
}

resource "aws_iam_role_policy_attachment" "log_archive_read" {
  role       = aws_iam_role.log_archive_read.name
  policy_arn = aws_iam_policy.log_archive_read.arn
}

data "aws_iam_policy_document" "log_archive_read" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      module.log_archive_bucket.s3_bucket_arn,
      "${module.log_archive_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      aws_kms_key.log_archive_encrypt.arn
    ]
  }
}

# Required for CBS v2.3
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "event_bus_invoke_remote_event_bus" {
  name               = "event-bus-invoke-remote-event-bus"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = {
    Owner = "CBS"
  }
}

data "aws_iam_policy_document" "event_bus_invoke_remote_event_bus" {
  statement {
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [var.cbs_destination_event_bus_arn]
  }
}

resource "aws_iam_policy" "event_bus_invoke_remote_event_bus" {
  name   = "event_bus_invoke_remote_event_bus"
  policy = data.aws_iam_policy_document.event_bus_invoke_remote_event_bus.json
}

resource "aws_iam_role_policy_attachment" "event_bus_invoke_remote_event_bus" {
  role       = aws_iam_role.event_bus_invoke_remote_event_bus.name
  policy_arn = aws_iam_policy.event_bus_invoke_remote_event_bus.arn
}
