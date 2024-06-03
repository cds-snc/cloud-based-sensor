variable "cbs_principal_arn" {
  description = "ARN of the CBS principal that reads objects from the log archive bucket"
  type        = string
  sensitive   = true
}

variable "cbs_principal_role_arn" {
  description = "ARN of the CBS principal role that reads objects from the log archive bucket (used upon decommissioning of CBS v1.0)"
  type        = string
  sensitive   = true
}

variable "cbs_transport_lambda_name" {
  description = "Name of the CBS transport Lambda function"
  type        = string
}
