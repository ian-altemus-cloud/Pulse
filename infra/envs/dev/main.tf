terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../modules/vpc"

  project_name         = "pulse"
  environment          = "dev"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "ecs" {
  source = "../../modules/ecs-service"

  project_name          = "pulse"
  environment           = "dev"
  aws_region            = "us-east-1"
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.vpc.alb_security_group_id
  ecs_security_group_id = module.vpc.ecs_security_group_id
  container_image       = "894943009636.dkr.ecr.us-east-1.amazonaws.com/pulse:v1.0.1"
  desired_count         = 1
}

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name     = "pulse"
  environment      = "dev"
  alert_email      = var.alert_email
  health_endpoint  = "http://${module.ecs.alb_dns_name}/health"
  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_service_name = module.ecs.ecs_service_name
}