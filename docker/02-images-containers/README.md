# 02 - Images and Containers: Deep Dive into Docker Core

## 🎯 **Learning Objectives**
By the end of this section, you'll master:
- Docker image architecture and layers
- Container networking fundamentals
- Advanced container operations
- Image optimization techniques
- Container debugging and troubleshooting

---

## 📋 **Table of Contents**
1. [Docker Image Architecture](#docker-image-architecture)
2. [Understanding Layers](#understanding-layers)
3. [Container Networking](#container-networking)
4. [Advanced Container Operations](#advanced-container-operations)
5. [Image Optimization](#image-optimization)
6. [Container Debugging](#container-debugging)
7. [Practical Scenarios](#practical-scenarios)
8. [Performance Optimization](#performance-optimization)

---

## 🏗️ **Docker Image Architecture**

### **Image Structure**
Docker images are built using a **layered file system** where each layer represents a set of file changes.

```
┌─────────────────────────────────────┐ ← Container Layer (R/W)
├─────────────────────────────────────┤
│         Application Layer           │ ← your app code
├─────────────────────────────────────┤
│         Dependencies Layer          │ ← npm install, pip install
├─────────────────────────────────────┤
│         Runtime Layer               │ ← Node.js, Python, etc.
├─────────────────────────────────────┤
│         OS Package Layer            │ ← apt-get, apk add
├─────────────────────────────────────┤
│         Base OS Layer               │ ← Ubuntu, Alpine, etc.
└─────────────────────────────────────┘
```

### **Union File System (UFS)**
- **Read-Only Layers**: All image layers are immutable
- **Copy-on-Write**: Container layer handles file modifications
- **Layer Sharing**: Multiple containers can share base layers

### **Image Inspection**
```bash
# View image layers
docker history nginx:alpine

# Detailed image information
docker inspect nginx:alpine

# Layer details with dive tool
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest nginx:alpine
```

---

## 📚 **Understanding Layers**

### **Layer Creation Process**
Each Dockerfile instruction creates a new layer:

```dockerfile
FROM ubuntu:20.04                    # Layer 1: Base OS
RUN apt-get update                   # Layer 2: Package update
RUN apt-get install -y python3      # Layer 3: Python installation
COPY app.py /app/                    # Layer 4: Application code
RUN pip3 install flask              # Layer 5: Dependencies
```

### **Layer Caching**
Docker caches layers to speed up builds:

```bash
# First build - all layers created
docker build -t myapp:v1 .

# Second build - uses cached layers if no changes
docker build -t myapp:v2 .
```

### **Cache Optimization Strategies**

#### **❌ Poor Layer Ordering:**
```dockerfile
FROM node:14-alpine
COPY . /app
WORKDIR /app
RUN npm install              # This layer rebuilds every code change
CMD ["node", "server.js"]
```

#### **✅ Optimized Layer Ordering:**
```dockerfile
FROM node:14-alpine
WORKDIR /app
COPY package*.json ./        # Copy dependencies first
RUN npm install              # Cache this layer
COPY . .                     # Copy code last
CMD ["node", "server.js"]
```

### **Layer Analysis Commands**
```bash
# Show image layers with sizes
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Analyze layer content
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest <image_name>

# Export image layers
docker save nginx:alpine | tar -tv
```

---

## 🌐 **Container Networking**

### **Network Drivers Overview**

| Driver | Use Case | Isolation | Performance |
|--------|----------|-----------|-------------|
| **bridge** | Single host, containers communicate | Medium | Good |
| **host** | Container uses host network | None | Best |
| **none** | Complete network isolation | Complete | N/A |
| **overlay** | Multi-host communication | High | Good |
| **macvlan** | Container appears as physical device | High | Best |

### **Default Bridge Network**
```bash
# List networks
docker network ls

# Inspect default bridge
docker network inspect bridge

# Run containers on default bridge
docker run -d --name web1 nginx
docker run -d --name web2 nginx

# Test connectivity (containers can communicate by IP)
docker exec web1 ping <web2_ip>
```

### **Custom Bridge Networks**
```bash
# Create custom network
docker network create \
  --driver bridge \
  --subnet=172.20.0.0/16 \
  --ip-range=172.20.240.0/20 \
  my-network

# Run containers on custom network
docker run -d --name app1 --network my-network nginx
docker run -d --name app2 --network my-network nginx

# Test DNS resolution (containers can communicate by name)
docker exec app1 ping app2
docker exec app1 nslookup app2
```

### **Advanced Networking Features**

#### **Port Publishing**
```bash
# Publish specific port
docker run -d -p 8080:80 nginx

# Publish to specific interface
docker run -d -p 127.0.0.1:8080:80 nginx

# Publish range of ports
docker run -d -p 8080-8090:8080-8090 nginx

# Publish all exposed ports randomly
docker run -d -P nginx
```

#### **Network Aliases**
```bash
# Create container with network alias
docker run -d \
  --name database \
  --network my-network \
  --network-alias db \
  --network-alias postgres \
  postgres:13

# Other containers can connect using aliases
docker run -d \
  --name app \
  --network my-network \
  -e DATABASE_URL=postgresql://db:5432/myapp \
  my-app:latest
```

#### **Multiple Networks**
```bash
# Create multiple networks
docker network create frontend
docker network create backend

# Connect container to multiple networks
docker run -d --name app \
  --network frontend \
  nginx

docker network connect backend app

# Verify connections
docker inspect app --format='{{range .NetworkSettings.Networks}}{{.NetworkID}} {{end}}'
```

### **Container-to-Container Communication**

#### **Same Network Communication**
```bash
# Create application network
docker network create app-network

# Database container
docker run -d \
  --name postgres-db \
  --network app-network \
  -e POSTGRES_PASSWORD=secret \
  postgres:13

# Application container
docker run -d \
  --name web-app \
  --network app-network \
  -p 8080:3000 \
  -e DATABASE_URL=postgresql://postgres-db:5432/app \
  my-web-app:latest

# Redis cache container
docker run -d \
  --name redis-cache \
  --network app-network \
  redis:alpine

# Test connectivity
docker exec web-app ping postgres-db
docker exec web-app ping redis-cache
```

---

## 🔧 **Advanced Container Operations**

### **Container Resource Management**

#### **CPU Limits**
```bash
# Limit CPU usage
docker run -d \
  --name cpu-limited \
  --cpus="1.5" \
  --cpu-shares=1024 \
  stress-cpu-app

# CPU affinity (bind to specific cores)
docker run -d \
  --name cpu-pinned \
  --cpuset-cpus="0,2" \
  stress-cpu-app
```

#### **Memory Limits**
```bash
# Set memory limit
docker run -d \
  --name memory-limited \
  --memory="512m" \
  --memory-swap="1g" \
  memory-intensive-app

# OOM kill behavior
docker run -d \
  --name no-oom-kill \
  --memory="256m" \
  --oom-kill-disable \
  app-with-memory-leaks
```

#### **Disk I/O Limits**
```bash
# Limit read/write IOPS
docker run -d \
  --name io-limited \
  --device-read-iops /dev/sda:100 \
  --device-write-iops /dev/sda:100 \
  io-intensive-app

# Limit bandwidth
docker run -d \
  --name bandwidth-limited \
  --device-read-bps /dev/sda:10mb \
  --device-write-bps /dev/sda:10mb \
  backup-app
```

### **Container Security**

#### **User Namespace Mapping**
```bash
# Run as specific user
docker run -d \
  --name secure-app \
  --user 1000:1000 \
  nginx

# Map user namespace
docker run -d \
  --name user-mapped \
  --userns=host \
  nginx
```

#### **Capabilities**
```bash
# Drop all capabilities
docker run -d \
  --name no-caps \
  --cap-drop=ALL \
  nginx

# Add specific capabilities
docker run -d \
  --name specific-caps \
  --cap-drop=ALL \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_TIME \
  network-app
```

#### **Read-only Filesystem**
```bash
# Make root filesystem read-only
docker run -d \
  --name readonly-app \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/run \
  nginx
```

### **Container Restart Policies**
```bash
# Never restart
docker run -d --restart=no nginx

# Always restart
docker run -d --restart=always nginx

# Restart unless stopped manually
docker run -d --restart=unless-stopped nginx

# Restart on failure (max 3 times)
docker run -d --restart=on-failure:3 nginx
```

---

## 🚀 **Image Optimization**

### **Base Image Selection**

#### **Size Comparison**
```bash
# Check image sizes
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Popular base images (sizes vary)
ubuntu:20.04     ~72MB
alpine:3.15      ~5.6MB
scratch          ~0MB (empty)
distroless       ~20MB
```

#### **Multi-Stage Build Example**
```dockerfile
# ❌ Single stage (large final image)
FROM node:16
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
CMD ["node", "dist/server.js"]

# ✅ Multi-stage (optimized final image)
# Build stage
FROM node:16-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Production stage
FROM node:16-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY dist ./dist
USER node
CMD ["node", "dist/server.js"]
```

### **Layer Optimization Techniques**

#### **Combine RUN Instructions**
```dockerfile
# ❌ Multiple layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean

# ✅ Single layer
RUN apt-get update && \
    apt-get install -y curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

#### **Use .dockerignore**
```dockerignore
# .dockerignore file
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.nyc_output
coverage
.nyc_output
```

### **Image Security Scanning**
```bash
# Using Docker Scout (built-in)
docker scout quickview nginx:alpine
docker scout cves nginx:alpine

# Using Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image nginx:alpine

# Using Snyk
docker scan nginx:alpine
```

---

## 🔍 **Container Debugging**

### **Container Inspection Commands**
```bash
# Detailed container information
docker inspect container_name

# Process list inside container
docker top container_name

# File changes in container
docker diff container_name

# Resource usage statistics
docker stats container_name

# Container events
docker events --filter container=container_name
```

### **Log Management**
```bash
# View logs with timestamps
docker logs -t container_name

# Follow logs (tail -f equivalent)
docker logs -f container_name

# Show last N lines
docker logs --tail 50 container_name

# Show logs since specific time
docker logs --since 2022-01-01T00:00:00 container_name
docker logs --since 2h container_name

# Filter logs by level (if structured)
docker logs container_name 2>&1 | grep ERROR
```

### **Debugging Techniques**

#### **Interactive Debugging**
```bash
# Start shell in running container
docker exec -it container_name bash
docker exec -it container_name sh  # for Alpine

# Start debugging container with same image
docker run -it --rm nginx:alpine sh

# Debug with additional tools
docker run -it --rm \
  --pid container:target_container \
  --network container:target_container \
  nicolaka/netshoot
```

#### **File System Debugging**
```bash
# Copy files from container
docker cp container_name:/app/logs/error.log ./

# Copy files to container
docker cp debug-script.sh container_name:/tmp/

# Mount debugging volume
docker run -it --rm \
  -v /var/log:/host-logs \
  ubuntu:20.04 bash
```

#### **Network Debugging**
```bash
# Check network connectivity
docker exec container_name ping google.com
docker exec container_name curl -I http://api.example.com
docker exec container_name netstat -tuln

# DNS debugging
docker exec container_name nslookup database
docker exec container_name cat /etc/resolv.conf

# Port debugging
docker exec container_name telnet database 5432
```

### **Performance Debugging**
```bash
# CPU and memory usage
docker stats --no-stream container_name

# Process monitoring inside container
docker exec container_name top
docker exec container_name ps aux

# Disk usage
docker exec container_name df -h
docker exec container_name du -sh /app

# Network traffic
docker exec container_name ss -tuln
```

---

## 🎯 **Practical Scenarios**

### **Scenario 1: Multi-Tier Application**
```bash
# Create application network
docker network create webapp-network

# Database tier
docker run -d \
  --name postgres-db \
  --network webapp-network \
  -e POSTGRES_DB=webapp \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret123 \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:13

# Cache tier
docker run -d \
  --name redis-cache \
  --network webapp-network \
  redis:alpine

# Application tier
docker run -d \
  --name web-app \
  --network webapp-network \
  -p 8080:3000 \
  -e DATABASE_URL=postgresql://admin:secret123@postgres-db:5432/webapp \
  -e REDIS_URL=redis://redis-cache:6379 \
  my-webapp:latest

# Load balancer tier
docker run -d \
  --name nginx-lb \
  --network webapp-network \
  -p 80:80 \
  -v ./nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine
```

### **Scenario 2: Development Environment**
```bash
# Create development network
docker network create dev-network

# Development database with persistent data
docker run -d \
  --name dev-postgres \
  --network dev-network \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=devpass \
  -v dev-postgres-data:/var/lib/postgresql/data \
  postgres:13

# Development application with live reload
docker run -d \
  --name dev-app \
  --network dev-network \
  -p 3000:3000 \
  -v $(pwd)/src:/app/src \
  -v /app/node_modules \
  -e NODE_ENV=development \
  my-app:dev

# Development tools container
docker run -it --rm \
  --name dev-tools \
  --network dev-network \
  -v $(pwd):/workspace \
  -w /workspace \
  node:16-alpine sh
```

### **Scenario 3: Microservices Architecture**
```bash
# Service mesh network
docker network create microservices

# User service
docker run -d \
  --name user-service \
  --network microservices \
  -e PORT=3001 \
  -e DATABASE_URL=postgresql://user-db:5432/users \
  user-service:latest

# Order service
docker run -d \
  --name order-service \
  --network microservices \
  -e PORT=3002 \
  -e USER_SERVICE_URL=http://user-service:3001 \
  order-service:latest

# API Gateway
docker run -d \
  --name api-gateway \
  --network microservices \
  -p 8080:80 \
  -e USER_SERVICE=http://user-service:3001 \
  -e ORDER_SERVICE=http://order-service:3002 \
  api-gateway:latest
```

---

## ⚡ **Performance Optimization**

### **Container Performance Tuning**

#### **Memory Optimization**
```bash
# Set memory limits with swap
docker run -d \
  --memory="1g" \
  --memory-swap="2g" \
  --memory-swappiness=60 \
  memory-app

# Disable swap completely
docker run -d \
  --memory="1g" \
  --memory-swap="1g" \
  memory-app
```

#### **CPU Optimization**
```bash
# CPU quota (microseconds per 100ms)
docker run -d \
  --cpu-period=100000 \
  --cpu-quota=150000 \
  cpu-app  # 1.5 CPUs

# Real-time priority
docker run -d \
  --cpu-rt-runtime=950000 \
  --cpu-rt-period=1000000 \
  realtime-app
```

#### **I/O Optimization**
```bash
# Block I/O weight (relative)
docker run -d \
  --blkio-weight 500 \
  --device-write-bps /dev/sda:50mb \
  io-app
```

### **Image Build Performance**

#### **Build Cache Optimization**
```dockerfile
# Use build cache effectively
FROM node:16-alpine

# Install system dependencies (rarely change)
RUN apk add --no-cache git python3 make g++

# Copy package files first (for dependency caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy source code last (changes frequently)
COPY src ./src
```

#### **Parallel Builds**
```bash
# Build with BuildKit (parallel processing)
DOCKER_BUILDKIT=1 docker build -t myapp .

# Multi-platform builds
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myapp:latest \
  --push .
```

---

## 📊 **Monitoring and Metrics**

### **Resource Monitoring**
```bash
# Real-time stats
docker stats

# Export stats to file
docker stats --no-stream > container-stats.txt

# Custom format
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
```

### **Health Checks**
```bash
# Built-in health check
docker run -d \
  --name healthy-app \
  --health-cmd="curl -f http://localhost:3000/health || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  web-app

# Check health status
docker inspect healthy-app --format='{{.State.Health.Status}}'
```

---

## 🧪 **Advanced Labs**

### **Lab 1: Layer Analysis**
```bash
# Build test image with multiple layers
cat > Dockerfile << EOF
FROM alpine:3.15
RUN apk add --no-cache curl
RUN apk add --no-cache git
RUN echo "Layer 3" > /tmp/file1
RUN echo "Layer 4" > /tmp/file2
COPY . /app
EOF

# Build and analyze
docker build -t layer-test .
docker history layer-test
docker inspect layer-test
```

### **Lab 2: Network Security**
```bash
# Create isolated networks
docker network create --internal backend
docker network create frontend

# Backend services (no external access)
docker run -d --name database --network backend postgres:13
docker run -d --name cache --network backend redis:alpine

# Application (bridge between networks)
docker run -d --name app --network frontend myapp:latest
docker network connect backend app

# Frontend (external access)
docker run -d --name nginx --network frontend -p 80:80 nginx
```

### **Lab 3: Performance Testing**
```bash
# CPU stress test
docker run -d \
  --name cpu-stress \
  --cpus="0.5" \
  --memory="256m" \
  stress:latest stress --cpu 2 --timeout 60s

# Monitor performance
docker stats cpu-stress

# Network performance test
docker run -it --rm networkstatic/iperf3 -c iperf.he.net
```

---

## ✅ **Key Takeaways**

1. **Layer Understanding**: Master Docker's layered architecture for optimization
2. **Network Mastery**: Configure custom networks for service communication
3. **Resource Management**: Set appropriate limits for production workloads
4. **Security Practices**: Apply security principles from container creation
5. **Debugging Skills**: Use built-in tools for effective troubleshooting
6. **Performance Tuning**: Optimize for specific workload requirements

---

## 🎓 **Next Steps**

Ready for **[03-dockerfile-basics](../03-dockerfile-basics/)**? You'll learn:
- Advanced Dockerfile instructions
- Multi-stage build patterns
- Security hardening techniques
- Best practices for production images

---

## 📚 **Additional Resources**

- [Docker Network Documentation](https://docs.docker.com/network/)
- [Image Layer Explorer - Dive](https://github.com/wagoodman/dive)
- [Container Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Docker Performance Tuning](https://docs.docker.com/config/containers/resource_constraints/)
