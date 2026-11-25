# Bootstrapping Terraform

This solves a 🐓 and 🥚 problem in deploying the Cloud Based Sensor (CBS) infrastructure using Terraform since Terraform requires IAM credentials and cannot create it's own roles. This `bootstrap` directory will contain the base configuration required to manage the CBS infrastructure using Terragrunt and the related IAM assumed roles

## Sequence
- Create the central account `ConfigTerraformAdministratorRole` role to be used by Terraform (via GitHub Actions OIDC)
- For each account (satellite) that will be monitored by the CBS, create:
  - a `ConfigTerraformAdminExecutionRole` role with a trust relationship to the Central account's `ConfigTerraformAdministratorRole` role
  - a `ConfigTerraformReadOnlyExecutionRole` role with a trust relationship to the Central account's `ConfigTerraformReadOnlyRole` role (used for plans)
  - a `CbsSatelliteReplicateToLogArchive` role used by S3 replication