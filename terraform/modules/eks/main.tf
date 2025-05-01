module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      desired_size   = var.desired_size
      min_size       = 1
      max_size       = 5
      capacity_type  = "ON_DEMAND"
      tags = {
        Purpose = "spark-demo"
      }
    }
  }

  enable_irsa = true

  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  cluster_endpoint_private_access      = true

  # grant the IAM principal running Terraform full “system:masters” access
  enable_cluster_creator_admin_permissions = true
}

output "cluster_oidc_issuer_url" {
  value = module.eks.oidc_provider
}