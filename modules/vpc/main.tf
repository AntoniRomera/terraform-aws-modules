###############################################################################
# VPC module
#
# Provisions a VPC with one public and one private subnet per supplied AZ.
# Subnet CIDRs are derived from the parent CIDR via cidrsubnet() so callers
# never hardcode subnet ranges. A shared (or per-AZ) NAT gateway provides
# egress for private subnets.
###############################################################################

locals {
  az_count = length(var.azs)

  # Newbits = 8 keeps a /16 -> /24 subnets; works for any reasonable parent CIDR.
  # Public subnets occupy the first block per AZ, private the next block, so the
  # two ranges never overlap.
  public_subnet_cidrs = [
    for idx in range(local.az_count) : cidrsubnet(var.cidr, 8, idx)
  ]
  private_subnet_cidrs = [
    for idx in range(local.az_count) : cidrsubnet(var.cidr, 8, idx + local.az_count)
  ]

  # When single_nat_gateway is true we create exactly one NAT; otherwise one per AZ.
  nat_gateway_count = var.single_nat_gateway ? 1 : local.az_count

  # Tags that let the AWS Load Balancer Controller / in-tree ELB discover subnets.
  eks_shared_tags = var.eks_cluster_name == null ? {} : {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
  eks_public_tags = var.eks_cluster_name == null ? {} : {
    "kubernetes.io/role/elb" = "1"
  }
  eks_private_tags = var.eks_cluster_name == null ? {} : {
    "kubernetes.io/role/internal-elb" = "1"
  }

  common_tags = merge(var.tags, { "ManagedBy" = "terraform", "Module" = "vpc" })
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(local.common_tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${var.name}-igw" })
}

###############################################################################
# Subnets
###############################################################################

resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    local.eks_shared_tags,
    local.eks_public_tags,
    {
      Name = "${var.name}-public-${var.azs[count.index]}"
      Tier = "public"
    },
  )
}

resource "aws_subnet" "private" {
  count = local.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    local.common_tags,
    local.eks_shared_tags,
    local.eks_private_tags,
    {
      Name = "${var.name}-private-${var.azs[count.index]}"
      Tier = "private"
    },
  )
}

###############################################################################
# NAT gateways (one Elastic IP per NAT)
###############################################################################

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(local.common_tags, { Name = "${var.name}-nat-eip-${count.index}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  # Place each NAT in a public subnet so it can reach the internet.
  subnet_id = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, { Name = "${var.name}-nat-${count.index}" })

  depends_on = [aws_internet_gateway.this]
}

###############################################################################
# Route tables
###############################################################################

# Public: single shared table routing 0.0.0.0/0 to the IGW.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private: one table per AZ so each can target its own (or the shared) NAT.
resource "aws_route_table" "private" {
  count = local.az_count

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${var.name}-private-rt-${var.azs[count.index]}" })
}

resource "aws_route" "private_nat" {
  count = local.az_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  # With a single shared NAT every private table targets index 0; otherwise the
  # NAT in the matching AZ.
  nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  count = local.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
