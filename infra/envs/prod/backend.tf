terraform {
  backend "s3" {
    bucket         = "pulse-terraform-state-prod-894943009636"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "pulse-terraform-locks-prod"
    encrypt        = true
  }
}
