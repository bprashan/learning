# 🚀 Production E-commerce Platform Deployment Guide

## 📋 **Prerequisites & Requirements**

### **Infrastructure Requirements**
```yaml
Kubernetes Cluster:
  Version: 1.28+ (for latest Pod Security Standards)
  Nodes: Minimum 9 nodes (3 per availability zone)
  Node Specs: 
    - 4 vCPU, 16GB RAM minimum per node
    - 100GB SSD storage per node
    - Network: 10 Gbps between nodes

Cloud Provider Requirements:
  - Google GKE: Regional cluster with 3 zones
  - AWS EKS: Managed node groups across 3 AZs  
  - Azure AKS: Zone-redundant cluster

Storage Requirements:
  - Fast SSD storage class (minimum 1000 IOPS)
  - Volume snapshot support
  - Dynamic volume provisioning
```

### **Tool Requirements**
```bash
# Required CLI tools
kubectl >= 1.28
helm >= 3.12
argocd >= 2.8
istioctl >= 1.19 (optional for service mesh)

# Monitoring tools
prometheus-operator
grafana >= 9.0
elasticsearch >= 8.0
```

### **Network Requirements**
```yaml
Ports to Open:
  - 80, 443 (HTTP/HTTPS traffic)
  - 6443 (Kubernetes API)
  - 2379-2380 (etcd)
  - 10250 (kubelet)
  - 30000-32767 (NodePort services)

External Dependencies:
  - Container registry access
  - DNS resolution
  - NTP synchronization
  - Certificate authority access
```

---

## 🏗️ **Phase 1: Infrastructure Setup**

### **Step 1: Create GKE Cluster**
```bash
# Set variables
export PROJECT_ID="your-gcp-project"
export CLUSTER_NAME="ecommerce-production"
export REGION="us-central1"

# Create cluster
gcloud container clusters create $CLUSTER_NAME \
  --region=$REGION \
  --num-nodes=3 \
  --min-nodes=3 \
  --max-nodes=10 \
  --enable-autoscaling \
  --node-locations=us-central1-a,us-central1-b,us-central1-c \
  --machine-type=e2-standard-4 \
  --disk-size=100GB \
  --disk-type=pd-ssd \
  --enable-network-policy \
  --enable-ip-alias \
  --enable-autorepair \
  --enable-autoupgrade \
  --maintenance-window-start="2025-01-01T09:00:00Z" \
  --maintenance-window-end="2025-01-01T17:00:00Z" \
  --maintenance-window-recurrence="FREQ=WEEKLY;BYDAY=SA"

# Get credentials
gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION
```

### **Step 2: Verify Cluster Health**
```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes -o wide

# Verify storage class
kubectl get storageclass

# Check for default storage class
kubectl get storageclass | grep "(default)"

# If no default, set one:
kubectl patch storageclass fast-ssd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### **Step 3: Install Core Dependencies**
```bash
# Install cert-manager for SSL certificates
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux

# Install Prometheus Operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.size=10Gi
```

---

## 💾 **Phase 2: Database Layer Deployment**

### **Step 1: Create Namespace and Storage**
```bash
# Create namespaces
kubectl apply -f namespace.yaml

# Verify namespaces
kubectl get namespaces

# Check resource quotas
kubectl describe quota -n ecommerce-prod
```

### **Step 2: Deploy PostgreSQL Master**
```bash
# Deploy master database
kubectl apply -f database/postgresql-master.yaml

# Wait for master to be ready
kubectl wait --for=condition=ready pod -l app=postgresql,role=master -n ecommerce-prod --timeout=300s

# Check master status
kubectl get pods -n ecommerce-prod -l role=master
kubectl logs -n ecommerce-prod -l role=master -f
```

### **Step 3: Deploy PostgreSQL Read Replicas**
```bash
# Deploy read replicas
kubectl apply -f database/postgresql-slaves.yaml

# Wait for replicas to be ready
kubectl wait --for=condition=ready pod -l app=postgresql,role=slave -n ecommerce-prod --timeout=600s

# Verify replication status
kubectl exec -n ecommerce-prod postgresql-master-0 -- psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```

### **Step 4: Deploy Connection Pooler**
```bash
# Deploy PgPool for connection pooling and load balancing
kubectl apply -f database/pgpool.yaml

# Wait for pgpool to be ready
kubectl wait --for=condition=ready pod -l app=pgpool -n ecommerce-prod --timeout=180s

# Test database connectivity
kubectl exec -n ecommerce-prod -it deployment/pgpool -- psql -h localhost -U postgres -d ecommerce_db -c "SELECT version();"
```

---

## 🗄️ **Phase 3: Caching Layer Deployment**

### **Step 1: Deploy Redis Cluster**
```bash
# Deploy Redis cluster for session management
kubectl apply -f caching/redis-cluster.yaml

# Wait for Redis pods
kubectl wait --for=condition=ready pod -l app=redis -n ecommerce-prod --timeout=300s

# Initialize Redis cluster
kubectl get job redis-cluster-init -n ecommerce-prod
kubectl logs job/redis-cluster-init -n ecommerce-prod -f

# Verify cluster status
kubectl exec -n ecommerce-prod redis-cluster-0 -- redis-cli -a redis_secret123 cluster info
```

### **Step 2: Deploy Memcached Cluster**
```bash
# Deploy Memcached for product caching
kubectl apply -f caching/memcached-cluster.yaml

# Wait for Memcached pods
kubectl wait --for=condition=ready pod -l app=memcached -n ecommerce-prod --timeout=180s

# Test Memcached connectivity
kubectl exec -n ecommerce-prod deployment/memcached -- echo "stats" | nc localhost 11211
```

---

## 🏪 **Phase 4: Application Services Deployment**

### **Step 1: Deploy Core Microservices**
```bash
# Deploy all microservices
kubectl apply -f microservices/user-service.yaml
kubectl apply -f microservices/product-service.yaml
kubectl apply -f microservices/order-service.yaml
kubectl apply -f microservices/payment-service.yaml
kubectl apply -f microservices/inventory-service.yaml
kubectl apply -f microservices/notification-service.yaml

# Wait for all services to be ready
kubectl wait --for=condition=ready pod -l tier=microservice -n ecommerce-prod --timeout=300s

# Check service health
kubectl get pods -n ecommerce-prod -l tier=microservice
```

### **Step 2: Deploy Frontend and API Gateway**
```bash
# Deploy frontend application
kubectl apply -f frontend/react-frontend.yaml
kubectl apply -f frontend/api-gateway.yaml

# Wait for frontend services
kubectl wait --for=condition=ready pod -l app=frontend -n ecommerce-prod --timeout=180s
kubectl wait --for=condition=ready pod -l app=api-gateway -n ecommerce-prod --timeout=180s
```

### **Step 3: Configure Ingress and SSL**
```bash
# Deploy ingress configuration
kubectl apply -f networking/ingress.yaml

# Check ingress status
kubectl get ingress -n ecommerce-prod

# Get external IP
kubectl get svc -n ingress-nginx

# Update DNS records to point to the external IP
# Wait for SSL certificate to be issued
kubectl get certificate -n ecommerce-prod
```

---

## 🔒 **Phase 5: Security Configuration**

### **Step 1: Apply Network Policies**
```bash
# Deploy network policies for micro-segmentation
kubectl apply -f networking/network-policies.yaml

# Verify network policies
kubectl get networkpolicy -n ecommerce-prod

# Test network connectivity between services
kubectl exec -n ecommerce-prod deployment/user-service -- nc -zv database 5432
```

### **Step 2: Configure RBAC**
```bash
# Apply RBAC configuration
kubectl apply -f security/rbac.yaml

# Verify service accounts and roles
kubectl get serviceaccount -n ecommerce-prod
kubectl get rolebinding -n ecommerce-prod
```

### **Step 3: Apply Pod Security Standards**
```bash
# Apply pod security policies
kubectl apply -f security/pod-security-policies.yaml

# Label namespace for pod security
kubectl label namespace ecommerce-prod pod-security.kubernetes.io/enforce=restricted
kubectl label namespace ecommerce-prod pod-security.kubernetes.io/audit=restricted
kubectl label namespace ecommerce-prod pod-security.kubernetes.io/warn=restricted
```

---

## 📊 **Phase 6: Monitoring and Observability**

### **Step 1: Deploy Application Monitoring**
```bash
# Deploy Prometheus monitoring configuration
kubectl apply -f monitoring/prometheus-stack.yaml

# Deploy custom Grafana dashboards
kubectl apply -f monitoring/grafana-dashboards.yaml

# Deploy alerting rules
kubectl apply -f monitoring/alerting-rules.yaml
```

### **Step 2: Configure Log Aggregation**
```bash
# Deploy ELK stack for log aggregation
kubectl apply -f monitoring/elk-stack.yaml

# Wait for Elasticsearch cluster
kubectl wait --for=condition=ready pod -l app=elasticsearch -n ecommerce-prod --timeout=300s

# Verify Kibana access
kubectl port-forward -n ecommerce-prod svc/kibana 5601:5601
# Open http://localhost:5601 in browser
```

### **Step 3: Setup Alerting**
```bash
# Configure AlertManager
kubectl get secret -n monitoring alertmanager-kube-prometheus-stack-alertmanager -o yaml

# Test alert routing
kubectl exec -n monitoring deployment/kube-prometheus-stack-operator -- /bin/amtool config routes --config.file=/etc/alertmanager/config/alertmanager.yml
```

---

## ⚡ **Phase 7: Auto-scaling Configuration**

### **Step 1: Deploy HPA Configurations**
```bash
# Deploy Horizontal Pod Autoscalers
kubectl apply -f autoscaling/hpa-configs.yaml

# Verify HPA status
kubectl get hpa -n ecommerce-prod

# Check metrics server
kubectl top pods -n ecommerce-prod
kubectl top nodes
```

### **Step 2: Configure Cluster Autoscaler**
```bash
# Deploy cluster autoscaler
kubectl apply -f autoscaling/cluster-autoscaler.yaml

# Verify cluster autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler -f

# Check node scaling
kubectl get nodes --watch
```

### **Step 3: Deploy VPA (Optional)**
```bash
# Install VPA if using custom resource sizing
kubectl apply -f autoscaling/vpa-configs.yaml

# Check VPA recommendations
kubectl describe vpa -n ecommerce-prod
```

---

## 🧪 **Phase 8: Testing and Validation**

### **Step 1: Health Check Validation**
```bash
# Check all pod health
kubectl get pods -A | grep -v Running

# Verify all services are ready
kubectl get svc -n ecommerce-prod

# Test internal connectivity
kubectl run test-pod --image=busybox -it --rm -- sh
# Inside the test pod:
# nslookup database.ecommerce-prod.svc.cluster.local
# nslookup user-service.ecommerce-prod.svc.cluster.local
```

### **Step 2: Database Connectivity Tests**
```bash
# Test master database
kubectl exec -n ecommerce-prod postgresql-master-0 -- psql -U postgres -d ecommerce_db -c "SELECT COUNT(*) FROM products;"

# Test read replicas
kubectl exec -n ecommerce-prod postgresql-slave-0 -- psql -U postgres -d ecommerce_db -c "SELECT COUNT(*) FROM products;"

# Test connection pooler
kubectl exec -n ecommerce-prod deployment/pgpool -- psql -h localhost -U postgres -d ecommerce_db -c "SHOW pool_pools;"
```

### **Step 3: Cache Functionality Tests**
```bash
# Test Redis cluster
kubectl exec -n ecommerce-prod redis-cluster-0 -- redis-cli -a redis_secret123 set test_key "test_value"
kubectl exec -n ecommerce-prod redis-cluster-1 -- redis-cli -a redis_secret123 get test_key

# Test Memcached
kubectl exec -n ecommerce-prod deployment/memcached -- echo -e "set test_key 0 0 10\r\ntest_value\r\nget test_key\r\nquit\r" | nc localhost 11211
```

### **Step 4: Application Functionality Tests**
```bash
# Test API endpoints
kubectl port-forward -n ecommerce-prod svc/api-gateway 8080:80

# In another terminal, test endpoints:
curl http://localhost:8080/api/health
curl http://localhost:8080/api/users/health
curl http://localhost:8080/api/products/health
curl http://localhost:8080/api/orders/health
```

### **Step 5: Load Testing**
```bash
# Deploy load testing tools
kubectl apply -f testing/load-test-job.yaml

# Run basic load test
kubectl create job load-test-basic --from=cronjob/load-test-scheduler -n ecommerce-prod

# Monitor during load test
kubectl top pods -n ecommerce-prod
kubectl get hpa -n ecommerce-prod --watch
```

---

## 🚨 **Phase 9: Backup and Disaster Recovery Setup**

### **Step 1: Configure Database Backups**
```bash
# Deploy backup jobs
kubectl apply -f storage/backup-jobs.yaml

# Test backup functionality
kubectl create job manual-backup --from=cronjob/database-backup -n ecommerce-prod

# Verify backup creation
kubectl logs job/manual-backup -n ecommerce-prod
```

### **Step 2: Volume Snapshots**
```bash
# Create volume snapshot class
kubectl apply -f storage/snapshot-class.yaml

# Test volume snapshot
kubectl apply -f storage/test-snapshot.yaml

# Verify snapshot
kubectl get volumesnapshot -n ecommerce-prod
```

### **Step 3: Disaster Recovery Procedures**
```bash
# Document recovery procedures
kubectl apply -f disaster-recovery/failover-procedures.yaml

# Test failure scenarios (in staging environment)
# - Simulate node failure
# - Test database failover
# - Validate auto-recovery
```

---

## 🔍 **Phase 10: Performance Optimization**

### **Step 1: Resource Optimization**
```bash
# Analyze resource usage
kubectl top pods -n ecommerce-prod --sort-by=cpu
kubectl top pods -n ecommerce-prod --sort-by=memory

# Check resource requests vs usage
kubectl describe nodes | grep -A 5 "Allocated resources"

# Optimize based on VPA recommendations
kubectl get vpa -n ecommerce-prod -o yaml
```

### **Step 2: Database Performance Tuning**
```bash
# Check database performance
kubectl exec -n ecommerce-prod postgresql-master-0 -- psql -U postgres -d ecommerce_db -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"

# Analyze slow queries
kubectl exec -n ecommerce-prod postgresql-master-0 -- psql -U postgres -d ecommerce_db -c "SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"

# Check connection pool efficiency
kubectl exec -n ecommerce-prod deployment/pgpool -- psql -h localhost -U postgres -d ecommerce_db -c "SHOW pool_cache;"
```

### **Step 3: Cache Optimization**
```bash
# Check Redis memory usage
kubectl exec -n ecommerce-prod redis-cluster-0 -- redis-cli -a redis_secret123 info memory

# Check cache hit ratios
kubectl exec -n ecommerce-prod redis-cluster-0 -- redis-cli -a redis_secret123 info stats | grep hit

# Monitor Memcached efficiency
kubectl exec -n ecommerce-prod deployment/memcached -- echo "stats" | nc localhost 11211 | grep "get_hits\|get_misses"
```

---

## 📈 **Phase 11: Production Readiness Checklist**

### **Security Checklist**
```bash
# ✅ Verify all security configurations
echo "=== Security Validation ==="

# Check pod security contexts
kubectl get pods -n ecommerce-prod -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'

# Verify network policies are active
kubectl get networkpolicy -n ecommerce-prod --no-headers | wc -l

# Check RBAC permissions
kubectl auth can-i --list --as=system:serviceaccount:ecommerce-prod:user-service -n ecommerce-prod

# Verify TLS certificates
kubectl get certificate -n ecommerce-prod
```

### **High Availability Checklist**
```bash
echo "=== High Availability Validation ==="

# Check pod distribution across nodes
kubectl get pods -n ecommerce-prod -o wide | awk '{print $1, $7}' | sort -k2

# Verify PDB configurations
kubectl get pdb -n ecommerce-prod

# Check anti-affinity rules
kubectl get deployment -n ecommerce-prod -o yaml | grep -A 10 affinity
```

### **Performance Checklist**
```bash
echo "=== Performance Validation ==="

# Check resource limits and requests
kubectl describe pods -n ecommerce-prod | grep -A 2 -B 2 "Limits:\|Requests:"

# Verify HPA configurations
kubectl get hpa -n ecommerce-prod

# Check startup and readiness probe configurations
kubectl get pods -n ecommerce-prod -o yaml | grep -A 5 "readinessProbe:\|livenessProbe:"
```

### **Monitoring Checklist**
```bash
echo "=== Monitoring Validation ==="

# Check Prometheus targets
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 &
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# Verify Grafana dashboards
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &

# Check log aggregation
kubectl logs -n ecommerce-prod -l app=elasticsearch --tail=10
```

---

## 🎯 **Go-Live Procedures**

### **Pre-Go-Live Steps**
```bash
# 1. Final health check
kubectl get pods -A | grep -v Running
kubectl get svc -n ecommerce-prod

# 2. DNS configuration
# Point domain to ingress external IP
dig ecommerce.yourdomain.com

# 3. SSL certificate verification
kubectl get certificate -n ecommerce-prod

# 4. Load balancer configuration
kubectl get ingress -n ecommerce-prod -o yaml

# 5. Monitoring dashboard setup
# Configure Grafana alerts and dashboards
# Set up PagerDuty integration
```

### **Go-Live Monitoring**
```bash
# Monitor key metrics during go-live
watch kubectl top pods -n ecommerce-prod
watch kubectl get hpa -n ecommerce-prod
watch kubectl get pdb -n ecommerce-prod

# Watch for errors in real-time
kubectl logs -f -n ecommerce-prod -l tier=microservice --max-log-requests=10

# Monitor ingress traffic
kubectl logs -f -n ingress-nginx deployment/ingress-nginx-controller
```

### **Post Go-Live Validation**
```bash
# Validate external access
curl -I https://ecommerce.yourdomain.com/health
curl -I https://ecommerce.yourdomain.com/api/health

# Check database replication lag
kubectl exec -n ecommerce-prod postgresql-master-0 -- psql -U postgres -c "SELECT * FROM pg_stat_replication;"

# Verify auto-scaling works
# Generate load and watch HPA scale up
kubectl get hpa -n ecommerce-prod --watch
```

---

## 🚨 **Troubleshooting Common Issues**

### **Database Connection Issues**
```bash
# Check database pod status
kubectl describe pod -n ecommerce-prod postgresql-master-0

# Check connection pooler
kubectl logs -n ecommerce-prod deployment/pgpool

# Test database connectivity
kubectl exec -n ecommerce-prod deployment/pgpool -- pg_isready -h postgresql-master -p 5432
```

### **Service Discovery Issues**
```bash
# Check DNS resolution
kubectl exec -n ecommerce-prod deployment/user-service -- nslookup database.ecommerce-prod.svc.cluster.local

# Check service endpoints
kubectl get endpoints -n ecommerce-prod

# Check network policies
kubectl describe networkpolicy -n ecommerce-prod
```

### **Performance Issues**
```bash
# Check resource utilization
kubectl top pods -n ecommerce-prod
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check HPA status
kubectl describe hpa -n ecommerce-prod

# Check for resource constraints
kubectl get events -n ecommerce-prod | grep -i "insufficient\|failed\|error"
```

---

## 📞 **Support and Maintenance**

### **Daily Operations**
```bash
# Daily health check script
#!/bin/bash
echo "=== Daily E-commerce Platform Health Check ==="
echo "Date: $(date)"
echo ""

echo "=== Cluster Status ==="
kubectl get nodes

echo "=== Pod Status ==="
kubectl get pods -n ecommerce-prod | grep -v Running | grep -v Completed || echo "All pods running"

echo "=== Resource Usage ==="
kubectl top nodes
kubectl top pods -n ecommerce-prod --sort-by=cpu | head -10

echo "=== Database Status ==="
kubectl exec -n ecommerce-prod postgresql-master-0 -- psql -U postgres -c "SELECT * FROM pg_stat_replication;" 2>/dev/null || echo "Database check failed"

echo "=== Cache Status ==="
kubectl exec -n ecommerce-prod redis-cluster-0 -- redis-cli -a redis_secret123 cluster info 2>/dev/null | head -2 || echo "Redis check failed"

echo "Health check completed"
```

### **Backup Verification**
```bash
# Weekly backup verification
kubectl get job -n ecommerce-prod | grep backup
kubectl logs -n ecommerce-prod job/database-backup-$(date +%Y%m%d) --tail=20
```

### **Performance Reports**
```bash
# Generate weekly performance report
kubectl top pods -n ecommerce-prod --sort-by=cpu > weekly-cpu-usage.txt
kubectl top pods -n ecommerce-prod --sort-by=memory > weekly-memory-usage.txt
kubectl get hpa -n ecommerce-prod -o yaml > weekly-hpa-status.yaml
```

---

## 🎉 **Deployment Complete!**

Your production-grade e-commerce platform is now deployed and ready to handle enterprise-level traffic. The system includes:

- ✅ **High-availability database** with master-slave replication
- ✅ **Multi-layer caching** for optimal performance  
- ✅ **Auto-scaling microservices** for traffic spikes
- ✅ **Security hardening** with network policies and RBAC
- ✅ **Comprehensive monitoring** and alerting
- ✅ **Disaster recovery** capabilities
- ✅ **Performance optimization** for sub-2-second response times

The platform is designed to scale from 1,000 to 50,000+ concurrent users while maintaining 99.9% uptime. 🚀

### **Next Steps:**
1. Set up domain DNS and SSL certificates
2. Configure external monitoring (PagerDuty, Datadog)
3. Implement CI/CD pipelines with GitOps
4. Schedule regular disaster recovery tests
5. Plan capacity scaling for anticipated growth

**Happy e-commerce! 🛍️**
