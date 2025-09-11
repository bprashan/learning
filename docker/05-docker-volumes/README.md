# 05 - Docker Volumes: Data Persistence and Management

## 🎯 **Learning Objectives**
Master data persistence and storage management in Docker:
- Volume types and their use cases
- Data persistence strategies
- Backup and recovery procedures
- Performance optimization
- Production storage patterns
- Troubleshooting storage issues

---

## 📋 **Table of Contents**
1. [Storage Architecture Overview](#storage-architecture-overview)
2. [Volume Types Deep Dive](#volume-types-deep-dive)
3. [Data Persistence Strategies](#data-persistence-strategies)
4. [Backup and Recovery](#backup-and-recovery)
5. [Performance Optimization](#performance-optimization)
6. [Production Patterns](#production-patterns)
7. [Security Considerations](#security-considerations)
8. [Troubleshooting Storage](#troubleshooting-storage)

---

## 🏗️ **Storage Architecture Overview**

### **Docker Storage Stack**
```
┌─────────────────────────────────────────────────┐
│                 Container Layer (R/W)           │
├─────────────────────────────────────────────────┤
│            Image Layers (Read-Only)             │
├─────────────────────────────────────────────────┤
│                Storage Driver                   │
│     (overlay2, aufs, devicemapper, etc.)       │
├─────────────────────────────────────────────────┤
│                 Volume Mounts                   │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│   │ Volumes │ │ Bind    │ │ tmpfs   │          │
│   │         │ │ Mounts  │ │ Mounts  │          │
│   └─────────┘ └─────────┘ └─────────┘          │
├─────────────────────────────────────────────────┤
│              Host File System                   │
└─────────────────────────────────────────────────┘
```

### **Storage Options Comparison**

| Type | Managed by | Performance | Use Cases | Backup |
|------|------------|-------------|-----------|---------|
| **Volumes** | Docker | Good | Production data | Easy |
| **Bind Mounts** | Host | Best | Development, config | Manual |
| **tmpfs** | Memory | Excellent | Temporary data | N/A |

### **Storage Drivers**
```bash
# Check current storage driver
docker info | grep "Storage Driver"

# Common storage drivers:
# - overlay2 (recommended for most cases)
# - aufs (legacy Ubuntu)
# - devicemapper (RHEL/CentOS)
# - btrfs (advanced features)
# - zfs (advanced features)
```

---

## 💾 **Volume Types Deep Dive**

### **1. Named Volumes (Recommended for Production)**

#### **Creating and Managing Volumes**
```bash
# Create named volume
docker volume create my-volume

# Create volume with specific driver
docker volume create \
  --driver local \
  --opt type=ext4 \
  --opt device=/dev/sdb1 \
  production-data

# List all volumes
docker volume ls

# Inspect volume details
docker volume inspect my-volume

# Remove volume (only if not in use)
docker volume rm my-volume

# Remove all unused volumes
docker volume prune
```

#### **Volume Configuration Options**
```bash
# Volume with specific mount options
docker volume create \
  --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.1.100,rw \
  --opt device=:/path/to/nfs/share \
  nfs-volume

# Volume with size limit (requires specific drivers)
docker volume create \
  --driver local \
  --opt type=tmpfs \
  --opt device=tmpfs \
  --opt o=size=1g \
  limited-volume
```

#### **Using Volumes in Containers**
```bash
# Mount named volume
docker run -d \
  --name postgres-db \
  -v postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secret \
  postgres:13

# Multiple volumes
docker run -d \
  --name web-app \
  -v app-data:/app/data \
  -v app-logs:/app/logs \
  -v app-config:/app/config \
  my-web-app:latest

# Read-only volume mount
docker run -d \
  --name read-only-app \
  -v config-volume:/app/config:ro \
  my-app:latest
```

### **2. Bind Mounts (Host Directory Mapping)**

#### **Basic Bind Mounts**
```bash
# Mount host directory
docker run -d \
  --name dev-app \
  -v /host/path:/container/path \
  node:18-alpine

# Windows path example
docker run -d \
  --name windows-app \
  -v C:\Users\username\project:/app \
  node:18-alpine

# Current directory shorthand
docker run -d \
  --name current-dir \
  -v $(pwd):/app \
  node:18-alpine
```

#### **Advanced Bind Mount Options**
```bash
# Bind mount with specific options
docker run -d \
  --name secure-mount \
  --mount type=bind,source=/host/data,target=/app/data,readonly \
  my-app:latest

# Bind mount with propagation
docker run -d \
  --name propagation-test \
  --mount type=bind,source=/host/data,target=/app/data,bind-propagation=shared \
  my-app:latest
```

#### **Development Workflow with Bind Mounts**
```bash
# Hot reload development setup
docker run -d \
  --name dev-server \
  -p 3000:3000 \
  -v $(pwd)/src:/app/src \
  -v $(pwd)/package.json:/app/package.json \
  -v /app/node_modules \
  node:18-alpine npm run dev

# Configuration override
docker run -d \
  --name configurable-app \
  -v $(pwd)/config/dev.yml:/app/config/app.yml \
  -v $(pwd)/logs:/app/logs \
  my-app:latest
```

### **3. tmpfs Mounts (Memory-based Storage)**

#### **When to Use tmpfs**
- Temporary data processing
- Sensitive data that shouldn't persist
- High-performance temporary storage
- Build caches and temporary files

```bash
# Basic tmpfs mount
docker run -d \
  --name temp-storage \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  my-app:latest

# Multiple tmpfs mounts
docker run -d \
  --name multi-temp \
  --tmpfs /tmp \
  --tmpfs /var/cache \
  --tmpfs /var/tmp \
  my-app:latest

# tmpfs with specific options
docker run -d \
  --name optimized-temp \
  --mount type=tmpfs,destination=/app/temp,tmpfs-size=512m,tmpfs-mode=755 \
  processing-app:latest
```

### **4. Volume Plugins and Drivers**

#### **Network File System (NFS) Volumes**
```bash
# Install NFS plugin (if not built-in)
docker plugin install store/sumologic/docker-volume-driver:latest

# Create NFS volume
docker volume create \
  --driver local \
  --opt type=nfs \
  --opt o=addr=nfs.example.com,rw \
  --opt device=:/exports/data \
  nfs-shared-volume

# Use NFS volume across multiple containers
docker run -d --name app1 -v nfs-shared-volume:/data my-app:latest
docker run -d --name app2 -v nfs-shared-volume:/data my-app:latest
```

#### **Cloud Storage Volumes**
```bash
# AWS EFS volume (requires plugin)
docker volume create \
  --driver rexray/efs \
  --opt volumeType=efs \
  --opt fileSystemId=fs-12345678 \
  aws-efs-volume

# Google Cloud persistent disk
docker volume create \
  --driver rexray/gcepd \
  --opt volumeType=gp2 \
  --opt size=100 \
  gce-persistent-volume

# Azure file share
docker volume create \
  --driver rexray/azureud \
  --opt storageAccount=mystorageaccount \
  --opt share=myshare \
  azure-file-volume
```

---

## 💿 **Data Persistence Strategies**

### **Database Persistence Patterns**

#### **PostgreSQL High Availability Setup**
```bash
# Create persistent volumes
docker volume create postgres-primary-data
docker volume create postgres-replica-data

# Primary database
docker run -d \
  --name postgres-primary \
  -v postgres-primary-data:/var/lib/postgresql/data \
  -v $(pwd)/postgres-primary.conf:/etc/postgresql/postgresql.conf \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_REPLICATION_USER=replica \
  -e POSTGRES_REPLICATION_PASSWORD=replica_secret \
  -p 5432:5432 \
  postgres:13

# Replica database
docker run -d \
  --name postgres-replica \
  -v postgres-replica-data:/var/lib/postgresql/data \
  -e PGUSER=replica \
  -e PGPASSWORD=replica_secret \
  -e POSTGRES_PRIMARY_HOST=postgres-primary \
  -p 5433:5432 \
  postgres:13
```

#### **MySQL Cluster with Persistent Storage**
```bash
# MySQL master
docker volume create mysql-master-data
docker run -d \
  --name mysql-master \
  -v mysql-master-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_REPLICATION_USER=replica \
  -e MYSQL_REPLICATION_PASSWORD=replica_pass \
  -p 3306:3306 \
  mysql:8.0

# MySQL slave
docker volume create mysql-slave-data
docker run -d \
  --name mysql-slave \
  -v mysql-slave-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_MASTER_HOST=mysql-master \
  -e MYSQL_REPLICATION_USER=replica \
  -e MYSQL_REPLICATION_PASSWORD=replica_pass \
  -p 3307:3306 \
  mysql:8.0
```

#### **MongoDB Replica Set**
```bash
# Create volumes for replica set
for i in {1..3}; do
  docker volume create mongo-rs-${i}-data
done

# MongoDB replica set members
for i in {1..3}; do
  docker run -d \
    --name mongo-rs-${i} \
    -v mongo-rs-${i}-data:/data/db \
    -p $((27016 + i)):27017 \
    --network mongo-network \
    mongo:5.0 \
    mongod --replSet rs0 --bind_ip_all
done

# Initialize replica set
docker exec mongo-rs-1 mongo --eval '
rs.initiate({
  _id: "rs0",
  members: [
    {_id: 0, host: "mongo-rs-1:27017"},
    {_id: 1, host: "mongo-rs-2:27017"},
    {_id: 2, host: "mongo-rs-3:27017"}
  ]
})'
```

### **Application Data Patterns**

#### **Stateful Application with Persistent Storage**
```bash
# Application with multiple data types
docker run -d \
  --name stateful-app \
  -v app-database:/app/database \
  -v app-uploads:/app/uploads \
  -v app-cache:/app/cache \
  -v app-logs:/var/log/app \
  -v $(pwd)/config:/app/config:ro \
  --restart unless-stopped \
  my-stateful-app:latest
```

#### **Content Management System**
```bash
# WordPress with persistent data
docker volume create wordpress-data
docker volume create wordpress-db-data

# MySQL for WordPress
docker run -d \
  --name wordpress-db \
  -v wordpress-db-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=wordpress \
  -e MYSQL_USER=wpuser \
  -e MYSQL_PASSWORD=wppass \
  mysql:8.0

# WordPress application
docker run -d \
  --name wordpress \
  -v wordpress-data:/var/www/html \
  -p 80:80 \
  -e WORDPRESS_DB_HOST=wordpress-db \
  -e WORDPRESS_DB_USER=wpuser \
  -e WORDPRESS_DB_PASSWORD=wppass \
  -e WORDPRESS_DB_NAME=wordpress \
  --link wordpress-db \
  wordpress:latest
```

### **Shared Storage Patterns**

#### **Multi-Container Shared Volumes**
```bash
# Shared content volume
docker volume create shared-content

# Content producer
docker run -d \
  --name content-producer \
  -v shared-content:/app/content \
  content-generator:latest

# Content consumers
docker run -d \
  --name web-server \
  -v shared-content:/usr/share/nginx/html:ro \
  -p 80:80 \
  nginx:alpine

docker run -d \
  --name backup-service \
  -v shared-content:/backup/source:ro \
  -v backup-destination:/backup/dest \
  backup-tool:latest
```

---

## 🔄 **Backup and Recovery**

### **Volume Backup Strategies**

#### **Manual Backup Methods**
```bash
# Backup volume to tar archive
docker run --rm \
  -v postgres-data:/data \
  -v $(pwd)/backups:/backups \
  alpine tar czf /backups/postgres-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .

# Backup using rsync
docker run --rm \
  -v source-volume:/source:ro \
  -v $(pwd)/backups:/backups \
  alpine rsync -av /source/ /backups/

# Database-specific backup
docker exec postgres-container \
  pg_dump -U postgres mydb > backup-$(date +%Y%m%d).sql
```

#### **Automated Backup Scripts**
```bash
# Create backup script
cat > backup-volumes.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d-%H%M%S)

# Function to backup a volume
backup_volume() {
    local volume=$1
    local backup_name="${volume}-${DATE}"
    
    echo "Backing up volume: $volume"
    
    docker run --rm \
        -v $volume:/data:ro \
        -v $BACKUP_DIR:/backups \
        alpine tar czf /backups/${backup_name}.tar.gz -C /data .
    
    # Keep only last 7 days of backups
    find $BACKUP_DIR -name "${volume}-*" -mtime +7 -delete
}

# Backup critical volumes
backup_volume "postgres-data"
backup_volume "app-uploads"
backup_volume "app-config"

echo "Backup completed at $(date)"
EOF

chmod +x backup-volumes.sh

# Schedule with cron
echo "0 2 * * * /path/to/backup-volumes.sh" | crontab -
```

#### **Real-time Backup with Volume Replication**
```bash
# Primary volume
docker volume create primary-data

# Backup volume
docker volume create backup-data

# Sync service
docker run -d \
  --name volume-sync \
  -v primary-data:/source \
  -v backup-data:/backup \
  --restart unless-stopped \
  alpine sh -c 'while true; do rsync -av /source/ /backup/; sleep 3600; done'
```

### **Disaster Recovery Procedures**

#### **Volume Restore Process**
```bash
# Restore from backup
docker run --rm \
  -v restored-volume:/data \
  -v $(pwd)/backups:/backups \
  alpine tar xzf /backups/postgres-backup-20231201-020000.tar.gz -C /data

# Verify restored data
docker run --rm \
  -v restored-volume:/data \
  alpine ls -la /data

# Start container with restored volume
docker run -d \
  --name postgres-restored \
  -v restored-volume:/var/lib/postgresql/data \
  postgres:13
```

#### **Cross-Platform Migration**
```bash
# Export volume from source system
docker run --rm \
  -v source-volume:/data:ro \
  alpine tar c -C /data . | gzip > volume-export.tar.gz

# Transfer to target system (scp, rsync, cloud storage)
scp volume-export.tar.gz user@target-host:/tmp/

# Import on target system
gunzip < volume-export.tar.gz | docker run --rm -i \
  -v target-volume:/data \
  alpine tar x -C /data
```

### **Point-in-Time Recovery**

#### **Continuous Backup Strategy**
```bash
# WAL-E for PostgreSQL continuous backup
docker run -d \
  --name postgres-with-wal-e \
  -v postgres-data:/var/lib/postgresql/data \
  -v wal-e-config:/etc/wal-e \
  -e AWS_ACCESS_KEY_ID=your-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret \
  -e WALE_S3_PREFIX=s3://your-bucket/postgres-backups \
  postgres-wal-e:latest

# MySQL binary log backup
docker run -d \
  --name mysql-binlog-backup \
  -v mysql-data:/var/lib/mysql \
  -v binlog-backups:/backups \
  --restart unless-stopped \
  mysql-binlog-manager:latest
```

---

## ⚡ **Performance Optimization**

### **Storage Driver Optimization**

#### **Overlay2 Performance Tuning**
```bash
# Configure Docker daemon for performance
cat > /etc/docker/daemon.json << EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true",
    "overlay2.size=20G"
  ]
}
EOF

# Restart Docker daemon
systemctl restart docker
```

#### **Volume Performance Testing**
```bash
# Test volume write performance
docker run --rm \
  -v test-volume:/test \
  alpine dd if=/dev/zero of=/test/testfile bs=1M count=1000

# Test volume read performance
docker run --rm \
  -v test-volume:/test \
  alpine dd if=/test/testfile of=/dev/null bs=1M

# Compare bind mount vs volume performance
time docker run --rm \
  -v $(pwd)/test:/test \
  alpine dd if=/dev/zero of=/test/bind-test bs=1M count=1000

time docker run --rm \
  -v volume-test:/test \
  alpine dd if=/dev/zero of=/test/volume-test bs=1M count=1000
```

### **Database Performance Optimization**

#### **PostgreSQL Volume Optimization**
```bash
# Optimized PostgreSQL container
docker run -d \
  --name postgres-optimized \
  -v postgres-data:/var/lib/postgresql/data \
  -v postgres-config:/etc/postgresql \
  -v postgres-logs:/var/log/postgresql \
  --tmpfs /tmp:rw,size=1g \
  --shm-size=256mb \
  -e POSTGRES_PASSWORD=secret \
  postgres:13 \
  -c shared_buffers=256MB \
  -c effective_cache_size=1GB \
  -c work_mem=4MB \
  -c maintenance_work_mem=64MB
```

#### **MySQL InnoDB Optimization**
```bash
# MySQL with optimized storage configuration
docker run -d \
  --name mysql-optimized \
  -v mysql-data:/var/lib/mysql \
  -v mysql-config:/etc/mysql/conf.d \
  --tmpfs /tmp:rw,size=1g \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:8.0 \
  --innodb-buffer-pool-size=1G \
  --innodb-log-file-size=256M \
  --innodb-flush-log-at-trx-commit=2 \
  --innodb-flush-method=O_DIRECT
```

### **High-Performance Storage Solutions**

#### **SSD-Optimized Volumes**
```bash
# Create volume on high-performance storage
docker volume create \
  --driver local \
  --opt type=ext4 \
  --opt device=/dev/nvme0n1p1 \
  ssd-volume

# Use with database for maximum performance
docker run -d \
  --name high-perf-db \
  -v ssd-volume:/var/lib/postgresql/data \
  postgres:13
```

#### **Memory-Mapped Storage**
```bash
# Use tmpfs for ultra-high performance (non-persistent)
docker run -d \
  --name memory-cache \
  --tmpfs /cache:rw,size=4g,mode=1777 \
  redis:alpine redis-server --save "" --appendonly no
```

---

## 🏭 **Production Patterns**

### **Enterprise Storage Architecture**

#### **Multi-Tier Storage Strategy**
```bash
# Tier 1: Critical data on high-performance storage
docker volume create \
  --driver rexray/ebs \
  --opt size=100 \
  --opt volumeType=gp3 \
  --opt iops=3000 \
  critical-data-tier1

# Tier 2: Important data on standard storage
docker volume create \
  --driver rexray/ebs \
  --opt size=500 \
  --opt volumeType=gp2 \
  important-data-tier2

# Tier 3: Archival data on cost-effective storage
docker volume create \
  --driver rexray/ebs \
  --opt size=1000 \
  --opt volumeType=sc1 \
  archive-data-tier3

# Deploy application with appropriate storage tiers
docker run -d \
  --name enterprise-app \
  -v critical-data-tier1:/app/database \
  -v important-data-tier2:/app/uploads \
  -v archive-data-tier3:/app/archive \
  enterprise-app:latest
```

#### **Storage Class Management**
```bash
# Define storage classes for different workloads
cat > storage-classes.sh << 'EOF'
#!/bin/bash

# High IOPS for databases
create_db_volume() {
    docker volume create \
        --driver rexray/ebs \
        --opt size=$2 \
        --opt volumeType=io2 \
        --opt iops=10000 \
        $1
}

# Balanced performance for applications
create_app_volume() {
    docker volume create \
        --driver rexray/ebs \
        --opt size=$2 \
        --opt volumeType=gp3 \
        --opt iops=3000 \
        $1
}

# Cost-effective for backups
create_backup_volume() {
    docker volume create \
        --driver rexray/ebs \
        --opt size=$2 \
        --opt volumeType=st1 \
        $1
}
EOF
```

### **Microservices Storage Patterns**

#### **Service-Specific Storage Isolation**
```bash
# Create isolated storage for each service
services=("user-service" "order-service" "payment-service" "inventory-service")

for service in "${services[@]}"; do
    # Primary database volume
    docker volume create ${service}-db-data
    
    # Application data volume
    docker volume create ${service}-app-data
    
    # Log volume
    docker volume create ${service}-logs
    
    # Deploy service with isolated storage
    docker run -d \
        --name $service \
        -v ${service}-db-data:/app/database \
        -v ${service}-app-data:/app/data \
        -v ${service}-logs:/app/logs \
        --network microservices-network \
        --restart unless-stopped \
        $service:latest
done
```

#### **Shared Configuration and Secrets**
```bash
# Shared configuration volume
docker volume create shared-config

# Populate configuration
docker run --rm \
  -v shared-config:/config \
  -v $(pwd)/configs:/source \
  alpine cp -r /source/* /config/

# Services using shared configuration
for service in "${services[@]}"; do
    docker run -d \
        --name $service \
        -v ${service}-data:/app/data \
        -v shared-config:/app/config:ro \
        $service:latest
done
```

### **Disaster Recovery Architecture**

#### **Multi-Region Backup Strategy**
```bash
# Primary region volumes
docker volume create \
  --driver rexray/ebs \
  --opt size=100 \
  --opt availabilityZone=us-east-1a \
  primary-db-data

# Replica region volumes  
docker volume create \
  --driver rexray/ebs \
  --opt size=100 \
  --opt availabilityZone=us-west-2a \
  replica-db-data

# Cross-region replication service
docker run -d \
  --name cross-region-sync \
  -v primary-db-data:/source \
  -v replica-db-data:/destination \
  -e AWS_REGION_SOURCE=us-east-1 \
  -e AWS_REGION_DEST=us-west-2 \
  cross-region-replicator:latest
```

---

## 🔒 **Security Considerations**

### **Volume Access Control**

#### **User and Permission Management**
```bash
# Create volume with specific ownership
docker run --rm \
  -v secure-volume:/data \
  alpine chown -R 1000:1000 /data

# Run container with non-root user
docker run -d \
  --name secure-app \
  --user 1000:1000 \
  -v secure-volume:/app/data \
  my-app:latest

# Read-only volume mounts
docker run -d \
  --name readonly-consumer \
  -v shared-data:/app/data:ro \
  data-consumer:latest
```

#### **Encrypted Volumes**
```bash
# Create encrypted volume (requires LUKS setup)
docker volume create \
  --driver local \
  --opt type=ext4 \
  --opt device=/dev/mapper/encrypted-disk \
  encrypted-volume

# Use encrypted volume for sensitive data
docker run -d \
  --name secure-database \
  -v encrypted-volume:/var/lib/postgresql/data \
  postgres:13
```

### **Backup Security**

#### **Encrypted Backups**
```bash
# Encrypted backup script
cat > secure-backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/secure-backups"
GPG_RECIPIENT="backup@company.com"
DATE=$(date +%Y%m%d-%H%M%S)

backup_volume_encrypted() {
    local volume=$1
    local backup_name="${volume}-${DATE}"
    
    # Create compressed backup
    docker run --rm \
        -v $volume:/data:ro \
        alpine tar czf - -C /data . | \
    # Encrypt with GPG
    gpg --cipher-algo AES256 --compress-algo 1 --symmetric \
        --output "${BACKUP_DIR}/${backup_name}.tar.gz.gpg"
    
    echo "Encrypted backup created: ${backup_name}.tar.gz.gpg"
}

backup_volume_encrypted "sensitive-data"
EOF
```

### **Volume Scanning and Compliance**

#### **Security Scanning**
```bash
# Scan volumes for sensitive data
docker run --rm \
  -v target-volume:/scan:ro \
  security-scanner:latest \
  --scan-path /scan \
  --output-format json

# Compliance checking
docker run --rm \
  -v audit-volume:/audit:ro \
  compliance-checker:latest \
  --framework SOC2 \
  --scan-path /audit
```

---

## 🔧 **Troubleshooting Storage**

### **Common Volume Issues**

#### **Issue 1: Volume Mount Failures**
```bash
# Check if volume exists
docker volume ls | grep my-volume

# Inspect volume details
docker volume inspect my-volume

# Check volume mount points
docker inspect container --format='{{.Mounts}}'

# Test volume accessibility
docker run --rm -v my-volume:/test alpine ls -la /test
```

**Solutions:**
```bash
# Create missing volume
docker volume create my-volume

# Fix permissions
docker run --rm -v my-volume:/data alpine chown -R 1000:1000 /data

# Remount with correct options
docker run -d --name fixed-container \
  -v my-volume:/app/data \
  --restart unless-stopped \
  my-app:latest
```

#### **Issue 2: Performance Problems**
```bash
# Check I/O statistics
docker stats container-name

# Monitor volume usage
docker exec container df -h

# Test I/O performance
docker run --rm -v test-volume:/test alpine \
  dd if=/dev/zero of=/test/speedtest bs=1M count=100
```

**Solutions:**
```bash
# Use appropriate storage driver
docker info | grep "Storage Driver"

# Optimize for SSD
echo 'DOCKER_OPTS="--storage-driver=overlay2"' >> /etc/default/docker

# Use tmpfs for temporary data
docker run --tmpfs /tmp:rw,size=1g my-app
```

#### **Issue 3: Space Issues**
```bash
# Check Docker disk usage
docker system df -v

# Check volume sizes
docker exec container du -sh /var/lib/docker/volumes/*

# Clean up unused volumes
docker volume prune
```

**Solutions:**
```bash
# Extend volume size (cloud storage)
docker volume create --driver rexray/ebs \
  --opt size=200 extended-volume

# Implement log rotation
docker run --log-opt max-size=10m \
  --log-opt max-file=3 my-app

# Set up monitoring alerts
docker run -d --name disk-monitor \
  -v /var/lib/docker:/docker:ro \
  disk-space-monitor:latest
```

### **Data Recovery Scenarios**

#### **Corrupted Volume Recovery**
```bash
# Stop containers using the volume
docker stop $(docker ps -q --filter volume=corrupted-volume)

# Create backup of corrupted volume
docker run --rm \
  -v corrupted-volume:/source:ro \
  -v recovery-backup:/backup \
  alpine cp -a /source /backup/corrupted-$(date +%s)

# Run filesystem check
docker run --rm \
  -v corrupted-volume:/data \
  --privileged \
  alpine fsck /dev/sdb1

# Restore from backup if necessary
docker run --rm \
  -v clean-backup:/source:ro \
  -v corrupted-volume:/target \
  alpine sh -c 'rm -rf /target/* && cp -a /source/* /target/'
```

#### **Volume Migration Between Hosts**
```bash
# Source host - export volume
docker run --rm \
  -v source-volume:/data:ro \
  alpine tar c -C /data . | \
  ssh user@target-host 'docker run --rm -i \
    -v target-volume:/data \
    alpine tar x -C /data'

# Verify migration
docker run --rm -v target-volume:/data alpine ls -la /data
```

---

## 🧪 **Advanced Labs**

### **Lab 1: High Availability Storage Setup**
```bash
# Create replicated storage setup
# Primary storage
docker volume create ha-primary-data

# Secondary storage  
docker volume create ha-secondary-data

# Replication service
docker run -d \
  --name storage-replicator \
  -v ha-primary-data:/primary \
  -v ha-secondary-data:/secondary \
  --restart unless-stopped \
  storage-sync:latest

# Application with failover
docker run -d \
  --name ha-app \
  -v ha-primary-data:/app/data \
  --health-cmd="curl -f http://localhost:8080/health" \
  --restart unless-stopped \
  ha-app:latest
```

### **Lab 2: Performance Benchmarking**
```bash
# Benchmark different storage options
storage_types=("volume" "bind" "tmpfs")

for type in "${storage_types[@]}"; do
    case $type in
        "volume")
            mount_opt="-v benchmark-vol:/test"
            ;;
        "bind")
            mount_opt="-v $(pwd)/benchmark:/test"
            mkdir -p $(pwd)/benchmark
            ;;
        "tmpfs")
            mount_opt="--tmpfs /test"
            ;;
    esac
    
    echo "Benchmarking $type storage..."
    time docker run --rm $mount_opt alpine \
        dd if=/dev/zero of=/test/benchmark bs=1M count=1000
done
```

### **Lab 3: Automated Backup System**
```bash
# Complete backup automation system
cat > backup-system.sh << 'EOF'
#!/bin/bash

# Configuration
BACKUP_RETENTION=7
VOLUMES=(
    "postgres-data"
    "app-uploads"
    "app-config"
)

# Backup function with compression and encryption
backup_volume() {
    local volume=$1
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_name="${volume}-${timestamp}"
    
    echo "Starting backup of $volume..."
    
    # Create compressed, encrypted backup
    docker run --rm \
        -v $volume:/source:ro \
        -v backup-storage:/backups \
        alpine sh -c "
            tar czf - -C /source . | \
            gpg --cipher-algo AES256 --symmetric \
                --passphrase-file /backups/.gpg-pass \
                --output /backups/${backup_name}.tar.gz.gpg
        "
    
    # Cleanup old backups
    docker run --rm \
        -v backup-storage:/backups \
        alpine find /backups -name "${volume}-*" -mtime +$BACKUP_RETENTION -delete
    
    echo "Backup completed: $backup_name"
}

# Backup all volumes
for volume in "${VOLUMES[@]}"; do
    backup_volume "$volume"
done

# Send notification
echo "All backups completed at $(date)" | mail -s "Backup Report" admin@company.com
EOF

# Schedule backups
echo "0 2 * * * /usr/local/bin/backup-system.sh" | crontab -
```

---

## ✅ **Key Takeaways**

1. **Volume Types**: Choose appropriate storage type for each use case
2. **Data Persistence**: Implement robust persistence strategies for critical data
3. **Backup & Recovery**: Establish automated backup and tested recovery procedures
4. **Performance**: Optimize storage performance based on workload requirements
5. **Security**: Apply proper access controls and encryption for sensitive data
6. **Monitoring**: Implement comprehensive storage monitoring and alerting
7. **Disaster Recovery**: Plan and test disaster recovery scenarios

---

## 🎓 **Next Steps**

Ready for **[06-docker-compose](../06-docker-compose/)**? You'll learn:
- Multi-container application orchestration
- Service definitions and dependencies
- Environment management
- Production deployment strategies
- Advanced Compose patterns

---

## 📚 **Additional Resources**

- [Docker Volume Documentation](https://docs.docker.com/storage/volumes/)
- [Storage Driver Selection](https://docs.docker.com/storage/storagedriver/select-storage-driver/)
- [Volume Plugin Development](https://docs.docker.com/engine/extend/plugins_volume/)
- [Production Storage Best Practices](https://docs.docker.com/storage/storagedriver/)
- [Backup and Recovery Strategies](https://docs.docker.com/storage/storagedriver/)
