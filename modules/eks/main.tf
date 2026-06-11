###############################################################################
# EKS module
#
# Control plane + managed node groups + IRSA (OIDC provider) wiring.
# IAM roles and the cluster-autoscaler IRSA role live in iam.tf.
###############################################################################

locals {
  common_tags = merge(var.tags, { "ManagedBy" = "terraform", "Module" = "eks" })
}

###############################################################################
# Cluster security group rules
#
# EKS creates a managed cluster security group automatically; we add a rule so
# the control plane can reach node kubelets on the standard port range.
###############################################################################

resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for ${var.cluster_name} worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name                                        = "${var.cluster_name}-node-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

# Allow nodes to talk to each other (pod-to-pod across nodes).
resource "aws_security_group_rule" "node_to_node" {
  type                     = "ingress"
  description              = "Allow nodes to communicate with each other"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
}

# Allow the control plane (managed cluster SG) to reach node kubelets.
resource "aws_security_group_rule" "cluster_to_node" {
  type                     = "ingress"
  description              = "Allow control plane to reach node kubelets"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
}

# Nodes need egress to the internet (image pulls, AWS APIs) via NAT.
resource "aws_security_group_rule" "node_egress" {
  type              = "egress"
  description       = "Allow all egress from nodes"
  security_group_id = aws_security_group.node.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

###############################################################################
# Control plane
###############################################################################

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.public_access_cidrs
  }

  tags = merge(local.common_tags, { Name = var.cluster_name })

  # Ensure the cluster role policies are attached before the cluster is created
  # (otherwise EKS creation can fail with permission errors).
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

###############################################################################
# IRSA: OIDC identity provider
###############################################################################

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = merge(local.common_tags, { Name = "${var.cluster_name}-oidc" })
}

###############################################################################
# Managed node groups
###############################################################################

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size
  ami_type       = "AL2023_x86_64_STANDARD"

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = each.value.labels

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-${each.key}"
    # Cluster-autoscaler auto-discovery tags.
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]

  # Desired size drifts as the autoscaler scales the group; don't fight it.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
