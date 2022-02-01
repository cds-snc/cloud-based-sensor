resource "aws_config_conformance_pack" "cbs" {
  name = "cloud-based-sensor"

  template_body = data.template_file.cbs_conformance_pack.rendered

  depends_on = [
    aws_lambda_permission.cbs_s3_satellite_bucket_rule,
    aws_lambda_permission.cbs_wafv2_logs_rule,
  ]
}

data "template_file" "cbs_conformance_pack" {
  template = file("conformance_packs/cloud_based_sensor.yml")
  vars = {
    satellite_logging_bucket                = var.satellite_bucket_name
    cbs_s3_satellite_bucket_rule_lambda_arn = aws_lambda_function.cbs_s3_satellite_bucket_rule.arn
    cbs_wafv2_logs_rule_lambda_arn          = aws_lambda_function.cbs_wafv2_logs_rule.arn
  }
}
