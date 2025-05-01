variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "node_instance_type" {
  description = "EC2 instance type for managed nodes"
  type        = string
}

variable "desired_size" {
  description = "Desired number of nodes in the managed node group"
  type        = number
}

# (Optional) If you ever pass `env` or `tags` through, declare them too:
variable "env" {
  description = "Environment name (e.g. demo, prod)"
  type        = string
}

variable "tags" {
  description = "Extra tags to apply"
  type        = map(string)
  default     = {}
}
