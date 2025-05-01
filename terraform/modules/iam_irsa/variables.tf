variable "env" {
  description = "Environment name for resource suffix"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IRSA"
  type        = string
}

variable "s3_buckets" {
  description = "List of S3 bucket ARNs that Spark pods need access to"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}