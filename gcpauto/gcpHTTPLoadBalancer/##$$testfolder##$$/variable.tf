variable "project_id" {
  description = "The project ID to deploy the resources."
  type        = string
}

variable "region" {
  description = "The region where resources are deployed."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone where instances are deployed."
  type        = string
  default     = "us-central1-a"
}

variable "credentials" { }

variable "resource_name_prefix" {
  description = "Prefix for the resource names to ensure uniqueness."
  type        = string
  default     = "gcpauto"
}

