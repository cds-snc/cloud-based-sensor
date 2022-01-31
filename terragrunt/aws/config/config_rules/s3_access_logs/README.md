### AWS permissions required
Compliance check to ensure S3 buckets are sending access logs to the `cbs-satellite-${AWS_ACCOUNT_ID}` bucket.
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetBucketAcl",
    "s3:GetBucketLogging",
    "s3:ListAllMyBuckets"
  ],
  "Resource": "arn:aws:s3:::*"
}
```