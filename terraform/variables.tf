variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "medvault-eks"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_encryption" {
  description = "Enable encryption for data stores"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable versioning for S3 buckets"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = false
}

variable "enable_eks_public_endpoint" {
  description = "Enable public endpoint for EKS cluster"
  type        = bool
  default     = true
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 100
}

variable "rds_backup_retention_days" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "enable_lambda_vpc" {
  description = "Enable VPC for Lambda functions"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default = {
    Owner      = "platform-team"
    CostCenter = "engineering"
  }
}

variable "s3_buckets" {
  description = "Map of S3 buckets to create"
  type = map(object({
    name              = string
    versioning        = bool
    encryption        = bool
    access_logging    = bool
    public_read       = bool
    purpose           = string
  }))
  default = {
    phi_storage = {
      name           = "medvault-phi-storage"
      versioning     = true
      encryption     = true
      access_logging = true
      public_read    = false
      purpose        = "PHI data storage"
    }
  }
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 10
}

variable "node_instance_types" {
  description = "Instance types for worker nodes"
  type        = list(string)
  default     = ["t3.large"]
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for services"
  type        = bool
  default     = true
}
