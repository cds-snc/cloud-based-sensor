resource "aws_config_conformance_pack" "cbs" {
  count = var.config_rules_ff ? 1 : 0
  name = "cloud-based-sensor"

  template_body = data.template_file.cbs_conformance_pack[0].rendered

  depends_on = [
    aws_lambda_permission.cbs_s3_satellite_bucket_rule[0],
    aws_lambda_permission.cbs_wafv2_logs_rule[0],
  ]
}

data "template_file" "cbs_conformance_pack" {
  count = var.config_rules_ff ? 1 : 0
  template = file("conformance_packs/cloud_based_sensor.yml")
  vars = {
    satellite_logging_bucket                = var.satellite_bucket_name
    cbs_s3_satellite_bucket_rule_lambda_arn = aws_lambda_function.cbs_s3_satellite_bucket_rule[0].arn
    cbs_wafv2_logs_rule_lambda_arn          = aws_lambda_function.cbs_wafv2_logs_rule[0].arn
  }
}
