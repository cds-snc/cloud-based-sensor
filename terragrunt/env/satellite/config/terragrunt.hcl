terraform {
  source = "../../../aws//config"
}

inputs = {
  config_max_execution_frequency = "TwentyFour_Hours"
  aws_waf_log_bucket = "aws-waf-logs-cbs-${get_aws_account_id()}"
}

include {
  path = find_in_parent_folders()
  expose = true
}
