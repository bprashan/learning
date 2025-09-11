# 🚨 Init Container Nginx Configuration - Troubleshooting Guide

## Problem Analysis

### ❌ **What Went Wrong**

The init container was creating an **invalid nginx configuration**:

```bash
echo "server_name web-app;" > /shared/nginx.conf
```

This creates a file with just:
```nginx
server_name web-app;
```

### 🔍 **Why It Failed**

In nginx, the `server_name` directive **must be inside a `server` block**. Putting it at the root level causes:
```
nginx: [emerg] "server_name" directive is not allowed here
```

---

## ✅ **The Fix**

### **Corrected Init Container Configuration:**

```yaml
initContainers:
- name: init-config
  image: busybox:1.35
  command: ['sh', '-c']
  args:
    - |
      echo "Setting up configuration..."
      cat > /shared/default.conf << 'EOF'
      server {
          listen 80;
          server_name web-app;
          
          location / {
              root /usr/share/nginx/html;
              index index.html index.htm;
          }
          
          location /health {
              access_log off;
              return 200 "healthy\n";
              add_header Content-Type text/plain;
          }
      }
      EOF
      echo "Configuration complete!"
```

### **Key Improvements:**

1. **Proper Server Block**: Wrapped `server_name` in `server { }` block
2. **Health Endpoint**: Added `/health` for probes
3. **Complete Config**: Full nginx server configuration
4. **Proper File Name**: Using `default.conf` instead of `nginx.conf`

---

## 🔧 **Recovery Steps**

### **1. Apply the Fix**
```bash
kubectl apply -f deployment-advanced.yaml
```

### **2. Clean Up Failed Pods**
```bash
# Delete pods in CrashLoopBackOff state
kubectl delete pods -l app=web-app --field-selector=status.phase!=Running

# Or delete all pods to recreate with new config
kubectl delete pods -l app=web-app
```

### **3. Monitor Recovery**
```bash
# Watch pod status
kubectl get pods -l app=web-app -w

# Check rollout status
kubectl rollout status deployment/web-app-deployment
```

### **4. Validate the Fix**
```bash
# Check if pods are running
kubectl get pods -l app=web-app

# Test nginx configuration
kubectl exec deployment/web-app-deployment -c web-app -- nginx -t

# Test health endpoint
kubectl exec deployment/web-app-deployment -c web-app -- curl localhost/health
```

---

## 🏥 **Health Check Updates**

### **Updated Probe Configuration:**
```yaml
livenessProbe:
  httpGet:
    path: /health    # Changed from /
    port: 80
readinessProbe:
  httpGet:
    path: /health    # Changed from /
    port: 80
```

### **Benefits:**
- ✅ **Faster Response**: `/health` is lightweight
- ✅ **No Logging**: `access_log off` reduces noise
- ✅ **Explicit Status**: Returns "healthy" message
- ✅ **Proper Headers**: Content-Type set correctly

---

## 🧪 **Testing Your Fix**

### **Run the Automated Fix Script:**
```bash
.\fix-deployment-issue.ps1
```

### **Manual Testing:**
```bash
# Port forward to test locally
kubectl port-forward deployment/web-app-deployment 8080:80

# Test in another terminal
curl http://localhost:8080          # Main page
curl http://localhost:8080/health   # Health check
```

### **Expected Results:**
- Main page: Default nginx welcome page
- Health endpoint: "healthy" message
- All pods in "Running" state with "2/2 Ready"

---

## 💡 **Best Practices for Init Containers**

### **1. Configuration Validation**
```bash
# Always test your config
nginx -t -c /path/to/config

# Use init container to validate
args:
  - |
    # Generate config
    cat > /shared/nginx.conf << 'EOF'
    server { ... }
    EOF
    
    # Validate config
    nginx -t -c /shared/nginx.conf
    echo "Config validation passed!"
```

### **2. Error Handling**
```bash
args:
  - |
    set -e  # Exit on any error
    echo "Starting configuration setup..."
    
    # Your config generation here
    
    echo "Configuration complete!"
```

### **3. Debugging Init Containers**
```bash
# View init container logs
kubectl logs <pod-name> -c init-config

# Describe pod for events
kubectl describe pod <pod-name>

# Check init container status
kubectl get pod <pod-name> -o jsonpath='{.status.initContainerStatuses}'
```

---

## 🎯 **Common Init Container Patterns**

### **1. Database Migration**
```yaml
initContainers:
- name: db-migrate
  image: migrate/migrate
  command: ["migrate"]
  args: ["-path", "/migrations", "-database", "$DB_URL", "up"]
```

### **2. Config from Git**
```yaml
initContainers:
- name: git-clone
  image: alpine/git
  command: ["git", "clone", "https://github.com/company/configs.git", "/shared"]
```

### **3. Wait for Dependencies**
```yaml
initContainers:
- name: wait-for-db
  image: busybox
  command: ['sh', '-c', 'until nc -z postgres 5432; do sleep 1; done']
```

### **4. File Permissions Setup**
```yaml
initContainers:
- name: fix-permissions
  image: busybox
  command: ['sh', '-c', 'chown -R 1000:1000 /shared && chmod -R 755 /shared']
  securityContext:
    runAsUser: 0  # Run as root for permission changes
```

---

## 🚨 **Troubleshooting Checklist**

### **When Init Containers Fail:**
- [ ] Check init container logs: `kubectl logs <pod> -c <init-container>`
- [ ] Verify image exists and is accessible
- [ ] Check volume mounts and permissions
- [ ] Validate any generated configurations
- [ ] Ensure init container has necessary permissions
- [ ] Check for resource constraints
- [ ] Verify network connectivity for external dependencies

### **When Main Containers Fail:**
- [ ] Check if init containers completed successfully
- [ ] Verify shared volumes contain expected data
- [ ] Test configuration files generated by init containers
- [ ] Check main container logs for startup errors
- [ ] Validate health probe endpoints
- [ ] Ensure proper resource allocation

---

## ✅ **Success Indicators**

After applying the fix, you should see:

```bash
$ kubectl get pods -l app=web-app
NAME                                  READY   STATUS    RESTARTS   AGE
web-app-deployment-xyz123-abc         2/2     Running   0          2m
web-app-deployment-xyz123-def         2/2     Running   0          2m
web-app-deployment-xyz123-ghi         2/2     Running   0          2m
```

**Key Points:**
- ✅ Status: `Running`
- ✅ Ready: `2/2` (both containers ready)
- ✅ Restarts: Low or 0
- ✅ Health probes passing

This fix demonstrates the importance of proper configuration validation in init containers! 🎯
