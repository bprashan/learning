# 04 - Services & Networking

Services enable communication between different components within and outside the cluster.

## 🌐 Services Types

### 1. ClusterIP (Default)
- **Purpose**: Internal cluster communication
- **Access**: Only within cluster
- **Use Case**: Backend services, databases
- **IP**: Virtual IP accessible only within cluster

### 2. NodePort
- **Purpose**: External access through node's IP
- **Access**: `<NodeIP>:<NodePort>`
- **Port Range**: 30000-32767 (by default)
- **Use Case**: Development, testing, small applications

### 3. LoadBalancer
- **Purpose**: External access with cloud load balancer
- **Access**: External IP provided by cloud provider
- **Use Case**: Production applications in cloud environments
- **Cloud Integration**: GCP, AWS, Azure load balancers

### 4. ExternalName
- **Purpose**: Maps service to external DNS name
- **Access**: DNS CNAME record
- **Use Case**: External services, migration scenarios

## 🔄 Service Discovery

Services provide:
- **Stable IP addresses**
- **DNS names** (`service-name.namespace.svc.cluster.local`)
- **Load balancing** across pods
- **Health checking**

### DNS Resolution Examples:
```bash
# Same namespace
curl http://my-service:8080

# Different namespace  
curl http://my-service.other-namespace:8080

# Full FQDN
curl http://my-service.other-namespace.svc.cluster.local:8080
```

## 📡 Ingress

Ingress manages external access to services in a cluster, typically HTTP.

### Features:
- **Path-based routing**: `/api` → api-service, `/web` → web-service
- **Host-based routing**: `api.example.com` → api-service
- **SSL/TLS termination**
- **Load balancing**

### Ingress vs LoadBalancer:
- **Ingress**: Layer 7 (HTTP/HTTPS), multiple services per IP
- **LoadBalancer**: Layer 4 (TCP/UDP), one service per IP

## 🔒 NetworkPolicies

NetworkPolicies control traffic flow between pods.

### Policy Types:
- **Ingress**: Incoming traffic to pods
- **Egress**: Outgoing traffic from pods

### Default Behavior:
- **No NetworkPolicy**: All traffic allowed
- **Empty NetworkPolicy**: All traffic denied
- **Specific Rules**: Only matching traffic allowed

### Selectors:
- **podSelector**: Target pods for policy
- **namespaceSelector**: Allow traffic from specific namespaces
- **ipBlock**: Allow traffic from IP ranges

## ⚖️ Load Balancing

### Service Load Balancing:
- **Round Robin**: Default algorithm
- **Session Affinity**: Route to same pod (ClientIP)

### Ingress Load Balancing:
- **Depends on Ingress Controller**
- **GKE**: Google Cloud Load Balancer
- **NGINX**: Various algorithms available

## 🔍 Service Mesh

Advanced networking with service mesh (Istio, Linkerd):
- **Traffic management**
- **Security policies**
- **Observability**
- **Canary deployments**

## 🎯 Best Practices

1. **Use descriptive service names**
2. **Implement health checks**
3. **Set appropriate resource limits**
4. **Use NetworkPolicies for security**
5. **Monitor service performance**
6. **Use Ingress for HTTP services**
7. **Implement proper SSL/TLS**

## 🛠️ Troubleshooting

### Common Commands:
```bash
# Check service endpoints
kubectl get endpoints

# Test service connectivity
kubectl exec -it pod-name -- curl service-name:port

# Check service DNS
kubectl exec -it pod-name -- nslookup service-name

# View service details
kubectl describe service service-name

# Check ingress status
kubectl get ingress
kubectl describe ingress ingress-name
```
