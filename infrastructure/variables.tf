variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "tags" {
  description = "default tags"
  type        = map(string)
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnet names to their CIDR blocks and availability zones"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnet names to their CIDR blocks and availability zones"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "provision_nat_gateway" {
  description = "Specify whether to provision and configure the NAT gateway for private subnets"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment (e.g., staging, production)"
  type        = string
}

# ECS

variable "launch_type" {
  description = "Define ECS compute launch type"
  type        = string
  default     = "FARGATE"

}

variable "model_image_uri" {
  description = "Provide the image URI to set in task definition"
  type        = string
  default     = "619140547673.dkr.ecr.ap-south-2.amazonaws.com/test-repo:latest"

}

variable "model_port" {
  description = "Provide the port."
  type        = number
  default     = 8888

}