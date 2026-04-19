bucket           = "medvault-terraform-state"
key              = "prod/terraform.tfstate"
region           = "us-east-1"
encrypt          = true
dynamodb_table   = "terraform-locks"
