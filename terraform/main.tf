#########################################################
# 0.  Provider (default_tags)
#########################################################
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "IcebergDemo"
      Owner       = "JD-ID"
      Environment = var.env
    }
  }
}

#########################################################
# 1.  Network (VPC, subnets, NAT)
#########################################################
module "network" {
  source   = "./modules/network"
  env      = var.env
  vpc_cidr = var.vpc_cidr
}

#########################################################
# 2.  EKS cluster + managed node group
#########################################################
module "eks" {
  source             = "./modules/eks"
  env                = var.env
  cluster_name       = var.cluster_name
  subnet_ids         = module.network.private_subnet_ids
  vpc_id             = module.network.vpc_id
  node_instance_type = "t3.medium"
  desired_size       = 3
}

#########################################################
# 3.  S3 buckets
#########################################################
module "s3_raw" {
  source      = "./modules/s3"
  bucket_name = "iceberg-demo-raw-${var.env}"
  versioning  = true
}

module "s3_warehouse" {
  source      = "./modules/s3"
  bucket_name = "iceberg-demo-warehouse-${var.env}"
  versioning  = true
}

#########################################################
# 4.  RDS Postgres for Hive Metastore
#########################################################
#module "rds_postgres" {
#  source                = "./modules/rds_postgres"
#  env                   = var.env
#  db_instance_class     = "db.t3.micro"
#  db_username           = var.db_username
#  db_password           = var.db_password
#  private_subnet_ids    = module.network.private_subnet_ids
#  vpc_id                = module.network.vpc_id
#}

#########################################################
# 5.  IAM role for ServiceAccount (IRSA) – Spark pods
#########################################################
module "iam_irsa" {
  source          = "./modules/iam_irsa"
  env             = var.env
  oidc_provider_arn = module.eks.oidc_provider_arn
  s3_buckets      = [
    module.s3_raw.bucket_arn,
    module.s3_warehouse.bucket_arn
  ]
}

#########################################################
# 6.  Outputs (handy for scripts)
#########################################################
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "raw_bucket_name" {
  value = module.s3_raw.bucket_name
}

output "warehouse_bucket_name" {
  value = module.s3_warehouse.bucket_name
}


# ARN of the OIDC provider created for EKS (for IRSA)
output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

# IAM role ARN of the Spark service account (from iam_irsa module)
output "spark_sa_role_arn" {
  value = module.iam_irsa.spark_role_arn
}
