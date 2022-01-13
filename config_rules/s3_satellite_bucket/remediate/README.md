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