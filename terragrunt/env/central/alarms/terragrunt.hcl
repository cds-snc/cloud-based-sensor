terraform {
  source = "../../../aws//alarms"
}

inputs = {
  transport_lambda_log_group_name  = "/aws/lambda/CbsTransportLambda"
}

include {
  path = find_in_parent_folders()
  expose = true
}
