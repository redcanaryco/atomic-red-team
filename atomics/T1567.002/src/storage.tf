resource "random_string" "exfil_bucket_suffix" {
  length  = 16
  special = false
  upper   = false
  lower   = true
  numeric = true
}

resource "aws_s3_bucket" "exfil_bucket" {
  bucket        = "exfil-bucket-${random_string.exfil_bucket_suffix.result}"
  force_destroy = true
}
