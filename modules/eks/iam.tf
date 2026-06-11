###############################################################################
# IAM for EKS
#
#  - cluster role: assumed by the EKS control plane
#  - node role:    assumed by EC2 worker nodes
#  - autoscaler:   IRSA role assumed by the cluster-autoscaler service account
###############################################################################

data "aws_partition" "current" {}

###############################################################################
# Control plane role
###############################################################################

data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

###############################################################################
# Worker node role
###############################################################################

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

###############################################################################
# Cluster Autoscaler IRSA role
#
# Trust policy is scoped to the specific service account via the OIDC provider's
# `:sub` condition so only kube-system:cluster-autoscaler can assume the role.
###############################################################################

locals {
  # Strip the https:// scheme to build the OIDC condition keys.
  oidc_provider_url = replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")
}

data "aws_iam_policy_document" "autoscaler_assume_role" {
  count = var.enable_cluster_autoscaler_irsa ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      # var is "namespace:name"; the OIDC subject format is
      # system:serviceaccount:<namespace>:<name>.
      values = ["system:serviceaccount:${var.cluster_autoscaler_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "autoscaler" {
  count = var.enable_cluster_autoscaler_irsa ? 1 : 0

  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.autoscaler_assume_role[0].json

  tags = local.common_tags
}

data "aws_iam_policy_document" "autoscaler" {
  count = var.enable_cluster_autoscaler_irsa ? 1 : 0

  # Read-only discovery actions can be unscoped (they take no specific resource).
  statement {
    sid    = "Describe"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup",
    ]
    resources = ["*"]
  }

  # Mutating actions are scoped to ASGs tagged for this cluster's autoscaler.
  statement {
    sid    = "Modify"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_role_policy" "autoscaler" {
  count = var.enable_cluster_autoscaler_irsa ? 1 : 0

  name   = "${var.cluster_name}-cluster-autoscaler"
  role   = aws_iam_role.autoscaler[0].id
  policy = data.aws_iam_policy_document.autoscaler[0].json
}
