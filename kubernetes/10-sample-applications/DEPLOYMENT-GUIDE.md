# 🚀 Deployment Guide

## Prerequisites

Before deploying the 3-tier web application, ensure you have:

1. **GKE Cluster**: Running Kubernetes cluster
2. **kubectl**: Configured to access your cluster  
3. **Storage**: Default storage class available
4. **Ingress**: Ingress controller installed
5. **Monitoring**: Optional but recommended

## 📋 Step-by-Step Deployment

### 1. Verify Cluster Setup

```bash
# Check cluster connection
kubectl cluster-info

# Verify nodes
kubectl get nodes

# Check storage classes
kubectl get storageclass
```

### 2. Create Monitoring Stack (Optional but Recommended)

```bash
# Deploy Prometheus
kubectl apply -f 09-monitoring-logging/prometheus.yaml

# Deploy Grafana
kubectl apply -f 09-monitoring-logging/grafana.yaml

# Deploy EFK Stack for logging
kubectl apply -f 09-monitoring-logging/efk-stack.yaml
```

### 3. Deploy the 3-Tier Application

```bash
# Deploy the main application
kubectl apply -f 10-sample-applications/three-tier-webapp.yaml

# Wait for database to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n webapp --timeout=300s

# Deploy advanced features
kubectl apply -f 10-sample-applications/advanced-features.yaml

# Deploy maintenance jobs
kubectl apply -f 10-sample-applications/maintenance-jobs.yaml
```

### 4. Verify Deployment

```bash
# Check all resources in webapp namespace
kubectl get all -n webapp

# Check pod status
kubectl get pods -n webapp -w

# Check services
kubectl get svc -n webapp

# Check ingress
kubectl get ingress -n webapp
```

### 5. Access the Application

```bash
# Get the external IP (LoadBalancer) or configure DNS for Ingress
kubectl get ingress webapp-ingress -n webapp

# Port forward for local testing
kubectl port-forward svc/frontend-service 8080:80 -n webapp

# Access at http://localhost:8080
```

## 🔍 Troubleshooting Commands

### Check Application Logs
```bash
# Frontend logs
kubectl logs -f deployment/frontend-web -n webapp

# Backend logs  
kubectl logs -f deployment/backend-api -n webapp

# Database logs
kubectl logs -f statefulset/postgres-db -n webapp

# Redis logs
kubectl logs -f deployment/redis-cache -n webapp
```

### Debug Network Issues
```bash
# Test internal connectivity
kubectl exec -it deployment/backend-api -n webapp -- curl http://postgres-service:5432

# Check network policies
kubectl get networkpolicies -n webapp

# Describe services
kubectl describe svc backend-service -n webapp
```

### Check Resource Usage
```bash
# Pod resource usage
kubectl top pods -n webapp

# Node resource usage  
kubectl top nodes

# Check HPA status
kubectl get hpa -n webapp
```

### Database Operations
```bash
# Connect to database
kubectl exec -it statefulset/postgres-db -n webapp -- psql -U webapp -d webappdb

# Check database status
kubectl exec -it statefulset/postgres-db -n webapp -- pg_isready -U webapp

# View database logs
kubectl logs -f statefulset/postgres-db -n webapp
```

## 📊 Monitoring and Observability

### Access Monitoring Dashboards

```bash
# Prometheus (if deployed)
kubectl port-forward svc/prometheus-service 9090:9090

# Grafana (if deployed)  
kubectl port-forward svc/grafana-service 3000:80

# Kibana (if deployed)
kubectl port-forward svc/kibana-service 5601:80
```

### Default Credentials
- **Grafana**: admin / admin123 (change after first login)
- **Kibana**: No authentication by default

## 🔧 Configuration Updates

### Update Application Configuration
```bash
# Edit ConfigMap
kubectl edit configmap backend-config -n webapp

# Restart deployment to pick up changes
kubectl rollout restart deployment/backend-api -n webapp
```

### Scale Applications
```bash
# Manual scaling
kubectl scale deployment backend-api --replicas=5 -n webapp

# Check HPA status
kubectl describe hpa backend-api-hpa -n webapp
```

### Update Application Images
```bash
# Update backend image
kubectl set image deployment/backend-api backend-api=your-registry/backend:v2.0 -n webapp

# Check rollout status
kubectl rollout status deployment/backend-api -n webapp

# Rollback if needed
kubectl rollout undo deployment/backend-api -n webapp
```

## 🛡️ Security Considerations

### Network Security
```bash
# Verify network policies
kubectl get networkpolicies -n webapp

# Test network restrictions
kubectl exec -it deployment/frontend-web -n webapp -- curl http://postgres-service:5432
```

### RBAC Verification
```bash
# Check service accounts
kubectl get serviceaccounts -n webapp

# Check roles and bindings
kubectl get roles,rolebindings -n webapp
```

## 📋 Maintenance Tasks

### Backup Operations
```bash
# Check backup CronJob
kubectl get cronjob postgres-backup -n webapp

# Manual backup trigger
kubectl create job --from=cronjob/postgres-backup manual-backup-$(date +%s) -n webapp
```

### Health Monitoring
```bash
# Check health check job
kubectl get cronjob health-check -n webapp

# View recent health check results
kubectl get jobs -l job-name=health-check -n webapp
```

## 🧹 Cleanup

### Remove Application
```bash
# Delete all application resources
kubectl delete namespace webapp

# Delete monitoring stack (if deployed separately)
kubectl delete -f 09-monitoring-logging/

# Verify cleanup
kubectl get namespaces
```

## 📚 Learning Exercises

1. **Scale Testing**: Use `kubectl scale` to test HPA behavior
2. **Failure Simulation**: Delete pods and observe recovery
3. **Configuration Changes**: Update ConfigMaps and restart services  
4. **Monitoring Setup**: Configure custom Grafana dashboards
5. **Security Testing**: Verify network policies block unauthorized access
6. **Backup Testing**: Restore from backup to verify data integrity

## 🎯 Next Steps

1. **CI/CD Integration**: Set up GitOps with ArgoCD or Flux
2. **Service Mesh**: Implement Istio for advanced traffic management
3. **Advanced Monitoring**: Add custom metrics and alerting rules
4. **Security Hardening**: Implement Pod Security Standards
5. **Multi-Environment**: Set up staging and production environments

Happy Kubernetes Learning! 🎉
