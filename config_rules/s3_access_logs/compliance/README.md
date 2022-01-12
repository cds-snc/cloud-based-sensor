### AWS permissions required
Compliance check retrieves the replication configuration of a s3 bucket to check if it's replicating to the satellite bucket with name `cbs-satellite-account-bucket${AWS_ACCOUNT_ID}`.
```json
{
  "Effect": "Allow",
  "Action": "s3:GetReplicationConfiguration",
  "Resource": "arn:aws:s3:::*"
}
```