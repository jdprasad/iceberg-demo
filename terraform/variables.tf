###########  Root‑level variables  ###########
variable "env" {
  description = "Environment suffix for resource names (demo, prod, etc.)"
  type        = string
  default     = "demo"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "iceberg-demo-eks"
}

# Optional convenience tag map
variable "tags" {
  description = "Extra AWS resource tags to apply via var.tags + provider.default_tags"
  type        = map(string)
  default     = {}
}

# RDS creds – you can leave these as null and use TF Cloud/TFVars/Secrets Manager later
variable "db_username" {
  type        = string
  default     = "hms"
}

variable "db_password" {
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}


variable "s3_buckets" {
  description = "ARNs of the S3 buckets Spark needs to read/write"
  type        = list(string)
}

##############################################