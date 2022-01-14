# AWS permissions required
Remediation to create the `cbs-satellite-account-bucket${AWS_ACCOUNT_ID}` s3 bucket if it gets deleted.
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:CreateBucket",
    "s3:PutEncryptionConfiguration",
    "s3:PutLifecycleConfiguration",
    "s3:PutBucketPublicAccessBlock",
    "s3:PutReplicationConfiguration",
  ],
  "Resource": "arn:aws:s3:::cbs-satellite-account-bucket${AWS_ACCOUNT_ID}"
}
```

# Terraform example
The following Terraform will create the S3 source and destinations buckets and the replication rule that:
* Replicates objects from source to destination;
* Encrypts them with the destination account's Customer Managed Key (CMK); and
* Transfers object ownership to the destination bucket.

## :warning: Note
To use the Terraform:
1. `terraform apply` the Destination resources, which will fail attempting to create the `aws_kms_key.destination_encrypt` policy as the Source `S3Replicate` role does not exist yet.  
1. `terraform apply` the Source resources.
1. `terraform apply` the Destination resources.
An alternative to the above apply/fail would be to create a placeholder `S3Replicate` with no policies attached to start with.

## Source
```hcl
provider "aws" {
  region = "ca-central-1"
}


#
# Variables
#
variable "account_id_destination" {
  type = string
}

variable "account_id_source" {
  type = string
}

variable "destination_bucket_arn" {
  type = string
}

variable "destination_kms_key_arn" {
  type = string
}


#
# Replication role
#
resource "aws_iam_role" "s3_replicate" {
  name               = "S3Replicate"
  assume_role_policy = data.aws_iam_policy_document.s3_replicate_assume.json
}

resource "aws_iam_policy" "s3_replicate" {
  name   = "S3ReplicatePolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.s3_replicate.json
}

resource "aws_iam_role_policy_attachment" "s3_replicate" {
  role       = aws_iam_role.s3_replicate.name
  policy_arn = aws_iam_policy.s3_replicate.arn
}

data "aws_iam_policy_document" "s3_replicate_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_replicate" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.source.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl"
    ]
    resources = [
      "${aws_s3_bucket.source.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateObject",
      "s3:ReplicateDelete"
    ]
    resources = [
      "${var.destination_bucket_arn}/*"
    ]
  }
}


#
# Source bucket
#
resource "aws_s3_bucket" "source" {
  bucket = "scratch-test-bucket-replication-source"

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

  replication_configuration {
    role = aws_iam_role.s3_replicate.arn

    rules {
      id     = "ToDestination"
      prefix = ""
      status = "Enabled"

      destination {
        account_id         = var.account_id_destination
        bucket             = var.destination_bucket_arn
        replica_kms_key_id = var.destination_kms_key_arn
        access_control_translation {
          owner = "Destination"
        }
      }

      source_selection_criteria {
        sse_kms_encrypted_objects {
          enabled = true
        }
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "source" {
  bucket = aws_s3_bucket.source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## Destination
```hcl
provider "aws" {
  region = "ca-central-1"
}


#
# Variables
#
variable "account_id_destination" {
  type = string
}

variable "account_id_source" {
  type = string
}


#
# Destination
#
resource "aws_s3_bucket" "destination" {
  bucket = "scratch-test-bucket-replication-destination"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.destination_encrypt.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "destination" {
  bucket = aws_s3_bucket.destination.id
  policy = data.aws_iam_policy_document.destination_allow_replicate.json
}

data "aws_iam_policy_document" "destination_allow_replicate" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id_source}:role/S3Replicate"]
    }
    actions = [
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateObject",
      "s3:ReplicateDelete"
    ]
    resources = [
      "${aws_s3_bucket.destination.arn}/*",
    ]
  }
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id_source}:role/S3Replicate"]
    }
    actions = [
      "s3:List*",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [
      aws_s3_bucket.destination.arn
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "destination" {
  bucket = aws_s3_bucket.destination.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#
# KMS key for destination bucket encryption
#
resource "aws_kms_key" "destination_encrypt" {
  description         = "Encrypt objects in the destination S3 bucket"
  enable_key_rotation = "true"
  policy              = data.aws_iam_policy_document.destination_encrypt.json
}

data "aws_iam_policy_document" "destination_encrypt" {
  # Allow the destinatino account to use the key
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id_destination}:root"]
    }
  }

  # Allow the source account to use the key
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id_source}:root"]
    }
  }
}

```