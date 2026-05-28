variable "project" {
  description = "Project"
  default     = "retail-demand-pipeline"
}

variable "region" {
  description = "Region"
  default     = "europe-west9"
}

variable "location" {
  description = "Project Location"
  default     = "EU"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "retail_demand_pl_dataset"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "retail-demand-pl-bronze"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}
