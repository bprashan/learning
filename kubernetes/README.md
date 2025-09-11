# Kubernetes Learning Journey 🚀

Welcome to your comprehensive Kubernetes learning path! This repository is structured to take you from beginner to advanced concepts with hands-on examples for Google Kubernetes Engine (GKE).

## 📚 Learning Path

### 1. [Basics](./01-basics/README.md)
- Kubernetes Architecture
- Key Concepts & Terminology
- kubectl basics
- Setting up GKE cluster

### 2. [Core Concepts](./02-core-concepts/README.md)
- Pods
- Namespaces
- Labels & Selectors
- Annotations

### 3. [Workloads](./03-workloads/README.md)
- ReplicaSets
- Deployments
- StatefulSets
- DaemonSets
- Jobs & CronJobs

### 4. [Services & Networking](./04-services-networking/README.md)
- Services (ClusterIP, NodePort, LoadBalancer)
- Ingress
- NetworkPolicies
- DNS

### 5. [Storage](./05-storage/README.md)
- Volumes
- Persistent Volumes & Claims
- Storage Classes
- StatefulSet Storage

### 6. [Configuration](./06-configuration/README.md)
- ConfigMaps
- Secrets
- Environment Variables
- Init Containers

### 7. [Security](./07-security/README.md)
- RBAC (Role Based Access Control)
- Service Accounts
- Security Contexts
- Pod Security Standards

### 8. [Advanced Topics](./08-advanced-topics/README.md)
- Custom Resource Definitions (CRDs)
- Operators
- Helm Charts
- Horizontal Pod Autoscaler (HPA)
- Vertical Pod Autoscaler (VPA)

### 9. [Monitoring & Logging](./09-monitoring-logging/README.md)
- Prometheus & Grafana
- Elasticsearch, Fluentd, Kibana (EFK)
- Google Cloud Operations Suite
- Resource Monitoring

### 10. [Sample Applications](./10-sample-applications/README.md)
- 3-Tier Web Application
- Microservices Architecture
- Complete CI/CD Pipeline

## 🎯 Prerequisites

- Basic understanding of containers and Docker
- GCP account with billing enabled
- kubectl installed
- gcloud CLI installed

## 🚀 Getting Started

1. **Set up GKE cluster:**
   ```bash
   gcloud container clusters create learning-cluster \
     --zone=us-central1-a \
     --num-nodes=3 \
     --enable-autorepair \
     --enable-autoupgrade
   ```

2. **Configure kubectl:**
   ```bash
   gcloud container clusters get-credentials learning-cluster --zone=us-central1-a
   ```

3. **Verify connection:**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

## 📖 How to Use This Repository

- Each folder contains a README with theory and explanations
- YAML files are ready to apply to your GKE cluster
- Follow the numbered sequence for optimal learning
- Practice with the provided examples
- Experiment and modify the configurations

## 🔧 Useful Commands

```bash
# Apply a configuration
kubectl apply -f filename.yaml

# View resources
kubectl get pods,services,deployments

# Describe a resource
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Execute into a pod
kubectl exec -it <pod-name> -- /bin/bash

# Delete resources
kubectl delete -f filename.yaml
```

Happy Learning! 🎉
