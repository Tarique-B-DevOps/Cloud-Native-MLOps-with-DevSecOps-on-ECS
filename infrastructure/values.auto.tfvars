# Common Vars Values
tags = {
  "App"         = "price-prediction-model"
}

# VPC Vars Values
vpc_cidr = "10.0.0.0/16"

public_subnets = {
  "sub1" = {
    cidr_block        = "10.0.1.0/24"
    availability_zone = "ap-south-2a"

  },
  "sub2" = {
    cidr_block        = "10.0.2.0/24"
    availability_zone = "ap-south-2b"

  }
}

private_subnets = {
  "sub1" = {
    cidr_block        = "10.0.3.0/24"
    availability_zone = "ap-south-2a"
  },
  "sub2" = {
    cidr_block        = "10.0.4.0/24"
    availability_zone = "ap-south-2b"

  }
}

provision_nat_gateway = false