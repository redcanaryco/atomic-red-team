provider "google" {
}

variable "project_id" {
}

variable "bucket_name" {
}

variable "location" {
}


resource "google_storage_bucket" "bucket" {
  name     = var.bucket_name
  location = var.location
  project  = var.project_id
}
