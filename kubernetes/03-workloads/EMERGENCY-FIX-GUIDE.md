# 🚨 IMMEDIATE REAL-TIME FIX COMMANDS

## ⚡ EMERGENCY COMMANDS (Run these NOW!)

### 1. Check Current Status
```bash
kubectl get pods -l app=web-app -o wide
kubectl get deployment web-app-deployment
```

### 2. Quick Diagnosis
```bash
# Check one crashing pod logs
CRASH_POD=$(kubectl get pods -l app=web-app --field-selector=status.phase!=Running -o jsonpath='{.items[0].metadata.name}')
echo "Checking pod: $CRASH_POD"

# Check init container logs
kubectl logs $CRASH_POD -c init-config

# Check main container logs  
kubectl logs $CRASH_POD -c web-app
```

### 3. Apply Fix IMMEDIATELY
```bash
# Apply the corrected deployment
kubectl apply -f deployment-advanced.yaml

# Force delete crashing pods (they will be recreated with new config)
kubectl delete pods -l app=web-app --field-selector=status.phase!=Running --grace-period=0 --force
```

### 4. Monitor Recovery in Real-Time
```bash
# Watch pods recover
kubectl get pods -l app=web-app -w

# In another terminal, check rollout status
kubectl rollout status deployment/web-app-deployment --watch
```

---

## 🔧 STEP-BY-STEP EMERGENCY PROCEDURE

### Step 1: Immediate Diagnosis (30 seconds)
```bash
# Get overview
kubectl get pods -l app=web-app
kubectl describe deployment web-app-deployment | grep -A 5 "Conditions:"

# Quick log check for errors
kubectl logs -l app=web-app -c web-app --tail=5 | grep -i error
```

### Step 2: Apply Fix (10 seconds)
```bash
kubectl apply -f deployment-advanced.yaml
```

### Step 3: Force Pod Recreation (20 seconds)
```bash
# Delete all non-running pods
kubectl get pods -l app=web-app --no-headers | grep -v "Running" | awk '{print $1}' | xargs kubectl delete pod --grace-period=0 --force

# OR delete all pods to start fresh
kubectl delete pods -l app=web-app --grace-period=0 --force
```

### Step 4: Monitor Progress (2-3 minutes)
```bash
# Watch until all pods are Running and Ready
kubectl get pods -l app=web-app -w
```

### Step 5: Validate Fix (30 seconds)
```bash
# Check pod status
kubectl get pods -l app=web-app

# Test nginx config in one pod
POD_NAME=$(kubectl get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -c web-app -- nginx -t

# Test health endpoint
kubectl exec $POD_NAME -c web-app -- curl localhost/health
```

---

## 🚨 AUTOMATED EMERGENCY SCRIPT

**Just run this for complete automated fix:**
```powershell
.\emergency-fix.ps1
```

This script will:
- ✅ Diagnose the problem in real-time
- ✅ Apply the appropriate fix
- ✅ Monitor recovery progress
- ✅ Validate the solution
- ✅ Provide next steps

---

## 🎯 EXPECTED TIMELINE

| Step | Time | Expected Result |
|------|------|----------------|
| Diagnosis | 30s | Identify nginx config issue |
| Apply Fix | 10s | Deployment updated |
| Pod Deletion | 20s | Failed pods removed |
| Pod Recreation | 60-120s | New pods starting |
| Health Checks | 30-60s | Probes passing |
| **TOTAL** | **2-4 minutes** | All pods Running & Ready |

---

## ✅ SUCCESS INDICATORS

You'll know it's fixed when you see:
```bash
$ kubectl get pods -l app=web-app
NAME                                  READY   STATUS    RESTARTS   AGE
web-app-deployment-xxx-abc           2/2     Running   0          2m
web-app-deployment-xxx-def           2/2     Running   0          2m
web-app-deployment-xxx-ghi           2/2     Running   0          2m
web-app-deployment-xxx-jkl           2/2     Running   0          2m
web-app-deployment-xxx-mno           2/2     Running   0          2m
```

**Key Success Metrics:**
- ✅ STATUS: `Running`
- ✅ READY: `2/2`
- ✅ RESTARTS: `0` or low number
- ✅ All 5 pods healthy

---

## 🚨 IF PROBLEMS PERSIST

### Check Resources:
```bash
kubectl describe nodes | grep -A 3 "Allocated resources"
kubectl top nodes
```

### Scale Down Temporarily:
```bash
kubectl scale deployment web-app-deployment --replicas=2
```

### Check Events:
```bash
kubectl get events --sort-by=.metadata.creationTimestamp | tail -10
```

### Ultimate Fallback:
```bash
# Delete and recreate deployment
kubectl delete deployment web-app-deployment
kubectl apply -f deployment-advanced.yaml
```

---

## 💡 ROOT CAUSE

The issue was in the init container nginx configuration:
- ❌ **Wrong**: `echo "server_name web-app;" > /shared/nginx.conf`  
- ✅ **Fixed**: Proper server block with complete nginx config

The fix creates a valid nginx configuration with:
- Proper server block structure
- Health endpoint for probes  
- Complete nginx directives

---

**🎯 RUN THIS NOW FOR IMMEDIATE FIX:**
```powershell
.\emergency-fix.ps1
```
