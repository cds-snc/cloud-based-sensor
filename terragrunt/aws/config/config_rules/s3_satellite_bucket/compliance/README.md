# AWS permissions required
Compliance check lists all buckets in the account to check if the satellite bucket with name `cbs-central-satellite-${AWS_ACCOUNT_ID}` exists.
```json
{
  "Effect": "Allow",
  "Action": "s3:ListAllMyBuckets",
  "Resource": "*"
}
```