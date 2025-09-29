terraform {
  cloud {

    organization = "tarique-b-devops"

    workspaces {
      name = "hppm-aws-ecs"
    }
  }

}

provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      var.tags,
      {
        "TF-Workspace" = terraform.workspace
      }
    )
  }
}