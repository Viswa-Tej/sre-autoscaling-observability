# SRE Auto-Scaling Observability — GKE Edition


A production-grade SRE project demonstrating auto-scaling, full-stack observability, SLO monitoring, and GitOps CI/CD on **Google Kubernetes Engine (GCP)** — fully within the GCP free tier / $300 credit.

---

## Architecture

```
GitHub Push
    │
    ▼
GitHub Actions ──► Unit Tests ──► Docker Build ──► Artifact Registry
                                                          │
                                                          ▼
                                              GKE Cluster (europe-west1)
                                              ├── sre-app pods (HPA: 2–10)
                                              ├── Prometheus (scrapes /metrics)
                                              └── Grafana (SLO dashboards)
```

## Tech Stack

| Layer | Tool |
|---|---|
| Cloud | GCP (GKE, Artifact Registry, VPC, Cloud NAT) |
| IaC | Terraform (remote state on Terraform Cloud) |
| Container | Docker, Artifact Registry |
| Orchestration | Kubernetes (GKE), HPA |
| CI/CD | GitHub Actions + Workload Identity Federation |
| Observability | Prometheus, Grafana |
| Alerting | PrometheusRule (5 alert rules) |
| App | Python Flask + prometheus_client |

---

## Repository Structure

```
├── app/
│   ├── app.py              # Flask app with /metrics, /health, /stress, /error
│   ├── Dockerfile          # Non-root, gunicorn, healthcheck
│   ├── requirements.txt
│   └── tests/test_app.py   # Pytest unit tests
├── infra/
│   ├── main.tf             # Provider, backend
│   ├── variables.tf
│   ├── vpc.tf              # VPC, subnets, Cloud NAT
│   ├── gke.tf              # GKE cluster + node pool + service account
│   ├── artifact_registry.tf
│   └── outputs.tf
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml     # Rolling update, resource limits
│   ├── service.yaml
│   ├── ingress.yaml        # GCE load balancer
│   ├── hpa.yaml            # CPU + memory based scaling (2–10 replicas)
│   └── servicemonitor.yaml # Prometheus auto-discovery
├── monitoring/
│   ├── alerts/alerts.yaml  # 5 PrometheusRule alerts with runbook links
│   └── dashboards/slo-dashboard.json  # Grafana: SLO, error budget, HPA
├── runbooks/
│   ├── high-error-rate.md
│   ├── pod-crash-loop.md
│   └── hpa-max-replicas.md
└── .github/workflows/
    └── deploy.yml          # Test → Build → Push → Deploy → Verify
```

---

## Getting Started

### Prerequisites
- GCP account (free tier or $300 credit)
- `gcloud` CLI installed
- `terraform` CLI installed
- `kubectl` installed

### 1. GCP Setup
```bash
# Install gcloud CLI (Windows)
winget install Google.CloudSDK

# Authenticate
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Enable APIs (Terraform does this too, but handy to do manually first)
gcloud services enable container.googleapis.com artifactregistry.googleapis.com
```

### 2. Provision Infrastructure
```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and add your GCP project ID

terraform init
terraform plan
terraform apply
```

### 3. Connect to GKE
```bash
# Command is in terraform output
gcloud container clusters get-credentials sre-autoscaling-cluster \
  --zone europe-west1-b --project YOUR_PROJECT_ID

kubectl get nodes
```

### 4. Install Observability Stack
```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin123

# Apply your app's ServiceMonitor and alert rules
kubectl apply -f monitoring/alerts/alerts.yaml
kubectl apply -f k8s/servicemonitor.yaml
```

### 5. Deploy the App
```bash
# Update the image placeholder in deployment.yaml with your registry URL
# Then apply
kubectl apply -f k8s/
kubectl get pods -n sre-app
kubectl get hpa -n sre-app
```

### 6. Access Grafana
```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
# Open http://localhost:3000 — admin / admin123
# Import monitoring/dashboards/slo-dashboard.json
```

### 7. Trigger HPA Scale-Up
```bash
# Start load test in a separate terminal
kubectl run load-test --image=busybox -it --rm -- \
  /bin/sh -c "while true; do wget -q -O- http://sre-app-svc.sre-app/stress; done"

# Watch HPA scale in another terminal
kubectl get hpa sre-app-hpa -n sre-app -w
```

---

## SLO Definition

| SLI | SLO Target |
|---|---|
| Availability (non-5xx / total) | 99.9% over 30 days |
| P95 Latency | < 1.0s |
| Error budget burn rate | < 5% per 5 minutes |

---

## GitHub Actions Setup

Add these secrets to your GitHub repo (Settings → Secrets):

| Secret | Value |
|---|---|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `WIF_PROVIDER` | Workload Identity Provider resource name |
| `WIF_SERVICE_ACCOUNT` | Service account email for GH Actions |

---

## Cost Control

This project is designed to stay within GCP's free tier / $300 credit.

```bash
# Destroy everything when not actively working
cd infra && terraform destroy
```

**Estimated cost:** ~$0 with $300 credit. GKE autopilot or e2-small nodes 
for a few hours of testing costs cents.

---

## What I Built & Learned

- Provisioned GKE cluster with private nodes and Cloud NAT using Terraform
- Implemented HPA scaling on CPU + memory — tested with synthetic load
- Deployed Prometheus with ServiceMonitor for automatic scraping of custom metrics
- Built Grafana dashboard tracking SLIs (error rate, latency P50/P95/P99, availability)
- Defined SLOs with PromQL recording rules for error budget burn rate
- Wrote 5 alert rules with runbook links — mirrors real on-call SRE workflows
- Set up GitHub Actions CI/CD with Workload Identity Federation (no stored credentials)
