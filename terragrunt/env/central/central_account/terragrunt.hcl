terraform {
  source = "../../../aws//central_account"
}

inputs = {
  cbs_transport_lambda_name = "CbsTransportLambda"
}

include {
  path = find_in_parent_folders()
  expose = true
}
