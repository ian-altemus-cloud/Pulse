terraform {
  backend "s3" {
    bucket         = "pulse-tf-state-dev-894943009636"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "pulse-terraform-locks-dev"
    encrypt        = true
  }
}
