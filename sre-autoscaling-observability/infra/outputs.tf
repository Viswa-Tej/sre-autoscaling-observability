output "cluster_name" {
  value = google_container_cluster.main.name
}

output "cluster_location" {
  value = google_container_cluster.main.location
}

output "registry_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/sre-autoscaling-app"
}

output "kubeconfig_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --zone ${var.zone} --project ${var.project_id}"
}

output "project_id" {
  value = var.project_id
}
