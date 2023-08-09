provider "google" {
}

variable "project_id" {
}

variable "service_name" {
}

resource "google_service_account" "service_account" {
  account_id = var.service_name
  project    = var.project_id
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
