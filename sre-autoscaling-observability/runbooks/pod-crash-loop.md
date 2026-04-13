# Runbook: Pod Crash Loop

**Alert:** `PodCrashLooping` | **Severity:** Critical | **Threshold:** >3 restarts in 15m

## Steps
```bash
kubectl get pods -n sre-app
kubectl describe pod <pod-name> -n sre-app
kubectl logs <pod-name> -n sre-app --previous

# Rollback if bad image
kubectl rollout undo deployment/sre-app -n sre-app
```

## Common Causes
- **OOMKilled** → increase memory limits in deployment.yaml
- **Liveness probe failing** → increase `initialDelaySeconds`
- **Bad image** → rollback deployment
