# Production environment - mostly hardened but still has gaps
# Note: .auto.tfvars files are automatically loaded by Terraform

environment                   = "prod"
aws_region                    = "us-east-1"
cluster_name                  = "medvault-prod-eks"
cluster_version               = "1.28"
vpc_cidr                      = "10.2.0.0/16"

# Production settings - but still some violations exist in resource definitions
enable_encryption             = true
enable_versioning             = true
enable_vpc_flow_logs          = true
enable_cloudtrail             = false # VIOLATION: CloudTrail still disabled in production!
enable_eks_public_endpoint    = false # More restrictive
enable_lambda_vpc             = true
enable_kms_encryption         = true

rds_allocated_storage         = 500
rds_backup_retention_days     = 30 # Good retention
rds_multi_az                  = false # VIOLATION: Pattern 19 - still no Multi-AZ

node_group_desired_size       = 5
node_group_min_size           = 3
node_group_max_size           = 20
node_instance_types           = ["t3.xlarge"]

cloudwatch_log_retention_days = 365

tags = {
  Owner       = "platform-team"
  CostCenter  = "operations"
  Environment = "production"
  PHI         = "true"
  Compliance  = "SOC2,HIPAA"
  DataClass   = "Critical"
  BackupPolicy = "Daily"
}

s3_buckets = {
  prod_phi_storage = {
    name           = "medvault-prod-phi-storage"
    versioning     = true
    encryption     = true
    access_logging = true
    public_read    = false
    purpose        = "Production PHI storage"
  }
  prod_backup = {
    name           = "medvault-prod-backup"
    versioning     = true
    encryption     = true
    access_logging = true
    public_read    = false
    purpose        = "Production backups"
  }
  prod_audit_logs = {
    name           = "medvault-prod-audit"
    versioning     = true
    encryption     = true
    access_logging = false
    public_read    = false
    purpose        = "Production audit logs"
  }
  prod_static_assets = {
    name           = "medvault-prod-assets"
    versioning     = true
    encryption     = true
    access_logging = true
    public_read    = false
    purpose        = "Static web assets"
  }
}
