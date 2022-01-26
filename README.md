# Cloud Based Sensor

Infrastructure to support the Canadian Centre for Cyber Security (CCCS) Cloud Based Sensor (CBS) integration with AWS accounts.  The flow is as follows:

1. Each AWS satellite account has an S3 bucket that collects service and access logs.
1. This satellite bucket replicates its objects to a central log archive bucket.
1. CBS pulls objects from the log archive bucket to scan for threats.

This repo uses Terraform and Terragrunt to define and manage the satellite and central account AWS resources.

# CBS logging strucuture

```
cbs-log-archive-bucket/
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

# Setup
We use a bootstrap pattern to onboard new accounts so that we can create the OpenID Connect IAM roles that are used by our [Terraform GitHub Actions](./.github/workflows).  The following is only required once per account.

## Central account
1. Export an AWS access key for the central account.
1. Run [`./bootstrap/central_account_iam/bootstrap.sh`](./bootstrap/central_account_iam/bootstrap.sh)
1. Run `terragrunt init` in [`./terragrunt/env/central/central_account`](./terragrunt/env/central/central_account)
1. Import the bootstrapped role with `terragrunt import aws_iam_role.config_terraform_role ConfigTerraformAdministratorRole`

## Satellite account
1. Export an AWS access key for the satellite account.
1. Run [`./bootstrap/satellite_account_iam/bootstrap.sh`](./bootstrap/satellite_account_iam/bootstrap.sh).
1. Create a Pull Request with the new account ID added to [`./satellite_accounts`](./satellite_accounts).

# Debugging

### Auto remediation

```bash
aws configservice describe-remediation-execution-status \
  --config-rule-name rule_name \
  --region ca-central-1
```