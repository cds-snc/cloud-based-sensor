locals {
  vars = read_terragrunt_config("../env_vars.hcl")
}

inputs = {
  account_id        = "${local.vars.inputs.account_id}"
  billing_tag_key   = "CostCentre"
  billing_tag_value = "cbs-${local.vars.inputs.account_id}"   
  region            = "ca-central-1" 
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    encrypt        = true
    bucket         = "cbs-${local.vars.inputs.account_id}-tfstate"
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
