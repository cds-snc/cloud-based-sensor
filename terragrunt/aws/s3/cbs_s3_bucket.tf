resource "aws_s3_bucket" "cbs_satellite_bucket" {
  # checkov:skip=CKV_AWS_18: Access logging will be enabled on the final bucket infrastructure
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 14
    }
  }

  replication_configuration {
    role = aws_iam_role.replication.arn

    rules {
      status = "Enabled"

      destination {
        bucket = var.cbs_central_bucket_arn
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cbs_satellite_bucket" {
  bucket = aws_s3_bucket.cbs_satellite_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_pet" "this" {
  length = 2
}
resource "aws_iam_role" "replication" {
  name = "cbs-replication-${random_pet.this.id}"

  assume_role_policy = <<POLICY
{
  "Version"             : "2012-10-17",
  "Statement": [
    {
      "Action"          : "sts:AssumeRole",
      "Principal": {
        "Service"       : "s3.amazonaws.com"
      },
      "Effect"          : "Allow",
      "Sid"             : ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  name = "cbs-replication-${random_pet.this.id}"

  policy = <<POLICY
{
  "Version"             : "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect"          : "Allow",
      "Resource"        : "arn:aws:s3:::${var.bucket_name}"
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect"          : "Allow",
      "Resource"        :  "arn:aws:s3:::${var.bucket_name}/*"
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect"          : "Allow",
      "Resource"        : "${var.cbs_central_bucket_arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "replication" {
  name       = "cbs-replication-${random_pet.this.id}"
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}
