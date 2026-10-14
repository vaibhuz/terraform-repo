terraform {
  backend "s3" {
    bucket       = "backend-bucket-statefile321 "#backend-bucket-statefile321 
    key          = "terraform/vpc/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}