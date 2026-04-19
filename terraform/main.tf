locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Terraform   = "true"
      Timestamp   = formatdate("YYYY-MM-DD", timestamp())
    }
  )

  private_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  public_subnet_cidrs = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]

  region_to_nat_count = {
    "us-east-1" = 3
    "us-west-2" = 2
  }

  nat_gateway_count = lookup(local.region_to_nat_count, var.aws_region, 1)

  s3_buckets_expanded = merge(
    var.s3_buckets,
    var.environment == "prod" ? {
      prod_backup = {
        name           = "medvault-prod-backup"
        versioning     = true
        encryption     = true
        access_logging = true
        public_read    = false
        purpose        = "Production backups"
      }
    } : {}
  )
}

# Networking module
module "networking" {
  source = "./modules/networking"

  environment       = var.environment
  vpc_cidr          = var.vpc_cidr
  cluster_name      = var.cluster_name
  enable_flow_logs  = var.enable_vpc_flow_logs
  private_subnets  = local.private_subnet_cidrs
  public_subnets   = local.public_subnet_cidrs
  nat_gateway_count = local.nat_gateway_count

  tags = local.common_tags

  depends_on = [data.aws_caller_identity.current]
}

# EKS cluster module
module "eks" {
  source = "./modules/eks"

  environment              = var.environment
  cluster_name             = var.cluster_name
  cluster_version          = var.cluster_version
  vpc_id                   = module.networking.vpc_id
  private_subnets          = module.networking.private_subnet_ids
  endpoint_private_access  = true
  endpoint_public_access   = var.enable_eks_public_endpoint
  enable_audit_logging     = false # VIOLATION: Pattern 29

  node_group_desired_size = var.node_group_desired_size
  node_group_min_size     = var.node_group_min_size
  node_group_max_size     = var.node_group_max_size
  node_instance_types     = var.node_instance_types

  tags = local.common_tags

  depends_on = [module.networking]
}

# Data stores module
module "data_stores" {
  source = "./modules/data-stores"

  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  private_subnets           = module.networking.private_subnet_ids
  enable_encryption          = var.enable_encryption
  enable_versioning          = var.enable_versioning
  s3_buckets                 = local.s3_buckets_expanded
  rds_allocated_storage      = var.rds_allocated_storage
  rds_backup_retention_days  = var.rds_backup_retention_days
  rds_multi_az               = var.rds_multi_az
  cloudwatch_log_retention   = var.cloudwatch_log_retention_days

  tags = local.common_tags

  depends_on = [module.networking]
}

# Security module (IAM, KMS, CloudTrail)
module "security" {
  source = "./modules/security"

  environment         = var.environment
  cluster_name        = var.cluster_name
  cluster_oidc_url    = module.eks.oidc_provider_url
  enable_cloudtrail   = var.enable_cloudtrail
  enable_kms          = var.enable_kms_encryption
  s3_bucket_name      = var.environment == "prod" ? module.data_stores.audit_bucket_name : ""
  account_id          = data.aws_caller_identity.current.account_id

  tags = local.common_tags

  depends_on = [module.eks, module.data_stores]
}

# Compute module (Lambda, ALB, ECR)
module "compute" {
  source = "./modules/compute"

  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  private_subnets      = module.networking.private_subnet_ids
  enable_lambda_vpc    = var.enable_lambda_vpc
  cluster_security_group_id = module.eks.cluster_security_group_id

  tags = local.common_tags

  depends_on = [module.networking, module.security]
}

# Monitoring module (CloudWatch, SNS, Alarms)
module "monitoring" {
  source = "./modules/monitoring"

  environment                = var.environment
  cluster_name               = var.cluster_name
  log_retention_days         = var.cloudwatch_log_retention_days
  rds_instance_id            = module.data_stores.rds_instance_id
  enable_kms_encryption      = var.enable_kms_encryption
  kms_key_id                 = module.security.kms_key_id

  tags = local.common_tags

  depends_on = [module.data_stores, module.security]
}
