variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_oidc_url" {
  description = "OIDC provider URL for EKS cluster"
  type        = string
  default     = ""
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = false
}

variable "enable_kms" {
  description = "Enable KMS encryption"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "S3 bucket for CloudTrail logs"
  type        = string
  default     = ""
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
