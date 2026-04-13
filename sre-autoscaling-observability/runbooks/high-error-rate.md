# Runbook: High Error Rate

**Alert:** `HighErrorRate` | **Severity:** Critical | **Threshold:** >5% errors for 5m

## Steps
```bash
# 1. Check pods
kubectl get pods -n sre-app
kubectl logs -n sre-app -l app=sre-app --tail=50

# 2. Check recent deploys
kubectl rollout history deployment/sre-app -n sre-app

# 3. Rollback if bad deploy
kubectl rollout undo deployment/sre-app -n sre-app
kubectl rollout status deployment/sre-app -n sre-app

# 4. Manual scale if resource exhaustion
kubectl scale deployment sre-app --replicas=5 -n sre-app
```

## PromQL
```promql
sum(rate(http_requests_total{status_code=~"5.."}[5m])) by (endpoint)
```
