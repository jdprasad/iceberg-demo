###############################################################################
# Network – single call to terraform‑aws‑modules/vpc/aws
###############################################################################

locals {
  # Grab the first two AZs in the region for deterministic CIDR math
  availability_zones = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "${var.env}-vpc"
  cidr = var.vpc_cidr

  azs              = slice(local.availability_zones, 0, 2)
  public_subnets   = [cidrsubnet(var.vpc_cidr, 4, 0), cidrsubnet(var.vpc_cidr, 4, 1)]
  private_subnets  = [cidrsubnet(var.vpc_cidr, 4, 2), cidrsubnet(var.vpc_cidr, 4, 3)]

  enable_nat_gateway  = true
  single_nat_gateway  = true

  # Map public IPs on public subnets
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name   = "${var.env}-vpc"
    Purpose = "spark-demo"
  })
}

###########################
# Outputs for parent module
###########################

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}