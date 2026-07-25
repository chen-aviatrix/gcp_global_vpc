terraform {
  required_version = ">= 1.5"

  required_providers {
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "~> 3.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aviatrix" {
  controller_ip           = var.controller_ip
  username                = "admin"
  password                = var.controller_password
  skip_version_validation = true
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_west_1"
  region = "us-west-1"
}

provider "google" {
  project = var.gcp_project_id
  credentials = file(var.gcp_credentials_file)
}
