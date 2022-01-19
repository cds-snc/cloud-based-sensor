# Cloud Based Sensor

Infrastructure configuration to support the Canadian Centre for Cyber Security (CCCS) Cloud Based Sensor integration with CDS's AWS accounts.

# CBS logging strucuture

```
cbs-central-logging-bucket/
├─ [aws_account_id]/
│  ├─ [cloudtrail_logs]/
│  │  ├─ [trail_name]/
│  │  │  ├─ file_1
│  │  │  ├─ ...
│  ├─ [elb_logs]/
│  │  ├─ [elb_name]/
│  │  │  ├─ file_1
│  │  │  ├─ ...
│  ├─ [s3_access_logs]/
│  │  ├─ [bucket_name]/
│  │  │  ├─ file_1
│  │  │  ├─ ...
│  ├─ [vpc_flow_logs]/
│  │  ├─ [vpc_id]/
│  │  │  ├─ file_1
│  │  │  ├─ ...
│  ├─ [waf_acl_logs]/
│  │  ├─ [account_id]/
│  │  │  ├─ file_1
│  │  │  ├─ ...
```

# Config rules
* [`s3_satellite_bucket`](./terragrunt/aws/config/s3_satellite_bucket.tf): Checks that an account has the expected CBS s3 satellite bucket. 
* [`s3_access_logs`](./terragrunt/aws/config/s3_access_logs.tf): Checks that all s3 buckets are replicating to the expected CBS s3 satellite bucket. 

# Common Lambda IAM permissions

```json
{
  "Effect": "Allow",
  "Action": "config:PutEvaluations",
  "Resource": "*"
}
```