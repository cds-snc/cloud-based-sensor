# Cloud Based Sensor

Infrastructure to support the Canadian Centre for Cyber Security (CCCS) Cloud Based Sensor (CBS) integration with AWS accounts.  The flow is as follows:

1. Each AWS satellite account has an S3 bucket that collects service and access logs.
1. This satellite bucket replicates its objects to a central log archive bucket.
1. CBS pulls objects from the log archive bucket to scan for threats.

This repo uses Terraform and Terragrunt to define and manage the satellite and central account AWS resources.

# Setup
We use a bootstrap pattern to onboard new accounts so that we can create the OpenID Connect IAM roles that are used by our [Terraform GitHub Actions](./.github/workflows).  The following is only required once per account.

## Central account
1. Export an AWS access key for the central account.
1. Run [`./bootstrap/central_account_iam/bootstrap.sh`](./bootstrap/central_account_iam/bootstrap.sh).
1. Run `terragrunt init` in [`./terragrunt/env/central/central_account`](./terragrunt/env/central/central_account).
1. Import the bootstrapped role and IAM identity provider to the Terraform state:
```sh
terragrunt import \
    module.gh_oidc_roles.aws_iam_role.this[0] \
    ConfigTerraformAdministratorRole
terragrunt import \
    module.gh_oidc_roles.aws_iam_openid_connect_provider.github \
    ${GITHUB_OIDC_PROVIDER_ARN}
```

## Satellite account
1. Export an AWS access key for the satellite account.
1. Run [`./bootstrap/satellite_account_iam/bootstrap.sh`](./bootstrap/satellite_account_iam/bootstrap.sh).
1. Create a Pull Request with the new account ID added to [`./satellite_accounts`](./satellite_accounts).

# Log archive structure
**Note:** Cloudtrail logs are now centralized in the `o-gfiiyvq1tj` folder. This is the central Log Archive bucket name that all accounts log their Cloudtrail data to when they are created. After April 2022 the `cloudtrail_logs` folder will be empty as we only keep data for 14 days and no new data will be sent.

```
cbs-log-archive-bucket/
├─ [cloudtrail_logs]/
│  ├─ [AWSLogs]/
│  │  ├─ [aws_account_id]
│  │  │  ├─ file
│  │  │  ├─ ...
│  │  │  
├─ [lb_logs]/
│  ├─ [AWSLogs]/
│  │  ├─ [aws_account_id]
│  │  │  ├─ file
│  │  │  ├─ ...
│  │  │  
├─ [o-gfiiyvq1tj]/
│  ├─ [AWSLogs]/
│  │  ├─ [aws_account_id]
│  │  │  ├─ file
│  │  │  ├─ ...
│  │  │ 
├─ [vpc_flow_logs]/
│  ├─ [AWSLogs]/
│  │  ├─ [aws_account_id]
│  │  │  ├─ file
│  │  │  ├─ ...
│  │  │  
├─ [waf_acl_logs]/
│  ├─ [AWSLogs]/
│  │  ├─ [aws_account_id]
│  │  │  ├─ file
│  │  │  ├─ ...
```
