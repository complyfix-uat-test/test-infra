# Development environment - relaxed security, intentional violations

environment                   = "dev"
aws_region                    = "us-east-1"
cluster_name                  = "medvault-dev-eks"
cluster_version               = "1.28"
vpc_cidr                      = "10.0.0.0/16"

# VIOLATION: Variable precedence - override default encryption = true
enable_encryption             = false
enable_versioning             = false
enable_vpc_flow_logs          = false
enable_cloudtrail             = false
enable_eks_public_endpoint    = true
enable_lambda_vpc             = false
enable_kms_encryption         = false

rds_allocated_storage         = 50
rds_backup_retention_days     = 0
rds_multi_az                  = false

node_group_desired_size       = 2
node_group_min_size           = 1
node_group_max_size           = 5
node_instance_types           = ["t3.medium"]

cloudwatch_log_retention_days = 1

tags = {
  Owner       = "platform-team"
  CostCenter  = "engineering"
  Environment = "development"
  PHI         = "false"
}

s3_buckets = {
  dev_code = {
    name           = "medvault-dev-code"
    versioning     = false
    encryption     = false
    access_logging = false
    public_read    = false
    purpose        = "Development code artifacts"
  }
  dev_temp = {
    name           = "medvault-dev-temp"
    versioning     = false
    encryption     = false
    access_logging = false
    public_read    = true
    purpose        = "Temporary development data"
  }
  dev_logs = {
    name           = "medvault-dev-logs"
    versioning     = false
    encryption     = false
    access_logging = false
    public_read    = false
    purpose        = "Development logs"
  }
}
