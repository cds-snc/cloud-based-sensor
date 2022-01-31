#
# CloudTrail: deliver all events from all regions
# to the S3 satellite bucket
#
resource "aws_cloudtrail" "satellite_trail" {
  name                          = "CbsSatelliteTrail"
  s3_bucket_name                = var.satellite_bucket_name
  s3_key_prefix                 = "cloudtrail_logs"
  include_global_service_events = true
  is_multi_region_trail         = true

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
