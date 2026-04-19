output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "security_group_ids" {
  description = "Security group IDs from nested module"
  value = {
    eks_cluster   = module.security_groups.eks_cluster_sg_id
    eks_nodes     = module.security_groups.eks_nodes_sg_id
    alb           = module.security_groups.alb_sg_id
    rds           = module.security_groups.rds_sg_id
  }
}
