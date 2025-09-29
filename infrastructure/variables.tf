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