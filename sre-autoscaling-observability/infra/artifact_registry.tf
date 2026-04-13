# GCP Artifact Registry = equivalent of AWS ECR, free tier included
resource "google_artifact_registry_repository" "app" {
  location      = var.region
  repository_id = "sre-autoscaling-app"
  description   = "Docker images for SRE autoscaling app"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-last-10"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  depends_on = [google_project_service.apis]
}
