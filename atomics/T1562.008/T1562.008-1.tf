terraform {
  required_version = ">= 0.12"
}

provider "aws" {
}

resource "aws_s3_bucket" "some_bucket" {
}

resource "aws_cloudtrail" "some_cloudtrail" {
  s3_bucket_name = aws_s3_bucket.some_bucket.id
  name           = "some_cloudtrail"
}

