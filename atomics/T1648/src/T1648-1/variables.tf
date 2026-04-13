variable "profile" {
  description = "The AWS profile to use"
  default     = "default"
}

variable "region" {
  description = "The AWS region to deploy to"
  default     = "us-east-2"
}

variable "instance_type" {
  description = "The instance type to use for the EC2 instance"
  default     = "t2.micro"
}
