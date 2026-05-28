terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.34.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_storage_bucket" "retail-gcs-bucket" {
  name                        = var.gcs_bucket_name
  location                    = var.location
  force_destroy               = true
  storage_class               = var.gcs_storage_class
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "retail-bq-dataset" {
  dataset_id                 = var.bq_dataset_name
  description                = "bq dataset for retail demand pipeline"
  location                   = var.location
  delete_contents_on_destroy = true
}
