variable "bucket_name" {
  description = "Name of the S3 bucket to create"
  type        = string
}

variable "versioning" {
  description = "Whether to enable versioning"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}
