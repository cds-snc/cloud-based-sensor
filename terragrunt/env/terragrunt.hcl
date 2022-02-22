locals {
  vars                   = read_terragrunt_config("../env_vars.hcl")
  log_archive_account_id = "871282759583"
}

inputs = {
  account_id                         = "${get_aws_account_id()}"
  billing_tag_key                    = "CostCentre"
  billing_tag_value                  = "cbs-${get_aws_account_id()}"
  log_archive_account_id             = local.log_archive_account_id
  log_archive_bucket_name            = "cbs-log-archive-${local.log_archive_account_id}"
  region                             = "ca-central-1"
  satellite_bucket_name              = "cbs-satellite-${get_aws_account_id()}"
  satellite_s3_replicate_role_name   = "CbsSatelliteReplicateToLogArchive"
  satellite_account_ids              = split("\n", chomp(replace(file("../../satellite_accounts"),"\"","")))
  core_replicate_role_arn            = "arn:aws:iam::925306372402:role/CoreReplicateToCBSCentral"
  core_log_archive_bucket_arn        = "arn:aws:s3:::aws-landing-zone-logs-925306372402-ca-central-1"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    encrypt        = true
    bucket         = "cbs-${get_aws_account_id()}-tfstate"
    dynamodb_table = "tfstate-lock"
    region         = "ca-central-1"
    key            = "${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = file("./common/provider.tf")
}

generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite"
  contents  = file("./common/common_variables.tf")
}
