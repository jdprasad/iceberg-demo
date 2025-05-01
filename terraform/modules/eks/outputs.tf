output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider (for IRSA)"
  value       = module.eks.oidc_provider_arn
}
