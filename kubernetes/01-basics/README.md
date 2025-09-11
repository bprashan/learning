# 01 - Kubernetes Basics

## 🏗️ Kubernetes Architecture

Kubernetes follows a master-worker architecture:

### Master Components (Control Plane)
- **API Server**: Entry point for all REST commands
- **etcd**: Distributed key-value store for cluster data
- **Scheduler**: Assigns pods to nodes
- **Controller Manager**: Runs controller processes

### Worker Node Components
- **kubelet**: Agent that runs on each node
- **kube-proxy**: Network proxy
- **Container Runtime**: Docker, containerd, CRI-O

## 🔑 Key Concepts

### Pod
- Smallest deployable unit
- Contains one or more containers
- Shares network and storage

### Node
- Physical or virtual machine
- Runs pods
- Managed by master

### Cluster
- Set of nodes
- Managed by Kubernetes master

### Namespace
- Virtual clusters within a cluster
- Isolates resources

## 🛠️ Setting Up GKE Cluster

### Prerequisites
1. Install Google Cloud SDK
2. Enable Kubernetes Engine API
3. Set up billing

### Create Cluster

```bash
# Set your project
gcloud config set project YOUR_PROJECT_ID

# Create cluster
gcloud container clusters create k8s-learning-cluster \
    --zone us-central1-a \
    --num-nodes 3 \
    --enable-autorepair \
    --enable-autoupgrade \
    --machine-type e2-medium \
    --disk-size 20GB

# Get credentials
gcloud container clusters get-credentials k8s-learning-cluster --zone us-central1-a

# Verify
kubectl cluster-info
kubectl get nodes
```

## 📋 kubectl Basics

```bash
# Cluster information
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Resource operations
kubectl get pods
kubectl get services
kubectl get deployments

# Detailed information
kubectl describe node <node-name>
kubectl describe pod <pod-name>

# Logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs

# Execute commands
kubectl exec -it <pod-name> -- /bin/bash

# Apply configurations
kubectl apply -f file.yaml
kubectl delete -f file.yaml

# Port forwarding
kubectl port-forward pod/<pod-name> 8080:80
```

## 🔍 Useful Debugging Commands

```bash
# Get events
kubectl get events --sort-by=.metadata.creationTimestamp

# Resource usage
kubectl top nodes
kubectl top pods

# Troubleshooting
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous

# Edit resources
kubectl edit deployment <deployment-name>
```

## 🏷️ Labels and Selectors

Labels are key-value pairs attached to objects:

```yaml
metadata:
  labels:
    app: nginx
    version: v1.0
    environment: production
```

Selectors help filter resources:
```bash
kubectl get pods -l app=nginx
kubectl get pods -l environment=production,version=v1.0
```

## Next Steps
Move to [02-core-concepts](../02-core-concepts/README.md) to learn about Pods, Namespaces, and more!
