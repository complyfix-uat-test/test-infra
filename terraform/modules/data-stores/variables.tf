variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
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
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 100
}

variable "rds_backup_retention_days" {
  description = "RDS backup retention period"
  type        = number
  default     = 7
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ"
  type        = bool
  default     = false
}

variable "cloudwatch_log_retention" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
