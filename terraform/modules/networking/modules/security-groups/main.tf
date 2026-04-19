# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name        = "${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-eks-cluster-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_from_nodes" {
  security_group_id = aws_security_group.eks_cluster.id

  description                   = "Allow traffic from worker nodes"
  from_port                      = 443
  to_port                        = 443
  ip_protocol                    = "tcp"
  referenced_security_group_id   = aws_security_group.eks_nodes.id
}

# EKS Node Security Group
resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-eks-nodes-sg"
    }
  )
}

# Allow nodes to communicate with cluster
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_from_cluster" {
  security_group_id = aws_security_group.eks_nodes.id

  description                   = "Allow traffic from EKS cluster"
  from_port                      = 443
  to_port                        = 443
  ip_protocol                    = "tcp"
  referenced_security_group_id   = aws_security_group.eks_cluster.id
}

# Allow nodes to communicate with each other
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_from_nodes" {
  security_group_id = aws_security_group.eks_nodes.id

  description              = "Allow traffic between nodes"
  from_port                = 0
  to_port                  = 65535
  ip_protocol              = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# VIOLATION: Pattern 5 - Allow SSH from anywhere (0.0.0.0/0 on port 22)
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_ssh" {
  security_group_id = aws_security_group.eks_nodes.id

  description = "Allow SSH from anywhere - TODO: Restrict to bastion host"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "allow-ssh-anywhere"
  }
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-alb-sg"
    }
  )
}

# Allow HTTP/HTTPS from anywhere to ALB
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  description = "Allow HTTP from anywhere"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  description = "Allow HTTPS from anywhere"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

# VIOLATION: Pattern 6 - Allow RDP from anywhere (0.0.0.0/0 on port 3389)
resource "aws_vpc_security_group_ingress_rule" "alb_rdp" {
  security_group_id = aws_security_group.alb.id

  description = "Allow RDP from anywhere - FIXME: Remove or restrict"
  from_port   = 3389
  to_port     = 3389
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

# Allow ALB to communicate with nodes
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_from_alb" {
  security_group_id = aws_security_group.eks_nodes.id

  description              = "Allow traffic from ALB"
  from_port                = 0
  to_port                  = 65535
  ip_protocol              = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

# Egress rules (allow all outbound)
resource "aws_vpc_security_group_egress_rule" "eks_cluster_egress" {
  security_group_id = aws_security_group.eks_cluster.id

  description = "Allow all outbound traffic"
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "eks_nodes_egress" {
  security_group_id = aws_security_group.eks_nodes.id

  description = "Allow all outbound traffic"
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id

  description = "Allow all outbound traffic"
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-rds-sg"
    }
  )
}

# Allow connections from EKS nodes to RDS
resource "aws_vpc_security_group_ingress_rule" "rds_from_nodes" {
  security_group_id = aws_security_group.rds.id

  description              = "Allow PostgreSQL from EKS nodes"
  from_port                = 5432
  to_port                  = 5432
  ip_protocol              = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# RDS egress
resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  security_group_id = aws_security_group.rds.id

  description = "Allow all outbound traffic"
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# Lambda Security Group
resource "aws_security_group" "lambda" {
  name        = "${var.environment}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-lambda-sg"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "lambda_egress" {
  security_group_id = aws_security_group.lambda.id

  description = "Allow all outbound traffic"
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ElastiCache Security Group
resource "aws_security_group" "elasticache" {
  name        = "${var.environment}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-elasticache-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "elasticache_from_nodes" {
  security_group_id = aws_security_group.elasticache.id

  description              = "Allow Redis from EKS nodes"
  from_port                = 6379
  to_port                  = 6379
  ip_protocol              = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_egress_rule" "elasticache_egress" {
  security_group_id = aws_security_group.elasticache.id

  description = "Allow all outbound traffic"
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
