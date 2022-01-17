resource "aws_s3_bucket" "cbs_satellite_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    enabled = true
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
