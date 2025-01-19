terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.82.2"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region

  default_tags {
    tags = {
      AtomicTest = "T1648-1"
    }
  }
}

locals {
  cloud = length(regexall("-gov-", var.region)) > 0 ? "aws-us-gov" : length(regexall("-cn-", var.region)) > 0 ? "aws-cn" : "aws"
}
