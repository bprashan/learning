# 🚀 Advanced Deployment Deep Dive

## 📖 Overview

The `deployment-advanced.yaml` demonstrates several advanced Kubernetes concepts:

1. **Init Containers** - Setup tasks before main containers start
2. **Multi-Container Pods** - Main app + sidecar monitoring
3. **Shared Volumes** - Data sharing between containers
4. **Health Probes** - Advanced health checking
5. **Resource Management** - CPU/Memory limits and requests
6. **Host Path Volumes** - Access to node filesystem

---

## 🔧 Init Containers Explained

### What are Init Containers?

Init containers are **specialized containers that run and complete before the main application containers start**. They're perfect for setup tasks, prerequisites, and initialization logic.

### Key Characteristics:
- ✅ **Run sequentially** - One after another, not in parallel
- ✅ **Must complete successfully** - If init container fails, pod restarts
- ✅ **Run every time** - Execute on every pod start/restart
- ✅ **Share volumes** - Can prepare data for main containers
- ✅ **Different images** - Can use specialized tools not in main app

### In Your deployment-advanced.yaml:
```yaml
initContainers:
- name: init-config
  image: busybox:1.35  # Lightweight utility container
  command: ['sh', '-c']
  args:
    - |
      echo "Setting up configuration..."
      echo "server_name web-app;" > /shared/nginx.conf
      echo "Configuration complete!"
  volumeMounts:
  - name: shared-config
    mountPath: /shared
```

**What this does:**
1. Uses BusyBox (lightweight Linux utilities)
2. Creates an nginx configuration file
3. Saves it to a shared volume
4. Main nginx container will use this config

---

## 🏗️ Multi-Container Pod Architecture

Your deployment uses the **sidecar pattern** with two main containers:

### 1. Main Application Container (`web-app`):
```yaml
containers:
- name: web-app
  image: nginx:1.21
  ports:
  - containerPort: 80
    name: http
```
**Purpose:** Serves the web application

### 2. Sidecar Monitoring Container (`monitoring-agent`):
```yaml
- name: monitoring-agent
  image: prom/node-exporter:latest
  ports:
  - containerPort: 9100
    name: metrics
```
**Purpose:** Collects and exposes system metrics

### Benefits of Multi-Container Pods:
- 🔄 **Shared Lifecycle** - Containers start/stop together
- 📡 **Shared Network** - Same IP, can communicate via localhost
- 💾 **Shared Volumes** - Data sharing between containers
- 🎯 **Single Responsibility** - Each container has a specific role

---

## 📊 Volume Types Used

### 1. EmptyDir Volume (Temporary Storage):
```yaml
volumes:
- name: shared-config
  emptyDir: {}
```
**Use Case:** Share configuration between init and main containers

### 2. HostPath Volumes (Node Access):
```yaml
volumes:
- name: proc
  hostPath:
    path: /proc
- name: sys
  hostPath:
    path: /sys
```
**Use Case:** Monitor node-level metrics (CPU, memory, disk)

---

## 🔍 Health Probes Configuration

### Liveness Probe:
```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 30  # Wait 30s before first check
  periodSeconds: 10        # Check every 10s
  timeoutSeconds: 5        # 5s timeout per check
  failureThreshold: 3      # Restart after 3 failures
```
**Purpose:** Restart container if it becomes unhealthy

### Readiness Probe:
```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 10  # Start checking after 10s
  periodSeconds: 5         # Check every 5s
  successThreshold: 1      # Ready after 1 success
  failureThreshold: 3      # Not ready after 3 failures
```
**Purpose:** Control traffic routing to the pod

---

## ✅ Validation Guide

### 1. Deploy the Advanced Application:
```bash
kubectl apply -f deployment-advanced.yaml
```

### 2. Monitor Deployment Progress:
```bash
# Watch overall deployment status
kubectl rollout status deployment/web-app-deployment

# Watch pods being created
kubectl get pods -l app=web-app -w
```

### 3. Validate Init Container Execution:
```bash
# Check if init containers completed
kubectl get pods -l app=web-app

# View init container logs
kubectl logs -l app=web-app -c init-config

# Expected output: "Setting up configuration..." and "Configuration complete!"
```

### 4. Verify Multi-Container Setup:
```bash
# List all containers in pods
kubectl get pods -l app=web-app -o jsonpath='{.items[*].spec.containers[*].name}'

# Should show: web-app monitoring-agent
```

### 5. Check Volume Mounts:
```bash
# Verify shared config was created
kubectl exec deployment/web-app-deployment -c web-app -- ls -la /etc/nginx/conf.d/

# Check config content
kubectl exec deployment/web-app-deployment -c web-app -- cat /etc/nginx/conf.d/nginx.conf
```

### 6. Test Health Probes:
```bash
# Check probe status
kubectl describe pods -l app=web-app | grep -A 5 "Conditions:"

# Verify containers are ready
kubectl get pods -l app=web-app -o wide
```

### 7. Validate Monitoring Sidecar:
```bash
# Check if monitoring port is accessible
kubectl port-forward deployment/web-app-deployment 9100:9100

# In another terminal, test metrics endpoint
curl http://localhost:9100/metrics
```

### 8. Resource Usage Validation:
```bash
# Check actual resource usage
kubectl top pods -l app=web-app

# Compare with requested/limit values
kubectl describe pods -l app=web-app | grep -A 10 "Requests:"
```

---

## 🚨 Troubleshooting Common Issues

### Init Container Failures:
```bash
# Check init container status
kubectl get pods -l app=web-app

# If pod stuck in "Init:0/1", check init logs
kubectl logs -l app=web-app -c init-config

# Common issues:
# - Image pull failures
# - Permission issues writing to volumes
# - Script errors in init logic
```

### Multi-Container Issues:
```bash
# Check individual container status
kubectl get pods -l app=web-app -o jsonpath='{.items[*].status.containerStatuses[*].name}'

# Check specific container logs
kubectl logs deployment/web-app-deployment -c web-app
kubectl logs deployment/web-app-deployment -c monitoring-agent

# Common issues:
# - Port conflicts between containers
# - Resource constraints
# - Volume mount problems
```

### Health Probe Failures:
```bash
# Check probe configuration
kubectl describe pods -l app=web-app | grep -A 10 "Liveness\|Readiness"

# Test probe endpoints manually
kubectl exec deployment/web-app-deployment -c web-app -- curl localhost/

# Common issues:
# - Wrong probe path or port
# - Application takes longer to start than initialDelaySeconds
# - Network policies blocking probe traffic
```

---

## 🎯 Real-World Use Cases

### 1. Database Migration Pattern:
```yaml
initContainers:
- name: db-migrate
  image: migrate/migrate
  command: ["migrate", "-path", "/migrations", "-database", "$DATABASE_URL", "up"]
```

### 2. Configuration Download:
```yaml
initContainers:
- name: config-downloader
  image: alpine/git
  command: ["git", "clone", "https://github.com/company/configs.git", "/shared/config"]
```

### 3. Dependency Check:
```yaml
initContainers:
- name: wait-for-db
  image: busybox
  command: ["sh", "-c", "until nc -z postgres-service 5432; do sleep 1; done"]
```

### 4. Log Shipper Sidecar:
```yaml
containers:
- name: app
  image: my-app:latest
- name: log-shipper
  image: fluent/fluent-bit
  volumeMounts:
  - name: app-logs
    mountPath: /var/log/app
```

---

## 📈 Advanced Monitoring Commands

### Complete Validation Script:
```bash
#!/bin/bash
echo "🔍 Advanced Deployment Validation"
echo "================================="

# 1. Check deployment status
echo "📊 Deployment Status:"
kubectl get deployment web-app-deployment -o wide

# 2. Check pod details
echo -e "\n🎯 Pod Details:"
kubectl get pods -l app=web-app -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[*].ready,RESTARTS:.status.containerStatuses[*].restartCount,AGE:.metadata.creationTimestamp"

# 3. Verify init containers
echo -e "\n🚀 Init Container Status:"
kubectl get pods -l app=web-app -o jsonpath='{.items[*].status.initContainerStatuses[*].name}' && echo
kubectl get pods -l app=web-app -o jsonpath='{.items[*].status.initContainerStatuses[*].state}' | jq .

# 4. Check container logs
echo -e "\n📝 Container Logs:"
echo "Init container logs:"
kubectl logs -l app=web-app -c init-config --tail=5

echo -e "\nMain container logs:"
kubectl logs -l app=web-app -c web-app --tail=5

echo -e "\nMonitoring container logs:"
kubectl logs -l app=web-app -c monitoring-agent --tail=5

# 5. Test endpoints
echo -e "\n🌐 Endpoint Tests:"
POD_NAME=$(kubectl get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
echo "Testing web app endpoint:"
kubectl exec $POD_NAME -c web-app -- curl -s localhost/ | head -5

echo -e "\nTesting monitoring endpoint:"
kubectl exec $POD_NAME -c monitoring-agent -- curl -s localhost:9100/metrics | head -5

# 6. Resource usage
echo -e "\n💾 Resource Usage:"
kubectl top pods -l app=web-app

echo -e "\n✅ Validation Complete!"
```

---

## 🎪 GKE-Specific Considerations

### 1. Node Selector for Special Workloads:
```yaml
spec:
  template:
    spec:
      nodeSelector:
        cloud.google.com/gke-nodepool: monitoring-pool
```

### 2. Workload Identity for GCP Access:
```yaml
spec:
  template:
    spec:
      serviceAccountName: gcp-workload-identity-sa
```

### 3. Resource Optimization:
```yaml
# Use guaranteed QoS for critical workloads
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"  # Same as requests for guaranteed QoS
    cpu: "100m"
```

This advanced deployment showcases production-ready patterns that you'll commonly see in enterprise Kubernetes environments! 🚀
