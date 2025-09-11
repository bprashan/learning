# 11 - Docker Internals: Deep Architecture Dive

## 🎯 **Learning Objectives**
Master Docker's internal architecture and implementation:
- Docker daemon and client architecture
- Container runtime internals (runc, containerd)
- Linux kernel features and namespaces
- Storage drivers and filesystem layers
- Network implementation details
- Performance optimization and troubleshooting

---

## 📋 **Table of Contents**
1. [Docker Architecture Overview](#docker-architecture-overview)
2. [Container Runtime Stack](#container-runtime-stack)
3. [Linux Kernel Features](#linux-kernel-features)
4. [Storage Drivers Deep Dive](#storage-drivers-deep-dive)
5. [Networking Implementation](#networking-implementation)
6. [Image and Layer Management](#image-and-layer-management)
7. [Performance Analysis](#performance-analysis)
8. [Advanced Troubleshooting](#advanced-troubleshooting)

---

## 🏗️ **Docker Architecture Overview**

### **Complete Docker Stack**
```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Client (CLI)                     │
│                 docker build, run, pull, push              │
└─────────────────────┬───────────────────────────────────────┘
                      │ REST API / Unix Socket
┌─────────────────────▼───────────────────────────────────────┐
│                    Docker Daemon (dockerd)                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │   Images    │ │  Networks   │ │       Volumes           │ │
│  │ Management  │ │ Management  │ │     Management          │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────┘
                      │ Container Runtime API
┌─────────────────────▼───────────────────────────────────────┐
│                    containerd                              │
│        High-level container runtime                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │   Image     │ │ Container   │ │       Snapshot          │ │
│  │  Service    │ │  Service    │ │       Service           │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────┘
                      │ Runtime v2 API (shim)
┌─────────────────────▼───────────────────────────────────────┐
│                      runc                                  │
│           Low-level container runtime                      │
│                  (OCI Runtime)                            │
└─────────────────────┬───────────────────────────────────────┘
                      │ Linux Kernel Syscalls
┌─────────────────────▼───────────────────────────────────────┐
│                   Linux Kernel                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │ Namespaces  │ │   Cgroups   │ │      Capabilities       │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │   SELinux   │ │  AppArmor   │ │       Seccomp           │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### **Docker Daemon Internal Components**
```go
// Simplified Docker daemon architecture
type Daemon struct {
    // Core services
    containerStore   *container.Store
    imageService     *images.ImageService
    networkController *libnetwork.Controller
    volumeService    *volumeService
    
    // Runtime
    containerdCli    *containerd.Client
    
    // Storage
    graphDriver      graphdriver.Driver
    imageStore       image.Store
    layerStore       layer.Store
    
    // Configuration
    configStore      *config.Config
    registryService  *registry.Service
    
    // Events and logs
    eventsService    *events.Events
    logDriver        logger.Logger
}
```

### **Component Communication Flow**
```bash
# 1. Docker CLI command
docker run -it ubuntu:20.04 /bin/bash

# 2. REST API call to dockerd
POST /containers/create
{
  "Image": "ubuntu:20.04",
  "Cmd": ["/bin/bash"],
  "AttachStdin": true,
  "AttachStdout": true,
  "AttachStderr": true,
  "Tty": true
}

# 3. dockerd processes request
# - Validates image exists
# - Creates container configuration
# - Calls containerd API

# 4. containerd creates container
# - Prepares rootfs snapshot
# - Creates OCI runtime spec
# - Spawns runc via shim

# 5. runc executes container
# - Creates namespaces
# - Sets up cgroups
# - Executes container process
```

---

## 🔧 **Container Runtime Stack**

### **containerd Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                     containerd                             │
├─────────────────────────────────────────────────────────────┤
│  gRPC API Server                                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │   Images    │ │ Containers  │ │       Content           │ │
│  │   Service   │ │   Service   │ │       Service           │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │ Snapshots   │ │    Tasks    │ │       Events            │ │
│  │  Service    │ │   Service   │ │       Service           │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  Runtime Manager                                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │ Runtime v2  │ │    Shim     │ │     OCI Runtime         │ │
│  │   Plugin    │ │  Manager    │ │    (runc/kata)          │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### **OCI Runtime Specification**
```json
{
  "ociVersion": "1.0.2",
  "process": {
    "user": {
      "uid": 0,
      "gid": 0
    },
    "args": ["/bin/bash"],
    "env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
      "TERM=xterm"
    ],
    "cwd": "/",
    "capabilities": {
      "bounding": ["CAP_AUDIT_WRITE", "CAP_KILL", "CAP_NET_BIND_SERVICE"],
      "effective": ["CAP_AUDIT_WRITE", "CAP_KILL", "CAP_NET_BIND_SERVICE"],
      "inheritable": ["CAP_AUDIT_WRITE", "CAP_KILL", "CAP_NET_BIND_SERVICE"],
      "permitted": ["CAP_AUDIT_WRITE", "CAP_KILL", "CAP_NET_BIND_SERVICE"]
    },
    "rlimits": [
      {
        "type": "RLIMIT_NOFILE",
        "hard": 1024,
        "soft": 1024
      }
    ]
  },
  "root": {
    "path": "rootfs",
    "readonly": false
  },
  "hostname": "container-host",
  "mounts": [
    {
      "destination": "/proc",
      "type": "proc",
      "source": "proc"
    },
    {
      "destination": "/dev",
      "type": "tmpfs",
      "source": "tmpfs",
      "options": ["nosuid", "strictatime", "mode=755", "size=65536k"]
    }
  ],
  "linux": {
    "namespaces": [
      {"type": "pid"},
      {"type": "network"},
      {"type": "ipc"},
      {"type": "uts"},
      {"type": "mount"}
    ],
    "cgroupsPath": "/docker/container-id",
    "resources": {
      "memory": {
        "limit": 536870912,
        "swap": 536870912
      },
      "cpu": {
        "shares": 1024,
        "quota": 100000,
        "period": 100000
      }
    },
    "seccomp": {
      "defaultAction": "SCMP_ACT_ERRNO",
      "architectures": ["SCMP_ARCH_X86_64"],
      "syscalls": [
        {
          "names": ["read", "write", "open", "close"],
          "action": "SCMP_ACT_ALLOW"
        }
      ]
    }
  }
}
```

### **Runtime Lifecycle Management**
```bash
# Check containerd processes
sudo ctr containers list

# Create container with containerd directly
sudo ctr image pull docker.io/library/ubuntu:20.04
sudo ctr container create docker.io/library/ubuntu:20.04 test-container

# Create task (running container)
sudo ctr task start -d test-container

# Execute commands in container
sudo ctr task exec --exec-id bash-session -t test-container /bin/bash

# Container process tree
ps aux | grep containerd
```

---

## 🐧 **Linux Kernel Features**

### **Namespaces Deep Dive**

#### **Process (PID) Namespace**
```bash
# Check PID namespace
ls -la /proc/self/ns/
lrwxrwxrwx 1 root root 0 Dec  7 10:30 pid -> 'pid:[4026531836]'

# Create new PID namespace
sudo unshare --pid --fork --mount-proc /bin/bash

# Inside new namespace
ps aux  # Shows only processes in this namespace

# Parent can see all processes
ps aux | grep unshare
```

#### **Network Namespace Investigation**
```bash
# List network namespaces
sudo ip netns list

# Create network namespace
sudo ip netns add test-ns

# Execute in namespace
sudo ip netns exec test-ns ip addr show

# Container network namespace
docker run -d --name test nginx
CONTAINER_ID=$(docker inspect -f '{{.Id}}' test)
CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' test)

# Enter container's network namespace
sudo nsenter -t $CONTAINER_PID -n ip addr show
```

#### **Mount Namespace Analysis**
```bash
# Check mount namespace
sudo findmnt -D | head -20

# Container mount propagation
docker run --rm -it \
  --mount type=bind,source=/tmp,target=/host-tmp,bind-propagation=shared \
  ubuntu bash

# Inside container
findmnt | grep tmp
mount --bind /host-tmp /mnt
```

### **Control Groups (cgroups) Management**

#### **cgroups v1 Structure**
```bash
# cgroups hierarchy
ls -la /sys/fs/cgroup/
drwxr-xr-x 2 root root 0 Dec  7 10:30 blkio/
drwxr-xr-x 2 root root 0 Dec  7 10:30 cpu/
drwxr-xr-x 2 root root 0 Dec  7 10:30 cpuacct/
drwxr-xr-x 2 root root 0 Dec  7 10:30 devices/
drwxr-xr-x 2 root root 0 Dec  7 10:30 memory/
drwxr-xr-x 2 root root 0 Dec  7 10:30 pids/

# Container cgroups
docker run -d --name cgroup-test --memory=512m --cpus=0.5 nginx
CONTAINER_ID=$(docker inspect -f '{{.Id}}' cgroup-test)

# Memory limits
cat /sys/fs/cgroup/memory/docker/$CONTAINER_ID/memory.limit_in_bytes
cat /sys/fs/cgroup/memory/docker/$CONTAINER_ID/memory.usage_in_bytes

# CPU limits
cat /sys/fs/cgroup/cpu/docker/$CONTAINER_ID/cpu.cfs_quota_us
cat /sys/fs/cgroup/cpu/docker/$CONTAINER_ID/cpu.cfs_period_us

# Process list in cgroup
cat /sys/fs/cgroup/pids/docker/$CONTAINER_ID/cgroup.procs
```

#### **cgroups v2 (Unified Hierarchy)**
```bash
# Check if cgroups v2 is enabled
mount | grep cgroup2

# cgroups v2 structure
ls -la /sys/fs/cgroup/
-r--r--r-- 1 root root 0 Dec  7 10:30 cgroup.controllers
-rw-r--r-- 1 root root 0 Dec  7 10:30 cgroup.subtree_control
drwxr-xr-x 2 root root 0 Dec  7 10:30 system.slice/
drwxr-xr-x 2 root root 0 Dec  7 10:30 user.slice/

# Container in systemd slice
systemctl status docker-$CONTAINER_ID.scope
```

### **Security Features**

#### **Capabilities Analysis**
```bash
# Check container capabilities
docker run --rm --cap-add=ALL --cap-drop=MKNOD ubuntu \
  capsh --print

# Current process capabilities
grep Cap /proc/self/status

# Detailed capability info
cat /proc/self/status | grep Cap
CapInh: 0000000000000000
CapPrm: 0000003fffffffff
CapEff: 0000003fffffffff
CapBnd: 0000003fffffffff

# Decode capabilities
capsh --decode=0000003fffffffff
```

#### **Seccomp Profile Investigation**
```bash
# Check seccomp status
grep Seccomp /proc/self/status

# Container with custom seccomp
docker run --rm --security-opt seccomp=unconfined ubuntu \
  grep Seccomp /proc/self/status

# Seccomp profile location
ls -la /var/lib/docker/seccomp/
```

---

## 💾 **Storage Drivers Deep Dive**

### **Storage Driver Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                  Docker Image Layers                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │   Layer 1   │ │   Layer 2   │ │       Layer N           │ │
│  │  (Base OS)  │ │ (Updates)   │ │    (Application)        │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────┘
                      │ Union Mount
┌─────────────────────▼───────────────────────────────────────┐
│                 Storage Driver                             │
│           (overlay2, devicemapper, btrfs)                 │
└─────────────────────┬───────────────────────────────────────┘
                      │ Filesystem Operations
┌─────────────────────▼───────────────────────────────────────┐
│                 Host Filesystem                            │
│                   (ext4, xfs, btrfs)                      │
└─────────────────────────────────────────────────────────────┘
```

### **Overlay2 Driver Analysis**
```bash
# Check current storage driver
docker info | grep "Storage Driver"

# Docker data directory structure
sudo ls -la /var/lib/docker/
drwx------ 4 root root 4096 Dec  7 10:30 buildkit/
drwx------ 2 root root 4096 Dec  7 10:30 containers/
drwx------ 3 root root 4096 Dec  7 10:30 image/
drwxr-x--- 3 root root 4096 Dec  7 10:30 network/
drwx------ 5 root root 4096 Dec  7 10:30 overlay2/
drwx------ 4 root root 4096 Dec  7 10:30 plugins/
drwx------ 2 root root 4096 Dec  7 10:30 runtimes/
drwx------ 2 root root 4096 Dec  7 10:30 swarm/
drwx------ 2 root root 4096 Dec  7 10:30 tmp/
drwx------ 2 root root 4096 Dec  7 10:30 trust/
drwx------ 15 root root 4096 Dec  7 10:30 volumes/

# Overlay2 layer structure
sudo ls -la /var/lib/docker/overlay2/
drwx------ 4 root root 4096 Dec  7 10:30 l/           # Short layer IDs
drwx------ 4 root root 4096 Dec  7 10:30 <layer-id>/

# Layer details
sudo ls -la /var/lib/docker/overlay2/<layer-id>/
drwxr-xr-x 2 root root 4096 Dec  7 10:30 diff/        # Layer content
-rw-r--r-- 1 root root   26 Dec  7 10:30 link         # Short ID link
-rw-r--r-- 1 root root   28 Dec  7 10:30 lower        # Parent layers
drwx------ 2 root root 4096 Dec  7 10:30 work/        # Overlay workdir

# Container layer
CONTAINER_ID=$(docker run -d nginx)
sudo find /var/lib/docker/overlay2 -name "*$CONTAINER_ID*"
```

### **Layer Sharing Analysis**
```bash
# Create containers from same image
docker run -d --name nginx1 nginx
docker run -d --name nginx2 nginx

# Check shared layers
docker inspect nginx1 | jq '.[0].GraphDriver.Data'
docker inspect nginx2 | jq '.[0].GraphDriver.Data'

# Layer information
docker history nginx --no-trunc

# Image layer details
docker inspect nginx | jq '.[0].RootFS.Layers'
```

### **Storage Performance Testing**
```bash
#!/bin/bash
# storage-benchmark.sh

echo "Storage Performance Benchmark"
echo "============================="

# Test sequential write
echo "Sequential Write Test:"
docker run --rm -v /tmp:/host-tmp alpine \
  dd if=/dev/zero of=/host-tmp/test-seq bs=1M count=1000 oflag=direct

# Test random write
echo "Random Write Test:"
docker run --rm -v /tmp:/host-tmp alpine \
  dd if=/dev/urandom of=/host-tmp/test-rand bs=4k count=10000 oflag=direct

# Test with different storage drivers
echo "Testing with tmpfs:"
docker run --rm --tmpfs /tmp alpine \
  dd if=/dev/zero of=/tmp/test-tmpfs bs=1M count=100

# Cleanup
rm -f /tmp/test-*
```

---

## 🌐 **Networking Implementation**

### **Docker Network Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                    Host Network Stack                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │   docker0   │ │   br-xxx    │ │      Custom Bridge      │ │
│  │   Bridge    │ │   Bridge    │ │       Networks          │ │
│  └─────┬───────┘ └─────┬───────┘ └─────────┬───────────────┘ │
├────────┼─────────────────┼───────────────────┼─────────────────┤
│        │                 │                   │                 │
│  ┌─────▼───────┐   ┌─────▼───────┐   ┌─────▼───────────────┐ │
│  │   veth0     │   │   veth1     │   │      veth2          │ │
│  │ (Host side) │   │ (Host side) │   │   (Host side)       │ │
│  └─────┬───────┘   └─────┬───────┘   └─────┬───────────────┘ │
└────────┼─────────────────┼───────────────────┼─────────────────┘
         │                 │                   │
    ┌────▼──────┐     ┌────▼──────┐       ┌────▼──────┐
    │Container 1│     │Container 2│       │Container 3│
    │   eth0    │     │   eth0    │       │   eth0    │
    └───────────┘     └───────────┘       └───────────┘
```

### **Bridge Network Investigation**
```bash
# List Docker networks
docker network ls

# Bridge network details
docker network inspect bridge

# Check iptables rules
sudo iptables -t nat -L DOCKER
sudo iptables -L DOCKER-USER
sudo iptables -L FORWARD

# Network namespace for container
docker run -d --name net-test nginx
CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' net-test)

# Enter container network namespace
sudo nsenter -t $CONTAINER_PID -n bash
ip addr show
ip route show
```

### **Custom Network Deep Dive**
```bash
# Create custom network
docker network create --driver bridge \
  --subnet=192.168.100.0/24 \
  --ip-range=192.168.100.128/25 \
  --gateway=192.168.100.1 \
  custom-net

# Network interface created
ip addr show | grep br-

# Bridge details
sudo brctl show

# Container on custom network
docker run -d --name custom-container --network custom-net nginx

# Traffic analysis
sudo tcpdump -i br-$(docker network inspect custom-net -f '{{.Id}}' | cut -c1-12) -n
```

### **Overlay Network (Swarm)**
```bash
# Initialize swarm
docker swarm init

# Create overlay network
docker network create --driver overlay --attachable overlay-net

# Service on overlay network
docker service create --name web --network overlay-net --replicas 3 nginx

# VXLAN interface
ip addr show | grep vx-

# Overlay network routing
docker exec -it $(docker ps -q --filter "name=web") ip route
```

---

## 🖼️ **Image and Layer Management**

### **Image Storage Structure**
```bash
# Image metadata location
sudo ls -la /var/lib/docker/image/overlay2/
drwx------ 2 root root 4096 Dec  7 10:30 distribution/
drwx------ 4 root root 4096 Dec  7 10:30 imagedb/
drwx------ 5 root root 4096 Dec  7 10:30 layerdb/
-rw------- 1 root root   12 Dec  7 10:30 repositories.json

# Image database
sudo cat /var/lib/docker/image/overlay2/repositories.json | jq

# Layer database
sudo ls -la /var/lib/docker/image/overlay2/layerdb/sha256/

# Layer metadata
LAYER_ID="<layer-sha256>"
sudo cat /var/lib/docker/image/overlay2/layerdb/sha256/$LAYER_ID/cache-id
sudo cat /var/lib/docker/image/overlay2/layerdb/sha256/$LAYER_ID/diff
sudo cat /var/lib/docker/image/overlay2/layerdb/sha256/$LAYER_ID/size
```

### **Content Addressable Storage**
```bash
# Image manifest
docker manifest inspect nginx:latest

# Layer blobs
LAYER_DIGEST="sha256:..."
sudo find /var/lib/docker -name "*$LAYER_DIGEST*"

# Content store (containerd)
sudo ctr content ls
sudo ctr content get $LAYER_DIGEST | head -20
```

### **Build Cache Analysis**
```bash
# BuildKit cache
docker system df

# Build cache details
docker builder du

# Cache mount analysis
docker build --progress=plain --no-cache \
  --mount=type=cache,target=/var/cache/apt \
  -t test-cache .

# BuildKit history
docker history --no-trunc test-cache
```

---

## ⚡ **Performance Analysis**

### **Container Performance Metrics**
```bash
#!/bin/bash
# performance-analyzer.sh

CONTAINER_NAME=$1

if [ -z "$CONTAINER_NAME" ]; then
    echo "Usage: $0 <container_name>"
    exit 1
fi

echo "Performance Analysis for $CONTAINER_NAME"
echo "========================================"

# Basic container info
docker inspect $CONTAINER_NAME | jq '{
    Name: .Name,
    State: .State.Status,
    Created: .Created,
    RestartCount: .RestartCount
}'

# Resource usage
docker stats --no-stream $CONTAINER_NAME

# Process tree
CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME)
echo "Process Tree:"
pstree -p $CONTAINER_PID

# Memory analysis
echo "Memory Details:"
cat /proc/$CONTAINER_PID/status | grep -E "VmPeak|VmSize|VmRSS|VmData|VmStk"

# Open files
echo "Open File Descriptors:"
ls /proc/$CONTAINER_PID/fd | wc -l
lsof -p $CONTAINER_PID | head -10

# Network connections
echo "Network Connections:"
netstat -tulpn | grep $CONTAINER_PID

# I/O statistics
echo "I/O Statistics:"
cat /proc/$CONTAINER_PID/io
```

### **System-wide Performance Impact**
```bash
# System load before containers
uptime
free -h
df -h

# Docker daemon resource usage
ps aux | grep dockerd
systemctl status docker

# Overall container impact
docker stats --all --no-stream

# Host network impact
ss -tuln | grep docker
iptables -L -n | wc -l
```

### **Profiling Tools Integration**
```bash
# perf profiling
sudo perf record -p $(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME) sleep 30
sudo perf report

# strace analysis
sudo strace -p $(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME) -c

# ftrace for kernel tracing
echo function > /sys/kernel/debug/tracing/current_tracer
echo $(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME) > /sys/kernel/debug/tracing/set_ftrace_pid
```

---

## 🔧 **Advanced Troubleshooting**

### **Container Debugging Toolkit**
```bash
#!/bin/bash
# docker-debug-toolkit.sh

debug_container() {
    local container=$1
    echo "🔍 Debugging Container: $container"
    
    # Basic info
    echo "📋 Container Information:"
    docker inspect $container | jq '{
        Name: .Name,
        Image: .Config.Image,
        State: .State,
        Networks: .NetworkSettings.Networks,
        Mounts: .Mounts,
        RestartPolicy: .HostConfig.RestartPolicy
    }'
    
    # Resource constraints
    echo "📊 Resource Constraints:"
    docker inspect $container | jq '{
        Memory: .HostConfig.Memory,
        CpuShares: .HostConfig.CpuShares,
        CpuQuota: .HostConfig.CpuQuota,
        CpuPeriod: .HostConfig.CpuPeriod
    }'
    
    # Namespace information
    local pid=$(docker inspect -f '{{.State.Pid}}' $container)
    if [ "$pid" != "0" ]; then
        echo "🏷️ Namespace Information:"
        ls -la /proc/$pid/ns/
        
        echo "🔗 cgroups:"
        cat /proc/$pid/cgroup
        
        echo "📁 Mount points:"
        nsenter -t $pid -m findmnt
    fi
    
    # Network debugging
    echo "🌐 Network Information:"
    docker exec $container ip addr show
    docker exec $container ip route show
    
    # Process information
    echo "⚡ Process Information:"
    docker exec $container ps aux
    
    # Resource usage
    echo "📈 Current Resource Usage:"
    docker stats --no-stream $container
}

debug_networking() {
    echo "🌐 Docker Networking Debug"
    
    # Bridge information
    echo "🌉 Bridges:"
    brctl show
    
    # iptables rules
    echo "🔥 iptables NAT rules:"
    iptables -t nat -L DOCKER
    
    # Network namespaces
    echo "📦 Network Namespaces:"
    ip netns list
    
    # Interface statistics
    echo "📊 Interface Statistics:"
    cat /proc/net/dev
}

debug_storage() {
    echo "💾 Docker Storage Debug"
    
    # Storage driver info
    echo "🚛 Storage Driver:"
    docker info | grep -A 10 "Storage Driver"
    
    # Disk usage
    echo "💿 Disk Usage:"
    docker system df -v
    
    # Layer information
    echo "📚 Layer Analysis:"
    docker images --digests
    
    # Mount points
    echo "📁 Mount Analysis:"
    mount | grep docker
}

# Main execution
case "${1:-help}" in
    container)
        debug_container "$2"
        ;;
    network)
        debug_networking
        ;;
    storage)
        debug_storage
        ;;
    all)
        debug_networking
        echo -e "\n"
        debug_storage
        ;;
    help|*)
        echo "Docker Advanced Debug Toolkit"
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  container <name>  - Debug specific container"
        echo "  network          - Debug Docker networking"
        echo "  storage          - Debug Docker storage"
        echo "  all              - Run all system debugging"
        echo "  help             - Show this help"
        ;;
esac
```

### **Kernel-level Troubleshooting**
```bash
# Check kernel logs for Docker-related issues
dmesg | grep -i docker
dmesg | grep -i "out of memory"
dmesg | grep -i "killed process"

# systemd journal for dockerd
journalctl -u docker.service --since "1 hour ago"

# Kernel tracing
echo 1 > /sys/kernel/debug/tracing/events/syscalls/enable
cat /sys/kernel/debug/tracing/trace_pipe | grep docker

# Memory pressure
cat /proc/pressure/memory
cat /proc/pressure/cpu
cat /proc/pressure/io
```

### **Performance Bottleneck Analysis**
```bash
#!/bin/bash
# bottleneck-analyzer.sh

analyze_cpu_bottlenecks() {
    echo "🔥 CPU Bottleneck Analysis"
    
    # System-wide CPU usage
    top -b -n 1 | head -20
    
    # Per-container CPU usage
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    
    # CPU pressure
    cat /proc/pressure/cpu
    
    # Load average analysis
    uptime
    cat /proc/loadavg
}

analyze_memory_bottlenecks() {
    echo "🧠 Memory Bottleneck Analysis"
    
    # System memory
    free -h
    cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached"
    
    # Per-container memory
    docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}\t{{.MemPerc}}"
    
    # Memory pressure
    cat /proc/pressure/memory
    
    # OOM killer events
    dmesg | grep "Out of memory" | tail -10
}

analyze_io_bottlenecks() {
    echo "💿 I/O Bottleneck Analysis"
    
    # I/O statistics
    iostat -x 1 5
    
    # I/O pressure
    cat /proc/pressure/io
    
    # Docker storage usage
    docker system df
    
    # Per-container I/O
    for container in $(docker ps --format "{{.Names}}"); do
        pid=$(docker inspect -f '{{.State.Pid}}' $container)
        echo "Container: $container"
        cat /proc/$pid/io
        echo "---"
    done
}

analyze_network_bottlenecks() {
    echo "🌐 Network Bottleneck Analysis"
    
    # Network interface statistics
    cat /proc/net/dev
    
    # Network connections
    ss -tuln | wc -l
    echo "Total network connections: $(ss -tuln | wc -l)"
    
    # Docker network overhead
    iptables -L -n | wc -l
    echo "Total iptables rules: $(iptables -L -n | wc -l)"
    
    # Per-container network
    docker stats --no-stream --format "table {{.Container}}\t{{.NetIO}}"
}

# Run all analyses
echo "Docker Performance Bottleneck Analysis"
echo "======================================"
analyze_cpu_bottlenecks
echo -e "\n"
analyze_memory_bottlenecks
echo -e "\n"
analyze_io_bottlenecks
echo -e "\n"
analyze_network_bottlenecks
```

---

## ✅ **Key Takeaways**

### **Architecture Understanding**
1. **Layered Architecture**: Docker client → dockerd → containerd → runc → kernel
2. **Process Isolation**: Namespaces provide process, network, and filesystem isolation
3. **Resource Control**: cgroups manage CPU, memory, and I/O resources
4. **Security**: Multiple layers including capabilities, seccomp, and SELinux/AppArmor

### **Performance Optimization**
1. **Storage Drivers**: Choose appropriate driver for your workload (overlay2 for most cases)
2. **Network Modes**: Use host networking for performance-critical applications
3. **Resource Limits**: Always set appropriate CPU and memory limits
4. **Image Optimization**: Use multi-stage builds and minimal base images

### **Troubleshooting Skills**
1. **System Tools**: Master ps, top, netstat, iptables, and namespace tools
2. **Docker Tools**: Use docker inspect, stats, logs, and exec effectively
3. **Kernel Debugging**: Understand dmesg, /proc filesystem, and system calls
4. **Performance Analysis**: Use profiling tools and system metrics

---

## 🎓 **Next Steps**

Ready for **[12-interview-guide](../12-interview-guide/)**? You'll master:
- Senior DevOps interview questions
- Practical troubleshooting scenarios
- Architecture design problems
- Real-world production issues
- Best practices and patterns

---

## 📚 **Additional Resources**

- [Docker Internals Documentation](https://docs.docker.com/get-started/overview/)
- [OCI Runtime Specification](https://github.com/opencontainers/runtime-spec)
- [containerd Documentation](https://containerd.io/docs/)
- [Linux Containers (LXC)](https://linuxcontainers.org/lxc/introduction/)
- [Kernel Namespaces](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [Control Groups (cgroups)](https://www.kernel.org/doc/Documentation/cgroup-v1/cgroups.txt)
