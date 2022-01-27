# Cloud Based Sensor

Infrastructure to support the Canadian Centre for Cyber Security (CCCS) Cloud Based Sensor (CBS) integration with AWS accounts.  The flow is as follows:

1. Each AWS satellite account has an S3 bucket that collects service and access logs.
1. This satellite bucket replicates its objects to a central log archive bucket.
1. CBS pulls objects from the log archive bucket to scan for threats.

This repo uses Terraform and Terragrunt to define and manage the satellite and central account AWS resources.

# Config rules
This project sets up [AWS managed and custom Lambda ConfigRules](./terragrunt/aws/config) to check that:

* the expected CBS resource exist; and
* logs are being sent to the satellite bucket.

The [`compliance-check.yml`](.github/workflows/compliance-check.yml) is then used to notify us when rules are non-compliant.  This will be switched to an SNS topic and subscription.

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

# Log archive structure
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
