# Configure the AWS provider
terraform {
  backend "s3" {
    profile = "default"
    region = "us-east-1"
    key = "terraform.tfstate"
    bucket = "terraform-tfstate-poc01"
  }
  required_version = ">=0.13"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.39.0"  #      version = "~> 3.0"
    }
   }
}
provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "k8-vpc"
  cidr = "10.60.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.60.1.0/24", "10.60.2.0/24", "10.60.3.0/24"]
  public_subnets  = ["10.60.101.0/24", "10.60.102.0/24", "10.60.103.0/24"]

  enable_nat_gateway = false
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}