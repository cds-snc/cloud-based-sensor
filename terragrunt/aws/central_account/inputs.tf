variable "cbs_principal_arn" {
  description = "ARN of the CBS principal that reads objects from the log archive bucket"
  type        = string
  sensitive   = true
}

variable "cbs_transport_lambda_name" {
  description = "Name of the CBS transport Lambda function"
  type        = string
}
