# Staging environment - partially hardened
# Note: .auto.tfvars files are automatically loaded

environment                   = "staging"
aws_region                    = "us-east-1"
cluster_name                  = "medvault-staging-eks"
cluster_version               = "1.28"
vpc_cidr                      = "10.1.0.0/16"

# Partial hardening
enable_encryption             = true
enable_versioning             = true
enable_vpc_flow_logs          = true
enable_cloudtrail             = false # Still disabled in staging
enable_eks_public_endpoint    = true
enable_lambda_vpc             = false
enable_kms_encryption         = true

rds_allocated_storage         = 100
rds_backup_retention_days     = 7
rds_multi_az                  = false

node_group_desired_size       = 3
node_group_min_size           = 2
node_group_max_size           = 8
node_instance_types           = ["t3.large"]

cloudwatch_log_retention_days = 30

tags = {
  Owner       = "platform-team"
  CostCenter  = "engineering"
  Environment = "staging"
  PHI         = "true"
  Compliance  = "partial"
}

s3_buckets = {
  staging_phi = {
    name           = "medvault-staging-phi"
    versioning     = true
    encryption     = true
    access_logging = true
    public_read    = false
    purpose        = "Staging PHI data"
  }
  staging_logs = {
    name           = "medvault-staging-logs"
    versioning     = true
    encryption     = true
    access_logging = false
    public_read    = false
    purpose        = "Staging application logs"
  }
}
