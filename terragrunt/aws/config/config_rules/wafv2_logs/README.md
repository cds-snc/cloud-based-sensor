# AWS permissions required
Compliance check to ensure that the WAFV2 ACL's are logging to either S3 or Kinesis.
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "wafv2:GetWebACL",
                "wafv2:GetLoggingConfiguration",
                "wafv2:ListWebACLs",
                "wafv2:ListLoggingConfigurations",
                "wafv2:PutLoggingConfiguration",
                "config:PutEvaluations",
                "iam:CreateServiceLinkedRole",
            ],
            "Resource": "*"
        },
    ]
}
```