# 01 - Docker Basics: Foundation for Container Mastery

## 🎯 **Learning Objectives**
By the end of this section, you'll understand:
- Docker architecture and core concepts
- Docker installation and setup
- Basic Docker commands and workflow
- Docker vs Virtual Machines
- Container lifecycle management

---

## 📋 **Table of Contents**
1. [What is Docker?](#what-is-docker)
2. [Docker Architecture](#docker-architecture)
3. [Installation Guide](#installation-guide)
4. [Essential Docker Commands](#essential-docker-commands)
5. [Container Lifecycle](#container-lifecycle)
6. [Hands-On Labs](#hands-on-labs)
7. [Best Practices](#best-practices)
8. [Common Issues & Troubleshooting](#troubleshooting)

---

## 🐳 **What is Docker?**

Docker is a **containerization platform** that packages applications and their dependencies into lightweight, portable containers that can run consistently across different environments.

### **Key Benefits:**
- **Consistency**: "Works on my machine" → "Works everywhere"
- **Efficiency**: Lighter than VMs, faster startup times
- **Scalability**: Easy horizontal scaling
- **Isolation**: Process and resource isolation
- **Portability**: Run anywhere Docker is installed

### **Docker vs Virtual Machines**

| Aspect | Docker Containers | Virtual Machines |
|--------|-------------------|------------------|
| **OS Overhead** | Shares host OS kernel | Full OS per VM |
| **Resource Usage** | Minimal (~MB) | Heavy (~GB) |
| **Startup Time** | Seconds | Minutes |
| **Isolation Level** | Process-level | Hardware-level |
| **Portability** | High | Medium |

---

## 🏗️ **Docker Architecture**

```
┌─────────────────────────────────────────┐
│              Docker Client              │
│         (docker CLI commands)           │
└─────────────────┬───────────────────────┘
                  │ REST API
                  ▼
┌─────────────────────────────────────────┐
│              Docker Daemon              │
│              (dockerd)                  │
├─────────────────────────────────────────┤
│  Images  │ Containers │ Networks │ Volumes│
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│              Docker Registry            │
│            (Docker Hub, etc.)           │
└─────────────────────────────────────────┘
```

### **Core Components:**

#### **1. Docker Client**
- Command-line interface (CLI)
- Communicates with Docker daemon via REST API
- Can connect to remote Docker daemons

#### **2. Docker Daemon (dockerd)**
- Background service managing Docker objects
- Handles container lifecycle, images, networks, volumes
- Listens for Docker API requests

#### **3. Docker Images**
- Read-only templates for creating containers
- Built from Dockerfile instructions
- Stored in layers using Union File System

#### **4. Docker Containers**
- Running instances of Docker images
- Isolated processes with their own filesystem
- Can be started, stopped, moved, and deleted

#### **5. Docker Registry**
- Centralized storage for Docker images
- Docker Hub is the default public registry
- Can use private registries for enterprise

---

## 💻 **Installation Guide**

### **Windows Installation**

#### **Docker Desktop for Windows**
```powershell
# Method 1: Download from official site
# Visit: https://docs.docker.com/desktop/install/windows-install/

# Method 2: Using Chocolatey
choco install docker-desktop

# Method 3: Using winget
winget install Docker.DockerDesktop
```

#### **Prerequisites:**
- Windows 10/11 64-bit Pro, Enterprise, or Education
- WSL 2 feature enabled
- BIOS-level hardware virtualization support

#### **Enable WSL 2:**
```powershell
# Enable WSL and Virtual Machine Platform
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart and set WSL 2 as default
wsl --set-default-version 2

# Install Ubuntu (optional but recommended)
wsl --install -d Ubuntu
```

### **Verify Installation**
```bash
# Check Docker version
docker --version

# Check Docker info
docker info

# Test with hello-world
docker run hello-world
```

---

## ⚡ **Essential Docker Commands**

### **Image Management**
```bash
# List local images
docker images
docker image ls

# Search for images in registry
docker search nginx

# Pull image from registry
docker pull nginx:latest
docker pull ubuntu:20.04

# Remove images
docker rmi nginx:latest
docker image rm ubuntu:20.04

# Remove unused images
docker image prune

# Build image from Dockerfile
docker build -t myapp:v1.0 .

# Tag an image
docker tag myapp:v1.0 myapp:latest

# Push image to registry
docker push myapp:v1.0
```

### **Container Management**
```bash
# Run containers
docker run nginx                          # Foreground
docker run -d nginx                       # Background (detached)
docker run -it ubuntu bash               # Interactive with terminal
docker run -p 8080:80 nginx              # Port mapping
docker run --name webserver nginx        # Custom name

# List containers
docker ps                                 # Running containers
docker ps -a                             # All containers
docker container ls                       # Same as docker ps

# Container operations
docker start container_name               # Start stopped container
docker stop container_name                # Graceful stop
docker kill container_name                # Force stop
docker restart container_name             # Restart container

# Execute commands in running container
docker exec -it container_name bash      # Interactive bash
docker exec container_name ls -la        # Run single command

# View container logs
docker logs container_name                # Show logs
docker logs -f container_name             # Follow logs (tail -f)
docker logs --since 2h container_name     # Logs since 2 hours ago

# Container inspection
docker inspect container_name             # Detailed container info
docker stats                             # Live resource usage
docker top container_name                # Running processes

# Remove containers
docker rm container_name                  # Remove stopped container
docker rm -f container_name               # Force remove running container
docker container prune                    # Remove all stopped containers
```

### **System Management**
```bash
# Docker system information
docker info                              # System-wide information
docker version                           # Docker version details

# Disk usage
docker system df                         # Show docker disk usage
docker system df -v                      # Verbose disk usage

# Clean up
docker system prune                      # Remove unused data
docker system prune -a                   # Remove all unused data
docker system prune --volumes            # Include volumes in cleanup

# Resource monitoring
docker stats                             # Live resource usage
docker events                            # Real-time events
```

---

## 🔄 **Container Lifecycle**

```
┌─────────────┐    docker run     ┌─────────────┐
│   Image     │ ───────────────► │   Created   │
└─────────────┘                  └─────────────┘
                                         │
                                         ▼
                                 ┌─────────────┐
                                 │   Running   │
                                 └─────────────┘
                                    │       ▲
                           docker   │       │ docker
                           stop     │       │ start
                                    ▼       │
                                 ┌─────────────┐    docker rm    ┌─────────────┐
                                 │   Stopped   │ ──────────────► │   Deleted   │
                                 └─────────────┘                 └─────────────┘
```

### **States Explained:**
- **Created**: Container created but not started
- **Running**: Container is executing processes
- **Stopped**: Container stopped gracefully or forcefully
- **Deleted**: Container removed from system

---

## 🧪 **Hands-On Labs**

### **Lab 1: Your First Container**
```bash
# 1. Run a simple web server
docker run -d -p 8080:80 --name my-nginx nginx

# 2. Verify it's running
docker ps

# 3. Test the web server
# Open browser: http://localhost:8080

# 4. View logs
docker logs my-nginx

# 5. Execute command inside container
docker exec -it my-nginx bash
ls -la
exit

# 6. Stop and remove
docker stop my-nginx
docker rm my-nginx
```

### **Lab 2: Interactive Container**
```bash
# 1. Run interactive Ubuntu container
docker run -it --name my-ubuntu ubuntu:20.04 bash

# 2. Inside the container, run:
apt update
apt install -y curl
curl --version
exit

# 3. Start the stopped container
docker start my-ubuntu

# 4. Attach to it
docker exec -it my-ubuntu bash

# 5. Clean up
exit
docker rm -f my-ubuntu
```

### **Lab 3: Container with Volume**
```bash
# 1. Create a container with volume
docker run -d -v /tmp/data:/data --name data-container ubuntu:20.04 sleep 3600

# 2. Write data to volume
docker exec data-container bash -c "echo 'Hello Docker!' > /data/message.txt"

# 3. Read data from host
cat /tmp/data/message.txt  # Linux/Mac
type C:\tmp\data\message.txt  # Windows

# 4. Clean up
docker rm -f data-container
```

---

## ✅ **Best Practices**

### **1. Resource Management**
```bash
# Limit container resources
docker run -d --memory="512m" --cpus="1.0" nginx

# Set restart policy
docker run -d --restart=unless-stopped nginx
```

### **2. Naming Convention**
```bash
# Use descriptive names
docker run --name web-frontend nginx
docker run --name api-backend node:14
docker run --name db-postgres postgres:13
```

### **3. Logging**
```bash
# Configure log driver
docker run -d --log-driver=json-file --log-opt max-size=10m nginx

# View logs with timestamps
docker logs -t container_name
```

### **4. Security**
```bash
# Run as non-root user
docker run -d --user 1000:1000 nginx

# Read-only filesystem
docker run -d --read-only nginx

# No new privileges
docker run -d --security-opt=no-new-privileges nginx
```

---

## 🔧 **Common Issues & Troubleshooting**

### **Issue 1: Docker Daemon Not Running**
```bash
# Symptoms:
# "Cannot connect to the Docker daemon"

# Solution:
# Windows: Start Docker Desktop
# Linux: sudo systemctl start docker
```

### **Issue 2: Port Already in Use**
```bash
# Symptoms:
# "Port 8080 is already in use"

# Solutions:
# 1. Use different port
docker run -p 8081:80 nginx

# 2. Find process using port
netstat -tulpn | grep :8080  # Linux
netstat -ano | findstr :8080  # Windows

# 3. Stop conflicting service
```

### **Issue 3: Out of Disk Space**
```bash
# Check disk usage
docker system df

# Clean up
docker system prune -a
docker volume prune
```

### **Issue 4: Container Exits Immediately**
```bash
# Check exit code
docker ps -a

# View logs
docker logs container_name

# Common causes:
# - Process completes immediately
# - Missing CMD/ENTRYPOINT
# - Application crashes
```

### **Issue 5: Permission Denied**
```bash
# Linux: Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again

# Windows: Run as Administrator
# Or ensure Docker Desktop is running
```

---

## 📚 **Key Takeaways**

1. **Docker Architecture**: Understand client-daemon architecture
2. **Container vs Images**: Images are templates, containers are running instances  
3. **Lifecycle Management**: Master start, stop, restart, remove operations
4. **Basic Commands**: Know image and container management commands
5. **Troubleshooting**: Common issues and their solutions

---

## 🎓 **Next Steps**

Move on to **[02-images-containers](../02-images-containers/)** to dive deeper into:
- Image layers and caching
- Container networking basics
- Advanced container operations
- Image optimization techniques

---

## 📖 **Additional Resources**

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Hub Registry](https://hub.docker.com/)
- [Docker Desktop Manual](https://docs.docker.com/desktop/)
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)

**Remember**: Practice makes perfect! Try all the hands-on labs and experiment with different containers.
