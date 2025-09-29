module "vpc" {

    # Using my custom VPC module from GitHub
    source = "git::https://github.com/Tarique-B-DevOps/Terraform-AWS-VPC-EKS.git//modules/vpc?ref=main"
    vpc_cidr              = var.vpc_cidr
    public_subnets        = var.public_subnets
    private_subnets       = var.private_subnets
    provision_nat_gateway = var.provision_nat_gateway
    environment           = var.environment
  
}