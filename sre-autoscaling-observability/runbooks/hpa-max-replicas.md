# Runbook: HPA at Maximum Replicas

**Alert:** `HPAAtMaxReplicas` | **Severity:** Warning | **Threshold:** Max replicas for 10m

## Steps
```bash
kubectl describe hpa sre-app-hpa -n sre-app
kubectl top pods -n sre-app

# Temporary: increase max replicas
kubectl patch hpa sre-app-hpa -n sre-app -p '{"spec":{"maxReplicas":15}}'

# Scale GKE node pool if needed
gcloud container clusters resize sre-autoscaling-cluster \
  --node-pool sre-autoscaling-cluster-node-pool \
  --num-nodes 4 --zone europe-west1-b
```
