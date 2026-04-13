terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  # Free: Terraform Cloud backend (1 user, free forever)
  # Sign up at app.terraform.io, create org + workspace, fill in below
  backend "remote" {
    organization = "YOUR_TF_CLOUD_ORG"
    workspaces {
      name = "sre-autoscaling-gcp"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required GCP APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ])
  service            = each.value
  disable_on_destroy = false
}
