output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint for the Kubernetes API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version running on the control plane."
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "ID of the EKS-managed cluster security group."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_security_group_id" {
  description = "ID of the worker node security group (use as source for downstream ingress, e.g. RDS)."
  value       = aws_security_group.node.id
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for IRSA."
  value       = aws_iam_openid_connect_provider.oidc.arn
}

output "oidc_provider_url" {
  description = "URL of the cluster OIDC issuer."
  value       = aws_iam_openid_connect_provider.oidc.url
}

output "node_role_arn" {
  description = "ARN of the IAM role attached to worker nodes."
  value       = aws_iam_role.node.arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the cluster-autoscaler IRSA role (null if disabled). Annotate the service account with this."
  value       = var.enable_cluster_autoscaler_irsa ? aws_iam_role.autoscaler[0].arn : null
}
