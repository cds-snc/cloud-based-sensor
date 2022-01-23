variable "cbs_principal_arn" {
  description = "ARN of the CBS principal that reads objects from the log archive bucket"
  type        = string
  sensitive   = true
}
