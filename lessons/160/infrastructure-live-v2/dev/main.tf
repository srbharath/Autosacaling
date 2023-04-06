provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "local" {
    path = "dev/vpc/terraform.tfstate"
  }
}

module "vpc" {
  source = "../../infrastructure-modules/vpc"

  env = "dev"
}
