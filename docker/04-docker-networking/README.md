# 04 - Docker Networking: Advanced Network Architecture

## 🎯 **Learning Objectives**
Master Docker networking for production-grade architectures:
- Network drivers and their use cases
- Service discovery and DNS resolution
- Load balancing and traffic management
- Network security and isolation
- Production networking patterns
- Troubleshooting network issues

---

## 📋 **Table of Contents**
1. [Network Architecture Overview](#network-architecture-overview)
2. [Network Drivers Deep Dive](#network-drivers-deep-dive)
3. [Service Discovery & DNS](#service-discovery--dns)
4. [Load Balancing Strategies](#load-balancing-strategies)
5. [Network Security](#network-security)
6. [Production Patterns](#production-patterns)
7. [Troubleshooting Networks](#troubleshooting-networks)
8. [Real-World Scenarios](#real-world-scenarios)

---

## 🏗️ **Network Architecture Overview**

### **Docker Networking Stack**
```
┌─────────────────────────────────────────────────┐
│                Applications                     │
├─────────────────────────────────────────────────┤
│            Container Network Interface          │
├─────────────────────────────────────────────────┤
│              Docker Network Drivers             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────┐  │
│  │ bridge  │ │  host   │ │ overlay │ │ macvlan│ │  
│  └─────────┘ └─────────┘ └─────────┘ └───────┘  │
├─────────────────────────────────────────────────┤
│                Linux Networking                 │
│        (iptables, netfilter, bridge)            │
└─────────────────────────────────────────────────┘
```

### **Network Namespaces**
Each container gets its own network namespace with:
- **Isolated network stack**: Separate routing table, firewall rules
- **Virtual ethernet interfaces**: Connected to Docker networks
- **Localhost isolation**: 127.0.0.1 is container-specific
- **DNS resolution**: Container-specific /etc/resolv.conf

### **Core Networking Concepts**
```bash
# List all networks
docker network ls

# Inspect network details
docker network inspect bridge

# Create custom network
docker network create --driver bridge my-network

# Connect container to network
docker network connect my-network container_name

# Disconnect from network
docker network disconnect my-network container_name

# Remove network
docker network rm my-network
```

---

## 🚦 **Network Drivers Deep Dive**

### **1. Bridge Network (Default)**

#### **How Bridge Networks Work**
```
Host Machine
├── docker0 (bridge interface)
│   ├── veth1 ←→ Container1 (eth0: 172.17.0.2)
│   ├── veth2 ←→ Container2 (eth0: 172.17.0.3)
│   └── veth3 ←→ Container3 (eth0: 172.17.0.4)
└── Host Network (eth0: 192.168.1.100)
```

#### **Default Bridge Limitations**
```bash
# Containers on default bridge can only communicate by IP
docker run -d --name web1 nginx
docker run -d --name web2 nginx

# This won't work (no automatic DNS)
docker exec web1 ping web2  # ❌ Name resolution fails

# This works (using IP)
docker exec web1 ping 172.17.0.3  # ✅ Direct IP communication
```

#### **Custom Bridge Networks (Recommended)**
```bash
# Create custom bridge with specific subnet
docker network create \
  --driver bridge \
  --subnet=172.20.0.0/16 \
  --ip-range=172.20.240.0/20 \
  --gateway=172.20.0.1 \
  --opt com.docker.network.bridge.name=my-bridge \
  production-network

# Advanced bridge options
docker network create \
  --driver bridge \
  --subnet=192.168.100.0/24 \
  --gateway=192.168.100.1 \
  --opt com.docker.network.bridge.enable_icc=true \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  --opt com.docker.network.bridge.host_binding_ipv4=0.0.0.0 \
  advanced-bridge
```

#### **Bridge Network Best Practices**
```bash
# Use custom bridges for production
docker network create app-network

# Run containers with custom network
docker run -d \
  --name database \
  --network app-network \
  --restart unless-stopped \
  postgres:13

docker run -d \
  --name application \
  --network app-network \
  --restart unless-stopped \
  my-app:latest

# Test connectivity (DNS resolution works)
docker exec application ping database  # ✅ Works!
```

### **2. Host Network**

#### **When to Use Host Network**
- **High performance requirements**: No NAT overhead
- **Network monitoring tools**: Need access to host interfaces
- **Legacy applications**: Expecting specific network configuration

```bash
# Container uses host network stack directly
docker run -d \
  --name host-nginx \
  --network host \
  nginx

# Container binds to host ports directly
# No port mapping needed: nginx binds to host:80
```

#### **Host Network Limitations**
- **No isolation**: Containers share host network
- **Port conflicts**: Only one container per port
- **Security risk**: Direct access to host network
- **Not portable**: Host-specific network configuration

#### **Production Host Network Example**
```bash
# Monitoring container with host network access
docker run -d \
  --name node-exporter \
  --network host \
  --pid host \
  --restart unless-stopped \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  prom/node-exporter \
    --path.procfs=/host/proc \
    --path.sysfs=/host/sys
```

### **3. Overlay Networks (Swarm/Multi-Host)**

#### **Overlay Network Architecture**
```
Host 1 (Manager)          Host 2 (Worker)          Host 3 (Worker)
├── Container A          ├── Container B          ├── Container C
│   (10.0.1.2)          │   (10.0.1.3)          │   (10.0.1.4)
└── VXLAN Tunnel ←──────┼── VXLAN Tunnel ←──────┼── VXLAN Tunnel
                        │                       │
    Overlay Network: 10.0.1.0/24 (encrypted)
```

#### **Create Overlay Network**
```bash
# Initialize Docker Swarm (required for overlay)
docker swarm init

# Create overlay network
docker network create \
  --driver overlay \
  --subnet=10.0.1.0/24 \
  --encrypted \
  production-overlay

# Deploy service across multiple hosts
docker service create \
  --name web-service \
  --network production-overlay \
  --replicas 3 \
  nginx:alpine
```

#### **Overlay Network Features**
- **Multi-host communication**: Containers communicate across hosts
- **Automatic encryption**: Secure inter-host traffic
- **Service discovery**: Built-in DNS for services
- **Load balancing**: Automatic traffic distribution

### **4. Macvlan Networks**

#### **Macvlan Use Cases**
- **Legacy applications**: Need to appear as physical devices
- **Network appliances**: Firewalls, load balancers
- **DHCP clients**: Containers need DHCP-assigned IPs
- **VLAN integration**: Direct connection to VLANs

```bash
# Create macvlan network
docker network create \
  --driver macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  --opt parent=eth0 \
  macvlan-network

# Container gets IP from physical network
docker run -d \
  --name physical-device \
  --network macvlan-network \
  --ip=192.168.1.100 \
  nginx:alpine
```

#### **Macvlan Limitations**
- **Host isolation**: Host cannot communicate with macvlan containers
- **Switch requirements**: Switch must support promiscuous mode
- **IP management**: Manual IP assignment required

### **5. None Network**
```bash
# Complete network isolation
docker run -d \
  --name isolated-container \
  --network none \
  alpine sleep 3600

# Container has no network interfaces (except loopback)
docker exec isolated-container ip addr show
```

---

## 🔍 **Service Discovery & DNS**

### **Container DNS Resolution**

#### **Automatic DNS in Custom Networks**
```bash
# Create network and containers
docker network create app-network

docker run -d \
  --name postgres-db \
  --network app-network \
  -e POSTGRES_PASSWORD=secret \
  postgres:13

docker run -d \
  --name redis-cache \
  --network app-network \
  redis:alpine

docker run -d \
  --name web-app \
  --network app-network \
  -e DATABASE_URL=postgresql://postgres-db:5432/app \
  -e CACHE_URL=redis://redis-cache:6379 \
  my-webapp:latest

# Test DNS resolution
docker exec web-app nslookup postgres-db
docker exec web-app dig redis-cache
docker exec web-app cat /etc/hosts
```

#### **Network Aliases**
```bash
# Create container with multiple DNS names
docker run -d \
  --name database-server \
  --network app-network \
  --network-alias db \
  --network-alias postgres \
  --network-alias primary-db \
  postgres:13

# All these resolve to the same container
docker exec web-app ping db
docker exec web-app ping postgres
docker exec web-app ping primary-db
docker exec web-app ping database-server
```

### **Advanced DNS Configuration**

#### **Custom DNS Servers**
```bash
# Use custom DNS servers
docker run -d \
  --name custom-dns-app \
  --dns=8.8.8.8 \
  --dns=1.1.1.1 \
  --dns-search=company.internal \
  nginx:alpine

# Check DNS configuration
docker exec custom-dns-app cat /etc/resolv.conf
```

#### **DNS Options**
```bash
# Advanced DNS configuration
docker run -d \
  --name dns-optimized \
  --dns=192.168.1.1 \
  --dns-opt=timeout:3 \
  --dns-opt=attempts:2 \
  --dns-opt=ndots:1 \
  application:latest
```

### **Service Discovery Patterns**

#### **Pattern 1: Environment Variables**
```bash
# Link containers (legacy, not recommended)
docker run -d --name database postgres:13
docker run -d \
  --name app \
  --link database:db \
  -e DATABASE_HOST=db \
  my-app:latest
```

#### **Pattern 2: DNS-Based Discovery (Recommended)**
```bash
# Modern approach using DNS
docker network create service-network

docker run -d \
  --name user-service \
  --network service-network \
  --restart unless-stopped \
  user-service:latest

docker run -d \
  --name order-service \
  --network service-network \
  --restart unless-stopped \
  -e USER_SERVICE_URL=http://user-service:3000 \
  order-service:latest
```

#### **Pattern 3: External Service Discovery**
```bash
# Using Consul for service discovery
docker run -d \
  --name consul \
  --network service-network \
  -p 8500:8500 \
  consul:latest agent -server -bootstrap -ui -client=0.0.0.0

# Services register with Consul
docker run -d \
  --name api-service \
  --network service-network \
  -e CONSUL_URL=http://consul:8500 \
  api-service:latest
```

---

## ⚖️ **Load Balancing Strategies**

### **Internal Load Balancing**

#### **Docker Swarm Built-in Load Balancing**
```bash
# Create overlay network
docker network create --driver overlay lb-network

# Deploy service with multiple replicas
docker service create \
  --name web-service \
  --network lb-network \
  --replicas 3 \
  --publish 80:80 \
  nginx:alpine

# Traffic automatically distributed across replicas
# Built-in VIP (Virtual IP) load balancing
docker service ps web-service
```

#### **Round-Robin DNS**
```bash
# Multiple containers with same network alias
docker run -d --name web1 --network app-net --network-alias webapp nginx
docker run -d --name web2 --network app-net --network-alias webapp nginx
docker run -d --name web3 --network app-net --network-alias webapp nginx

# DNS queries return different IPs (round-robin)
docker exec client nslookup webapp
```

### **External Load Balancers**

#### **Nginx Load Balancer**
```bash
# Create load balancer network
docker network create lb-network

# Backend services
docker run -d --name app1 --network lb-network my-app:latest
docker run -d --name app2 --network lb-network my-app:latest
docker run -d --name app3 --network lb-network my-app:latest

# Nginx load balancer configuration
cat > nginx-lb.conf << EOF
upstream backend {
    server app1:3000;
    server app2:3000;
    server app3:3000;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Load balancer container
docker run -d \
  --name nginx-lb \
  --network lb-network \
  -p 80:80 \
  -v $(pwd)/nginx-lb.conf:/etc/nginx/conf.d/default.conf \
  nginx:alpine
```

#### **HAProxy Load Balancer**
```bash
# HAProxy configuration
cat > haproxy.cfg << EOF
global
    daemon

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend web_frontend
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /health
    server app1 app1:3000 check
    server app2 app2:3000 check
    server app3 app3:3000 check
EOF

# HAProxy container
docker run -d \
  --name haproxy-lb \
  --network lb-network \
  -p 80:80 \
  -p 8404:8404 \
  -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
  haproxy:alpine
```

### **Advanced Load Balancing**

#### **Session Affinity (Sticky Sessions)**
```nginx
# Nginx with sticky sessions
upstream backend {
    ip_hash;  # Routes based on client IP
    server app1:3000;
    server app2:3000;
    server app3:3000;
}
```

#### **Health Check Based Routing**
```bash
# Health check script
cat > health-check.sh << 'EOF'
#!/bin/bash
for server in app1 app2 app3; do
    if curl -f http://$server:3000/health > /dev/null 2>&1; then
        echo "$server is healthy"
    else
        echo "$server is unhealthy"
        # Remove from load balancer pool
    fi
done
EOF

# Health monitoring container
docker run -d \
  --name health-monitor \
  --network lb-network \
  -v $(pwd)/health-check.sh:/health-check.sh \
  alpine/curl sh -c "while true; do /health-check.sh; sleep 30; done"
```

---

## 🔒 **Network Security**

### **Network Isolation Strategies**

#### **Multi-Tier Architecture**
```bash
# Frontend network (public-facing)
docker network create \
  --driver bridge \
  --subnet=172.18.0.0/16 \
  frontend-network

# Backend network (internal only)
docker network create \
  --driver bridge \
  --internal \
  --subnet=172.19.0.0/16 \
  backend-network

# Database network (most restricted)
docker network create \
  --driver bridge \
  --internal \
  --subnet=172.20.0.0/16 \
  database-network

# Web tier (public + backend access)
docker run -d \
  --name web-server \
  --network frontend-network \
  -p 80:80 \
  nginx:alpine

docker network connect backend-network web-server

# Application tier (backend + database access)
docker run -d \
  --name app-server \
  --network backend-network \
  my-app:latest

docker network connect database-network app-server

# Database tier (isolated)
docker run -d \
  --name database \
  --network database-network \
  postgres:13
```

#### **Firewall Rules with iptables**
```bash
# Block inter-container communication on default bridge
docker run -d \
  --name isolated-app \
  --network isolated-net \
  --security-opt apparmor=docker-default \
  my-app:latest

# Custom iptables rules (advanced)
# Block traffic between specific containers
iptables -I DOCKER-USER -s 172.18.0.2 -d 172.18.0.3 -j DROP
```

### **Encrypted Communication**

#### **TLS Between Containers**
```bash
# Generate certificates for inter-service communication
docker run -d \
  --name secure-app \
  --network secure-network \
  -e TLS_CERT_PATH=/certs/server.crt \
  -e TLS_KEY_PATH=/certs/server.key \
  -v certs-volume:/certs \
  secure-app:latest

# Client with TLS verification
docker run -d \
  --name secure-client \
  --network secure-network \
  -e TLS_CA_PATH=/certs/ca.crt \
  -v certs-volume:/certs \
  secure-client:latest
```

#### **Overlay Network Encryption**
```bash
# Encrypted overlay network (Swarm mode)
docker network create \
  --driver overlay \
  --encrypted \
  --subnet=10.0.1.0/24 \
  secure-overlay

# All traffic automatically encrypted with IPSEC
```

### **Access Control**

#### **Network Policies (Docker EE/Kubernetes)**
```yaml
# Example network policy (conceptual)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-isolation
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
```

#### **Container Security Options**
```bash
# Run container with security constraints
docker run -d \
  --name secure-container \
  --network secure-network \
  --read-only \
  --tmpfs /tmp \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  nginx:alpine
```

---

## 🏭 **Production Patterns**

### **Pattern 1: Microservices Network Architecture**

```bash
# Create service-specific networks
docker network create frontend-services
docker network create backend-services  
docker network create data-services --internal

# API Gateway (public entry point)
docker run -d \
  --name api-gateway \
  --network frontend-services \
  -p 80:80 \
  -p 443:443 \
  api-gateway:latest

# Connect gateway to backend
docker network connect backend-services api-gateway

# User service
docker run -d \
  --name user-service \
  --network backend-services \
  --restart unless-stopped \
  user-service:latest

# Order service  
docker run -d \
  --name order-service \
  --network backend-services \
  --restart unless-stopped \
  order-service:latest

# Connect services to data layer
docker network connect data-services user-service
docker network connect data-services order-service

# Databases (isolated)
docker run -d \
  --name user-db \
  --network data-services \
  --restart unless-stopped \
  postgres:13

docker run -d \
  --name order-db \
  --network data-services \
  --restart unless-stopped \
  postgres:13

# Shared cache
docker run -d \
  --name redis-cache \
  --network backend-services \
  --restart unless-stopped \
  redis:alpine
```

### **Pattern 2: Blue-Green Deployment Network**

```bash
# Shared infrastructure network
docker network create infrastructure

# Blue environment
docker network create blue-env
docker run -d --name blue-app-1 --network blue-env my-app:v1
docker run -d --name blue-app-2 --network blue-env my-app:v1
docker run -d --name blue-app-3 --network blue-env my-app:v1

# Green environment
docker network create green-env
docker run -d --name green-app-1 --network green-env my-app:v2
docker run -d --name green-app-2 --network green-env my-app:v2
docker run -d --name green-app-3 --network green-env my-app:v2

# Load balancer (switch between environments)
docker run -d \
  --name load-balancer \
  --network infrastructure \
  -p 80:80 \
  -e ACTIVE_ENV=blue \
  smart-lb:latest

# Connect LB to both environments
docker network connect blue-env load-balancer
docker network connect green-env load-balancer

# Switch traffic to green
docker exec load-balancer update-config.sh --env=green
```

### **Pattern 3: Service Mesh Network**

```bash
# Service mesh control plane network
docker network create service-mesh-control

# Data plane networks
docker network create service-mesh-data

# Istio sidecar proxy pattern (conceptual)
docker run -d \
  --name app-service \
  --network service-mesh-data \
  my-app:latest

docker run -d \
  --name app-proxy \
  --network service-mesh-data \
  --network service-mesh-control \
  --pid container:app-service \
  --volumes-from app-service \
  istio/proxyv2:latest

# Service mesh provides: 
# - Automatic TLS
# - Traffic management
# - Observability
# - Security policies
```

### **Pattern 4: High Availability Network Setup**

```bash
# Multi-zone network setup
docker network create \
  --driver overlay \
  --attachable \
  --subnet=10.0.0.0/16 \
  ha-network

# Database cluster
docker service create \
  --name postgres-primary \
  --network ha-network \
  --constraint node.labels.zone==zone1 \
  --mount type=volume,source=pg-primary,target=/var/lib/postgresql/data \
  postgres:13

docker service create \
  --name postgres-replica \
  --network ha-network \
  --constraint node.labels.zone==zone2 \
  --mount type=volume,source=pg-replica,target=/var/lib/postgresql/data \
  postgres:13

# Application with multiple replicas
docker service create \
  --name web-app \
  --network ha-network \
  --replicas 6 \
  --constraint-add node.labels.zone==zone1 \
  --constraint-add node.labels.zone==zone2 \
  --constraint-add node.labels.zone==zone3 \
  web-app:latest
```

---

## 🔧 **Troubleshooting Networks**

### **Network Debugging Tools**

#### **Container Network Inspection**
```bash
# Inspect container network settings
docker inspect container_name --format='{{.NetworkSettings}}'

# View all network connections
docker inspect container_name --format='{{range .NetworkSettings.Networks}}{{.NetworkID}} {{.IPAddress}} {{.Gateway}}{{end}}'

# Check port mappings
docker port container_name

# View network statistics
docker exec container_name cat /proc/net/dev
docker exec container_name ss -tuln
```

#### **Network Connectivity Testing**
```bash
# Basic connectivity tests
docker exec container_name ping target_host
docker exec container_name telnet target_host 80
docker exec container_name curl -I http://target_host

# DNS resolution testing
docker exec container_name nslookup target_host
docker exec container_name dig target_host
docker exec container_name cat /etc/resolv.conf

# Network interface information
docker exec container_name ip addr show
docker exec container_name ip route show
docker exec container_name netstat -rn
```

#### **Advanced Network Debugging**
```bash
# Use netshoot for advanced debugging
docker run -it --rm \
  --network container:target_container \
  nicolaka/netshoot

# Or attach to container's network namespace
docker run -it --rm \
  --pid container:target_container \
  --network container:target_container \
  --cap-add SYS_ADMIN \
  nicolaka/netshoot

# Inside netshoot, you have access to:
# - tcpdump, wireshark
# - nmap, netcat
# - curl, wget
# - dig, nslookup
# - iperf3, mtr
```

### **Common Network Issues**

#### **Issue 1: Container Cannot Reach External Services**
```bash
# Check DNS resolution
docker exec container nslookup google.com

# Check routing
docker exec container ip route show

# Check iptables rules (on host)
iptables -L DOCKER-USER
iptables -L DOCKER

# Test with host network
docker run --rm --network host alpine ping google.com
```

**Solutions:**
```bash
# Fix DNS
docker run --dns=8.8.8.8 my-app

# Check firewall rules
systemctl status firewalld
ufw status

# Verify network configuration
docker network inspect bridge
```

#### **Issue 2: Containers Cannot Communicate**
```bash
# Check if containers are on same network
docker inspect container1 --format='{{.NetworkSettings.Networks}}'
docker inspect container2 --format='{{.NetworkSettings.Networks}}'

# Test connectivity by IP
docker exec container1 ping <container2_ip>

# Check network driver
docker network ls
docker network inspect network_name
```

**Solutions:**
```bash
# Connect containers to same network
docker network create shared-network
docker network connect shared-network container1
docker network connect shared-network container2

# Use custom bridge (not default)
docker network create --driver bridge custom-bridge
```

#### **Issue 3: Port Binding Failures**
```bash
# Check what's using the port
netstat -tulpn | grep :8080
ss -tulpn | grep :8080
lsof -i :8080

# Check Docker port mappings
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

**Solutions:**
```bash
# Use different port
docker run -p 8081:80 nginx

# Stop conflicting service
systemctl stop service_name

# Use random port assignment
docker run -P nginx
```

#### **Issue 4: Performance Issues**
```bash
# Check network statistics
docker exec container cat /proc/net/netstat
docker exec container iftop
docker exec container nload

# Test network performance
docker run --rm -it networkstatic/iperf3 -c target_host

# Monitor network traffic
sudo tcpdump -i docker0
```

**Solutions:**
```bash
# Use host networking for performance
docker run --network host performance-app

# Optimize network driver
docker network create --opt com.docker.network.driver.mtu=9000 jumbo-network

# Use more efficient protocols
# (HTTP/2, gRPC, binary protocols)
```

### **Monitoring and Logging**

#### **Network Monitoring Setup**
```bash
# Prometheus network monitoring
docker run -d \
  --name cadvisor \
  --network monitoring \
  -p 8080:8080 \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker/:/var/lib/docker:ro \
  google/cadvisor:latest

# Network traffic analysis
docker run -d \
  --name ntopng \
  --network host \
  --cap-add NET_ADMIN \
  -p 3000:3000 \
  ntopng/ntopng:stable
```

#### **Centralized Logging for Network Events**
```bash
# Fluentd for log aggregation
docker run -d \
  --name fluentd \
  --network logging \
  -p 24224:24224 \
  -v /var/log:/var/log \
  fluent/fluentd:latest

# Configure containers to use fluentd
docker run -d \
  --name app \
  --network app-network \
  --log-driver fluentd \
  --log-opt fluentd-address=localhost:24224 \
  --log-opt tag=myapp.{{.Name}} \
  my-app:latest
```

---

## 🎯 **Real-World Scenarios**

### **Scenario 1: E-commerce Platform Network**

```bash
# Public-facing network
docker network create \
  --driver bridge \
  --subnet=172.18.0.0/16 \
  public-network

# Internal services network
docker network create \
  --driver bridge \
  --internal \
  --subnet=172.19.0.0/16 \
  internal-network

# Data tier network (most isolated)
docker network create \
  --driver bridge \
  --internal \
  --subnet=172.20.0.0/16 \
  data-network

# CDN/Load Balancer (public entry)
docker run -d \
  --name cdn-lb \
  --network public-network \
  -p 80:80 -p 443:443 \
  --restart unless-stopped \
  nginx:alpine

# Web frontend (public + internal)
docker run -d \
  --name web-frontend \
  --network public-network \
  --restart unless-stopped \
  ecommerce-frontend:latest

docker network connect internal-network web-frontend

# API Gateway (internal + data)
docker run -d \
  --name api-gateway \
  --network internal-network \
  --restart unless-stopped \
  api-gateway:latest

docker network connect data-network api-gateway

# Microservices (internal + data)
services=(user-service product-service order-service payment-service)
for service in "${services[@]}"; do
  docker run -d \
    --name $service \
    --network internal-network \
    --restart unless-stopped \
    $service:latest
  
  docker network connect data-network $service
done

# Databases (isolated in data network)
docker run -d \
  --name postgres-users \
  --network data-network \
  --restart unless-stopped \
  -v postgres-users:/var/lib/postgresql/data \
  postgres:13

docker run -d \
  --name postgres-orders \
  --network data-network \
  --restart unless-stopped \
  -v postgres-orders:/var/lib/postgresql/data \
  postgres:13

# Cache layer
docker run -d \
  --name redis-cache \
  --network internal-network \
  --restart unless-stopped \
  redis:alpine

# Message queue
docker run -d \
  --name rabbitmq \
  --network internal-network \
  --restart unless-stopped \
  rabbitmq:3-management
```

### **Scenario 2: Development Environment with Network Isolation**

```bash
# Development networks per team
teams=(frontend backend devops)
for team in "${teams[@]}"; do
  docker network create \
    --driver bridge \
    --subnet=172.$((20+$(echo $team | wc -c))).0.0/16 \
    ${team}-dev-network
done

# Shared services network
docker network create shared-dev-services

# Shared database (accessible by all teams)
docker run -d \
  --name shared-postgres \
  --network shared-dev-services \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=devpass \
  -v postgres-dev-data:/var/lib/postgresql/data \
  postgres:13

# Frontend team containers
docker run -d \
  --name react-dev \
  --network frontend-dev-network \
  -p 3000:3000 \
  -v $(pwd)/frontend:/app \
  node:18-alpine sleep infinity

docker network connect shared-dev-services react-dev

# Backend team containers  
docker run -d \
  --name api-dev \
  --network backend-dev-network \
  -p 8080:8080 \
  -v $(pwd)/backend:/app \
  node:18-alpine sleep infinity

docker network connect shared-dev-services api-dev

# DevOps monitoring stack
docker run -d \
  --name prometheus \
  --network devops-dev-network \
  -p 9090:9090 \
  prom/prometheus

docker run -d \
  --name grafana \
  --network devops-dev-network \
  -p 3001:3000 \
  grafana/grafana

# Connect monitoring to all networks for observability
for team in "${teams[@]}"; do
  docker network connect ${team}-dev-network prometheus
done
```

---

## ✅ **Key Takeaways**

1. **Network Driver Selection**: Choose appropriate drivers for your use case
2. **Custom Networks**: Always use custom networks in production
3. **Service Discovery**: Leverage DNS-based service discovery
4. **Security Isolation**: Implement network segmentation strategies
5. **Load Balancing**: Plan for traffic distribution and high availability
6. **Monitoring**: Implement comprehensive network monitoring
7. **Troubleshooting**: Master debugging tools and techniques

---

## 🎓 **Next Steps**

Ready for **[05-docker-volumes](../05-docker-volumes/)**? You'll learn:
- Volume types and management strategies
- Data persistence patterns
- Backup and recovery procedures
- Performance optimization for storage
- Production data management

---

## 📚 **Additional Resources**

- [Docker Networking Documentation](https://docs.docker.com/network/)
- [Container Network Interface (CNI)](https://github.com/containernetworking/cni)
- [Overlay Networks Deep Dive](https://docs.docker.com/network/overlay/)
- [Network Security Best Practices](https://docs.docker.com/network/security/)
- [Troubleshooting Network Issues](https://docs.docker.com/network/troubleshooting/)
