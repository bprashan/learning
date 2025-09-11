# Docker Basics - Practical Labs

## Lab Environment Setup

### Prerequisites Checklist
- [ ] Docker Desktop installed and running
- [ ] WSL 2 enabled (Windows)
- [ ] Terminal/PowerShell access
- [ ] Internet connection for pulling images

---

## Lab 1: Docker Installation Verification

### Step 1: Verify Installation
```bash
# Check Docker version
docker --version

# Expected output: Docker version 20.x.x, build xxxxx

# Check Docker info
docker info

# Check if Docker daemon is running
docker run hello-world
```

### Expected Results
- Docker version information displays correctly
- `docker info` shows system information
- Hello-world container runs successfully

---

## Lab 2: Working with Images

### Step 1: Image Operations
```bash
# Pull different versions of Ubuntu
docker pull ubuntu:20.04
docker pull ubuntu:22.04
docker pull ubuntu:latest

# List all images
docker images

# Check image details
docker inspect ubuntu:20.04
```

### Step 2: Image Cleanup
```bash
# Remove specific image
docker rmi ubuntu:22.04

# Remove unused images
docker image prune

# Force remove image (if containers exist)
docker rmi -f ubuntu:20.04
```

---

## Lab 3: Container Operations

### Step 1: Basic Container Operations
```bash
# Run container in different modes
docker run ubuntu:20.04 echo "Hello World"           # Run and exit
docker run -it ubuntu:20.04 bash                     # Interactive mode
docker run -d ubuntu:20.04 sleep 3600                # Detached mode
```

### Step 2: Container Management
```bash
# List all containers
docker ps -a

# Start/stop containers
docker start <container_id>
docker stop <container_name>

# Rename container
docker rename <old_name> <new_name>

# Remove containers
docker rm <container_id>
```

---

## Lab 4: Real-World Web Server

### Step 1: Deploy Nginx Web Server
```bash
# Run Nginx web server
docker run -d \
  --name my-web-server \
  -p 8080:80 \
  nginx:alpine

# Verify it's running
docker ps

# Test the web server
curl http://localhost:8080
# Or open http://localhost:8080 in browser
```

### Step 2: Customize Web Content
```bash
# Copy custom HTML to container
echo "<h1>My Docker Web Server</h1>" > index.html

# Copy file to running container
docker cp index.html my-web-server:/usr/share/nginx/html/

# Verify changes
curl http://localhost:8080
```

### Step 3: Monitor Container
```bash
# View logs
docker logs my-web-server
docker logs -f my-web-server  # Follow logs

# Check resource usage
docker stats my-web-server

# Inspect container details
docker inspect my-web-server
```

---

## Lab 5: Container Networking

### Step 1: Port Mapping Variations
```bash
# Map multiple ports
docker run -d \
  --name multi-port-app \
  -p 8080:80 \
  -p 8443:443 \
  nginx:alpine

# Random port mapping
docker run -d -P nginx:alpine

# Check port mappings
docker port multi-port-app
```

### Step 2: Container Communication
```bash
# Run database container
docker run -d \
  --name my-database \
  -e POSTGRES_PASSWORD=mypassword \
  postgres:13

# Run application container linking to database
docker run -d \
  --name my-app \
  --link my-database:db \
  alpine sleep 3600

# Test connection
docker exec my-app ping db
```

---

## Lab 6: Data Management

### Step 1: Temporary Data
```bash
# Create container with temporary data
docker run -it \
  --name temp-data \
  ubuntu:20.04 bash

# Inside container:
echo "Temporary data" > /tmp/data.txt
cat /tmp/data.txt
exit

# Data is lost when container is removed
docker rm temp-data
```

### Step 2: Volume Mounting
```bash
# Create directory on host
mkdir -p /tmp/docker-data  # Linux/Mac
# md C:\temp\docker-data   # Windows

# Mount host directory
docker run -it \
  --name persistent-data \
  -v /tmp/docker-data:/data \
  ubuntu:20.04 bash

# Inside container:
echo "Persistent data" > /data/persistent.txt
exit

# Verify data persists on host
cat /tmp/docker-data/persistent.txt  # Linux/Mac
# type C:\temp\docker-data\persistent.txt  # Windows
```

---

## Lab 7: Container Lifecycle Management

### Step 1: Container States
```bash
# Create container without starting
docker create --name lifecycle-demo ubuntu:20.04 sleep 3600

# Check status
docker ps -a

# Start container
docker start lifecycle-demo

# Check running status
docker ps

# Pause container
docker pause lifecycle-demo
docker ps

# Unpause container
docker unpause lifecycle-demo

# Stop container gracefully
docker stop lifecycle-demo

# Kill container forcefully
docker kill lifecycle-demo

# Remove container
docker rm lifecycle-demo
```

---

## Lab 8: Environment Variables

### Step 1: Setting Environment Variables
```bash
# Run container with environment variables
docker run -d \
  --name env-demo \
  -e NODE_ENV=production \
  -e PORT=3000 \
  -e DEBUG=true \
  node:14-alpine sleep 3600

# Check environment variables
docker exec env-demo printenv

# Use environment file
echo "DATABASE_URL=postgresql://localhost:5432/mydb" > .env
echo "REDIS_URL=redis://localhost:6379" >> .env

docker run -d \
  --name env-file-demo \
  --env-file .env \
  alpine sleep 3600

docker exec env-file-demo printenv
```

---

## Lab 9: Resource Limits

### Step 1: Memory and CPU Limits
```bash
# Run container with resource limits
docker run -d \
  --name resource-limited \
  --memory="256m" \
  --cpus="0.5" \
  nginx:alpine

# Monitor resource usage
docker stats resource-limited

# Test memory limit (will be killed if exceeds)
docker exec resource-limited dd if=/dev/zero of=/tmp/memory_test bs=1M count=512
```

---

## Lab 10: Container Health Checks

### Step 1: Built-in Health Checks
```bash
# Run container with health check
docker run -d \
  --name healthy-nginx \
  --health-cmd="curl -f http://localhost/ || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  nginx:alpine

# Check health status
docker ps
docker inspect healthy-nginx --format='{{.State.Health.Status}}'
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: Container Exits Immediately
```bash
# Diagnosis
docker logs <container_name>
docker inspect <container_name> --format='{{.State.ExitCode}}'

# Solutions
# 1. Use interactive mode for debugging
docker run -it ubuntu:20.04 bash

# 2. Keep container running
docker run -d ubuntu:20.04 tail -f /dev/null
```

#### Issue 2: Port Already in Use
```bash
# Find process using port
netstat -tulpn | grep :8080  # Linux
netstat -ano | findstr :8080  # Windows

# Use different port
docker run -p 8081:80 nginx
```

#### Issue 3: Permission Denied
```bash
# Linux: Add user to docker group
sudo usermod -aG docker $USER
# Logout and login

# Check Docker daemon status
systemctl status docker  # Linux
```

#### Issue 4: Out of Disk Space
```bash
# Check disk usage
docker system df

# Clean up
docker system prune
docker container prune
docker image prune
docker volume prune
```

---

## Performance Tips

### 1. Optimize Container Startup
```bash
# Use alpine images (smaller)
docker run alpine:latest echo "Fast startup"

# Use specific tags (avoid latest)
docker run nginx:1.21-alpine
```

### 2. Monitor Resources
```bash
# Real-time monitoring
docker stats

# Historical data (requires monitoring setup)
docker events --since="1h"
```

### 3. Cleanup Regularly
```bash
# Weekly cleanup routine
docker system prune -f
docker volume prune -f
docker network prune -f
```

---

## Lab Completion Checklist

- [ ] Docker installation verified
- [ ] Basic image operations completed
- [ ] Container lifecycle understood
- [ ] Web server deployment successful
- [ ] Port mapping configured correctly
- [ ] Volume mounting working
- [ ] Environment variables set
- [ ] Resource limits applied
- [ ] Health checks configured
- [ ] Troubleshooting scenarios practiced

## Next Steps

After completing these labs, you should be comfortable with:
- Docker basic commands and operations
- Container lifecycle management
- Basic networking and storage concepts
- Troubleshooting common issues

**Ready for the next level?** Proceed to [02-images-containers](../02-images-containers/) for advanced image and container management!
