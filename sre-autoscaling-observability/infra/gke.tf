resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-nodes-sa"
  display_name = "GKE Node Service Account"
}

resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader"
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_container_cluster" "main" {
  name     = var.cluster_name
  location = var.zone

  # We manage node pools separately
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.main.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  depends_on = [google_project_service.apis]
}

resource "google_container_node_pool" "main" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.main.name

  # FREE TIER: e2-micro is always free (1 per region)
  # For a working cluster we use e2-small — still cheap
  # Destroy after testing to avoid charges
  node_count = 2

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  node_config {
    machine_type    = "e2-small"
    disk_size_gb    = 20
    disk_type       = "pd-standard"
    service_account = google_service_account.gke_nodes.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = var.environment
      project     = "sre-autoscaling"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
