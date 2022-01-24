# AWS permissions required
Compliance check lists all WAF ACL's in the account to check if they are logging to either S3 or Kinesis.
```json
{
  "Effect": "Allow",
  "Action": "wafv2:list_web_acls",
  "Resource": "*"
}, 
{
  "Effect": "Allow",
  "Action": "wafv2:ListLoggingConfigurations",
  "Resource": "*"
}
```