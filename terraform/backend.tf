terraform {
  backend "s3" {
    bucket           = "medvault-terraform-state"
    key              = "prod/terraform.tfstate"
    region           = "us-east-1"
    encrypt          = true
    dynamodb_table   = "terraform-locks"
    skip_credentials_validation = false
    skip_metadata_api_check      = false
  }
}
