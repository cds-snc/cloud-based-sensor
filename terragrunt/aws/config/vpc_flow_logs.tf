resource "aws_config_config_rule" "cbs_vpc_flow_logging_enabled" {
  name        = "cbs_vpc_flow_logging_enabled"
  description = "A Config rule that checks whether VPC flow logs are enabled."

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::VPC"
    ]
  }
}
