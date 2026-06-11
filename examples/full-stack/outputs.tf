output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_autoscaler_role_arn" {
  description = "IRSA role ARN for the cluster autoscaler."
  value       = module.eks.cluster_autoscaler_role_arn
}

output "rds_endpoint" {
  description = "RDS connection endpoint."
  value       = module.rds.endpoint
}

output "rds_password" {
  description = "RDS master password (sensitive)."
  value       = module.rds.password
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to update your local kubeconfig for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
