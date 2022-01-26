resource "aws_config_config_rule" "cbs_elb_logging_enabled" {
  name        = "cbs_elb_logging_enabled"
  description = "A Config rule that checks whether ELB logging is enabled."

  source {
    owner             = "AWS"
    source_identifier = "ELB_LOGGING_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::ElasticLoadBalancing::LoadBalancer",
      "AWS::ElasticLoadBalancingV2::LoadBalancer"
    ]
  }
}
