# 08 - Docker Security: Comprehensive Container Security

## 🎯 **Learning Objectives**
Master Docker security for production environments:
- Container security fundamentals
- Image vulnerability management
- Runtime security monitoring
- Network and access control
- Compliance and governance
- Security automation and tooling

---

## 📋 **Table of Contents**
1. [Security Architecture Overview](#security-architecture-overview)
2. [Image Security](#image-security)
3. [Container Runtime Security](#container-runtime-security)
4. [Network Security](#network-security)
5. [Access Control & Authentication](#access-control--authentication)
6. [Secrets Management](#secrets-management)
7. [Monitoring & Incident Response](#monitoring--incident-response)
8. [Compliance & Governance](#compliance--governance)

---

## 🛡️ **Security Architecture Overview**

### **Docker Security Stack**
```
┌─────────────────────────────────────────────────┐
│                 Governance                      │
│           (Policies, Compliance)                │
├─────────────────────────────────────────────────┤
│              Security Monitoring                │
│        (SIEM, Alerting, Incident Response)      │
├─────────────────────────────────────────────────┤
│               Access Control                    │
│         (RBAC, Authentication, Authorization)   │
├─────────────────────────────────────────────────┤
│              Runtime Security                   │
│      (AppArmor, SELinux, Seccomp, Capabilities) │
├─────────────────────────────────────────────────┤
│               Network Security                  │
│        (Firewalls, Segmentation, Encryption)    │
├─────────────────────────────────────────────────┤
│                Image Security                   │
│     (Scanning, Signing, Base Image Hardening)   │
├─────────────────────────────────────────────────┤
│               Host Security                     │
│        (OS Hardening, Kernel Security)          │
└─────────────────────────────────────────────────┘
```

### **Security Principles**
1. **Least Privilege**: Minimal permissions and capabilities
2. **Defense in Depth**: Multiple security layers
3. **Zero Trust**: Verify everything, trust nothing
4. **Immutable Infrastructure**: Read-only containers
5. **Security by Default**: Secure configurations out of the box

### **Threat Model**
```
External Threats          Internal Threats         Supply Chain
┌─────────────────┐       ┌─────────────────┐      ┌─────────────────┐
│ • Network attacks│       │ • Insider threats│      │ • Malicious     │
│ • DDoS           │ ────► │ • Privilege      │ ────►│   dependencies  │
│ • Data breaches  │       │   escalation     │      │ • Compromised   │
│ • Malware        │       │ • Data theft     │      │   base images   │
└─────────────────┘       └─────────────────┘      └─────────────────┘
```

---

## 🔍 **Image Security**

### **Secure Base Images**

#### **Official vs Custom Images**
```dockerfile
# ✅ Use official, maintained images
FROM node:18-alpine3.16

# ✅ Use specific, stable tags
FROM postgres:13.8-alpine3.16

# ❌ Avoid 'latest' tag
FROM ubuntu:latest

# ✅ Use minimal distributions
FROM alpine:3.16
FROM gcr.io/distroless/java:17
FROM scratch  # For static binaries
```

#### **Base Image Selection Criteria**
```bash
# Check image details
docker inspect node:18-alpine3.16

# Verify image signatures (Docker Content Trust)
export DOCKER_CONTENT_TRUST=1
docker pull node:18-alpine3.16

# Check image provenance
docker buildx imagetools inspect node:18-alpine3.16
```

### **Vulnerability Scanning**

#### **Docker Scout (Built-in)**
```bash
# Quick vulnerability overview
docker scout quickview myapp:latest

# Detailed CVE analysis
docker scout cves myapp:latest

# Compare with base image
docker scout compare myapp:latest --to node:18-alpine

# Get recommendations
docker scout recommendations myapp:latest

# Policy evaluation
docker scout policy myapp:latest
```

#### **Trivy Scanner**
```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan image for vulnerabilities
trivy image myapp:latest

# Scan with severity filter
trivy image --severity HIGH,CRITICAL myapp:latest

# Scan and output to JSON
trivy image --format json --output results.json myapp:latest

# Scan filesystem
trivy fs --security-checks vuln,config .

# Scan Dockerfile
trivy config Dockerfile
```

#### **Automated Scanning in CI/CD**
```yaml
# GitHub Actions example
name: Security Scan

on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
      
      - name: Fail on high vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          exit-code: '1'
          severity: 'HIGH,CRITICAL'
```

### **Image Hardening**

#### **Multi-Stage Security Hardening**
```dockerfile
# Build stage with security scanning
FROM node:18-alpine3.16 AS builder

# Install security updates
RUN apk update && apk upgrade

# Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
    python3 \
    make \
    g++

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Remove build dependencies
RUN apk del .build-deps

COPY . .
RUN npm run build

# Security scan stage
FROM builder AS security-scan
RUN apk add --no-cache curl
RUN npm audit --audit-level=high

# Production stage with minimal attack surface
FROM alpine:3.16 AS production

# Install only runtime dependencies
RUN apk update && apk upgrade && \
    apk add --no-cache \
    nodejs \
    dumb-init && \
    rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Copy application with proper ownership
COPY --from=builder --chown=nodejs:nodejs /app/dist /app/
COPY --from=builder --chown=nodejs:nodejs /app/node_modules /app/node_modules/

# Switch to non-root user
USER nodejs

WORKDIR /app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node healthcheck.js || exit 1

# Use init system for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
```

#### **Distroless Images**
```dockerfile
# Go application with distroless
FROM golang:1.19-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o app .

# Distroless base (no shell, package manager)
FROM gcr.io/distroless/static-debian11:nonroot
COPY --from=builder /app/app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

### **Image Signing and Verification**

#### **Docker Content Trust**
```bash
# Enable content trust
export DOCKER_CONTENT_TRUST=1

# Generate signing keys
docker trust key generate mykey

# Sign and push image
docker tag myapp:latest myregistry.com/myapp:latest
docker push myregistry.com/myapp:latest

# Verify signature on pull
docker pull myregistry.com/myapp:latest
```

#### **Cosign Signing**
```bash
# Install cosign
go install github.com/sigstore/cosign/cmd/cosign@latest

# Generate key pair
cosign generate-key-pair

# Sign image
cosign sign --key cosign.key myregistry.com/myapp:latest

# Verify signature
cosign verify --key cosign.pub myregistry.com/myapp:latest
```

---

## 🔒 **Container Runtime Security**

### **Linux Security Modules**

#### **AppArmor Configuration**
```bash
# Check AppArmor status
sudo aa-status

# Create AppArmor profile for Docker
sudo tee /etc/apparmor.d/docker-nginx << 'EOF'
#include <tunables/global>

profile docker-nginx flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # Allow network access
  network inet tcp,
  network inet udp,

  # Allow file access
  /usr/sbin/nginx mr,
  /var/log/nginx/* w,
  /var/cache/nginx/* w,
  /etc/nginx/** r,
  /usr/share/nginx/** r,

  # Deny dangerous capabilities
  deny /proc/sys/** w,
  deny /sys/** w,
}
EOF

# Load profile
sudo apparmor_parser -r /etc/apparmor.d/docker-nginx

# Run container with AppArmor
docker run -d \
  --security-opt apparmor=docker-nginx \
  nginx:alpine
```

#### **SELinux Configuration**
```bash
# Check SELinux status
sestatus

# Set SELinux labels for containers
docker run -d \
  --security-opt label=level:s0:c100,c200 \
  nginx:alpine

# Custom SELinux policy
sudo setsebool -P container_manage_cgroup on
```

### **Capabilities Management**

#### **Dropping Capabilities**
```bash
# Drop all capabilities
docker run -d \
  --cap-drop=ALL \
  nginx:alpine

# Add only required capabilities
docker run -d \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --cap-add=CHOWN \
  nginx:alpine

# Check container capabilities
docker exec container_name capsh --print
```

#### **Capability Analysis**
```dockerfile
# Dockerfile with minimal capabilities
FROM nginx:alpine

# Create non-root user for nginx
RUN addgroup -g 101 -S nginx && \
    adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

# Modify nginx to run on non-privileged port
RUN sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf && \
    sed -i 's/listen  \[::\]:80;/listen  [::]:8080;/' /etc/nginx/conf.d/default.conf

USER nginx
EXPOSE 8080

# Run with dropped capabilities
# docker run -d --cap-drop=ALL -p 8080:8080 secure-nginx
```

### **Seccomp Profiles**

#### **Custom Seccomp Profile**
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": [
        "read", "write", "open", "close", "stat", "fstat", "lstat",
        "poll", "lseek", "mmap", "mprotect", "munmap", "brk",
        "rt_sigaction", "rt_sigprocmask", "rt_sigreturn", "ioctl",
        "pread64", "pwrite64", "readv", "writev", "access", "pipe",
        "select", "sched_yield", "mremap", "msync", "mincore",
        "madvise", "shmget", "shmat", "shmctl", "dup", "dup2",
        "pause", "nanosleep", "getitimer", "alarm", "setitimer",
        "getpid", "sendfile", "socket", "connect", "accept", "sendto",
        "recvfrom", "sendmsg", "recvmsg", "shutdown", "bind", "listen",
        "getsockname", "getpeername", "socketpair", "setsockopt",
        "getsockopt", "clone", "fork", "vfork", "execve", "exit",
        "wait4", "kill", "uname", "semget", "semop", "semctl",
        "shmdt", "msgget", "msgsnd", "msgrcv", "msgctl", "fcntl",
        "flock", "fsync", "fdatasync", "truncate", "ftruncate",
        "getdents", "getcwd", "chdir", "fchdir", "rename", "mkdir",
        "rmdir", "creat", "link", "unlink", "symlink", "readlink",
        "chmod", "fchmod", "chown", "fchown", "lchown", "umask",
        "gettimeofday", "getrlimit", "getrusage", "sysinfo", "times",
        "ptrace", "getuid", "syslog", "getgid", "setuid", "setgid",
        "geteuid", "getegid", "setpgid", "getppid", "getpgrp",
        "setsid", "setreuid", "setregid", "getgroups", "setgroups",
        "setresuid", "getresuid", "setresgid", "getresgid", "getpgid",
        "setfsuid", "setfsgid", "getsid", "capget", "capset",
        "rt_sigpending", "rt_sigtimedwait", "rt_sigqueueinfo",
        "rt_sigsuspend", "sigaltstack", "utime", "mknod", "uselib",
        "personality", "ustat", "statfs", "fstatfs", "sysfs",
        "getpriority", "setpriority", "sched_setparam",
        "sched_getparam", "sched_setscheduler", "sched_getscheduler",
        "sched_get_priority_max", "sched_get_priority_min",
        "sched_rr_get_interval", "mlock", "munlock", "mlockall",
        "munlockall", "vhangup", "modify_ldt", "pivot_root",
        "_sysctl", "prctl", "arch_prctl", "adjtimex", "setrlimit",
        "chroot", "sync", "acct", "settimeofday", "mount", "umount2",
        "swapon", "swapoff", "reboot", "sethostname", "setdomainname",
        "iopl", "ioperm", "create_module", "init_module",
        "delete_module", "get_kernel_syms", "query_module", "quotactl",
        "nfsservctl", "getpmsg", "putpmsg", "afs_syscall",
        "tuxcall", "security", "gettid", "readahead", "setxattr",
        "lsetxattr", "fsetxattr", "getxattr", "lgetxattr",
        "fgetxattr", "listxattr", "llistxattr", "flistxattr",
        "removexattr", "lremovexattr", "fremovexattr", "tkill",
        "time", "futex", "sched_setaffinity", "sched_getaffinity",
        "set_thread_area", "io_setup", "io_destroy", "io_getevents",
        "io_submit", "io_cancel", "get_thread_area", "lookup_dcookie",
        "epoll_create", "epoll_ctl_old", "epoll_wait_old",
        "remap_file_pages", "getdents64", "set_tid_address",
        "restart_syscall", "semtimedop", "fadvise64", "timer_create",
        "timer_settime", "timer_gettime", "timer_getoverrun",
        "timer_delete", "clock_settime", "clock_gettime",
        "clock_getres", "clock_nanosleep", "exit_group", "epoll_wait",
        "epoll_ctl", "tgkill", "utimes", "vserver", "mbind",
        "set_mempolicy", "get_mempolicy", "mq_open", "mq_unlink",
        "mq_timedsend", "mq_timedreceive", "mq_notify",
        "mq_getsetattr", "kexec_load", "waitid", "add_key",
        "request_key", "keyctl", "ioprio_set", "ioprio_get",
        "inotify_init", "inotify_add_watch", "inotify_rm_watch",
        "migrate_pages", "openat", "mkdirat", "mknodat", "fchownat",
        "futimesat", "newfstatat", "unlinkat", "renameat", "linkat",
        "symlinkat", "readlinkat", "fchmodat", "faccessat",
        "pselect6", "ppoll", "unshare", "set_robust_list",
        "get_robust_list", "splice", "tee", "sync_file_range",
        "vmsplice", "move_pages", "utimensat", "epoll_pwait",
        "signalfd", "timerfd_create", "eventfd", "fallocate",
        "timerfd_settime", "timerfd_gettime", "accept4", "signalfd4",
        "eventfd2", "epoll_create1", "dup3", "pipe2", "inotify_init1",
        "preadv", "pwritev", "rt_tgsigqueueinfo", "perf_event_open",
        "recvmmsg", "fanotify_init", "fanotify_mark", "prlimit64",
        "name_to_handle_at", "open_by_handle_at", "clock_adjtime",
        "syncfs", "sendmmsg", "setns", "getcpu", "process_vm_readv",
        "process_vm_writev"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

Apply seccomp profile:
```bash
# Run with custom seccomp profile
docker run -d \
  --security-opt seccomp=./secure-profile.json \
  nginx:alpine
```

### **Read-Only Root Filesystem**

#### **Implementation Pattern**
```dockerfile
FROM alpine:3.16

# Install application
RUN apk add --no-cache nodejs npm && \
    addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY --chown=appuser:appgroup . .

USER appuser

# Application will run with read-only root filesystem
# Writable directories must be mounted as tmpfs or volumes
```

Run with read-only filesystem:
```bash
docker run -d \
  --read-only \
  --tmpfs /tmp:rw,size=100m \
  --tmpfs /var/run:rw,size=10m \
  -v app-data:/app/data \
  myapp:latest
```

---

## 🌐 **Network Security**

### **Network Segmentation**

#### **Multi-Tier Network Architecture**
```yaml
# docker-compose.yml
version: '3.8'

services:
  # Frontend (public access)
  frontend:
    image: nginx:alpine
    networks:
      - public
      - frontend-backend
    ports:
      - "80:80"
      - "443:443"
    
  # Application tier (internal access only)
  backend:
    image: myapp:latest
    networks:
      - frontend-backend
      - backend-database
    
  # Database tier (most restricted)
  database:
    image: postgres:13
    networks:
      - backend-database
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password

networks:
  public:
    driver: bridge
    
  frontend-backend:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.20.0.0/24
          
  backend-database:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.21.0.0/24

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

#### **Network Policies (Kubernetes)**
```yaml
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
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
```

### **TLS and Encryption**

#### **Service-to-Service TLS**
```dockerfile
# TLS-enabled application
FROM alpine:3.16

# Install CA certificates
RUN apk add --no-cache ca-certificates

# Copy application and certificates
COPY app /app
COPY certs/server.crt /etc/ssl/certs/
COPY certs/server.key /etc/ssl/private/
COPY certs/ca.crt /etc/ssl/certs/

# Set proper permissions
RUN chmod 600 /etc/ssl/private/server.key

USER 1001
EXPOSE 8443

CMD ["/app", "--tls-cert=/etc/ssl/certs/server.crt", "--tls-key=/etc/ssl/private/server.key"]
```

#### **Mutual TLS (mTLS) Configuration**
```bash
# Generate CA and certificates
openssl genrsa -out ca.key 4096
openssl req -new -x509 -key ca.key -sha256 -subj "/C=US/ST=CA/O=MyOrg/CN=MyCA" -days 3650 -out ca.crt

# Generate server certificate
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=CA/O=MyOrg/CN=myservice"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -sha256

# Generate client certificate
openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr -subj "/C=US/ST=CA/O=MyOrg/CN=myclient"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365 -sha256
```

### **Firewall and Access Control**

#### **iptables Rules for Docker**
```bash
# Create custom iptables rules for Docker
sudo iptables -N DOCKER-USER

# Block inter-container communication except allowed
sudo iptables -I DOCKER-USER -i docker0 -o docker0 -j DROP

# Allow specific container communication
sudo iptables -I DOCKER-USER -s 172.17.0.2 -d 172.17.0.3 -j ACCEPT

# Log dropped packets
sudo iptables -I DOCKER-USER -j LOG --log-prefix "DOCKER-USER-DROP: "

# Apply rules
sudo iptables-save > /etc/iptables/rules.v4
```

---

## 🔐 **Access Control & Authentication**

### **Docker Daemon Security**

#### **TLS Configuration**
```bash
# Generate certificates for Docker daemon
openssl genrsa -aes256 -out ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

# Server certificate
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=docker-daemon" -sha256 -new -key server-key.pem -out server.csr
echo subjectAltName = DNS:docker-daemon,IP:127.0.0.1 >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -out server-cert.pem -extfile extfile.cnf

# Client certificate
openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
echo extendedKeyUsage = clientAuth > extfile-client.cnf
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -out cert.pem -extfile extfile-client.cnf

# Configure Docker daemon
sudo mkdir -p /etc/docker/certs.d
sudo cp {ca,server-cert,server-key}.pem /etc/docker/certs.d/

# Update daemon configuration
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "hosts": ["tcp://0.0.0.0:2376"],
  "tls": true,
  "tlscert": "/etc/docker/certs.d/server-cert.pem",
  "tlskey": "/etc/docker/certs.d/server-key.pem",
  "tlsverify": true,
  "tlscacert": "/etc/docker/certs.d/ca.pem"
}
EOF

# Connect with TLS
docker --tlsverify --tlscacert=ca.pem --tlscert=cert.pem --tlskey=key.pem -H=docker-daemon:2376 ps
```

#### **User Namespace Mapping**
```bash
# Configure user namespace mapping
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "userns-remap": "default"
}
EOF

# Create subuid and subgid mappings
echo "dockremap:165536:65536" | sudo tee -a /etc/subuid
echo "dockremap:165536:65536" | sudo tee -a /etc/subgid

# Restart Docker
sudo systemctl restart docker

# Verify user namespace
docker run --rm alpine id
```

### **Role-Based Access Control (RBAC)**

#### **Docker Authorization Plugin**
```bash
# Install authorization plugin
docker plugin install store/sumologic/docker-authz-plugin:1.0.0

# Configure plugin
docker plugin set sumologic/docker-authz-plugin:1.0.0 \
  AUTHZ_ENDPOINT=https://authz.example.com

# Enable plugin in daemon configuration
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "authorization-plugins": ["sumologic/docker-authz-plugin:1.0.0"]
}
EOF
```

#### **Custom Authorization Policy**
```json
{
  "policies": [
    {
      "name": "developers",
      "users": ["dev1", "dev2"],
      "actions": ["container:create", "container:start", "container:stop"],
      "resources": ["image:myapp/*", "container:dev-*"]
    },
    {
      "name": "operators",
      "users": ["ops1", "ops2"],
      "actions": ["*"],
      "resources": ["*"],
      "conditions": {
        "time": "09:00-17:00",
        "network": "10.0.0.0/8"
      }
    }
  ]
}
```

---

## 🔑 **Secrets Management**

### **Docker Secrets (Swarm Mode)**

#### **Basic Secrets Management**
```bash
# Create secret from file
echo "mysecretpassword" | docker secret create db_password -

# Create secret from stdin
docker secret create api_key ./api_key.txt

# List secrets
docker secret ls

# Inspect secret (metadata only)
docker secret inspect db_password
```

#### **Using Secrets in Services**
```yaml
version: '3.8'

services:
  database:
    image: postgres:13
    secrets:
      - db_password
      - db_user
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_USER_FILE: /run/secrets/db_user
    
  application:
    image: myapp:latest
    secrets:
      - source: api_key
        target: /app/secrets/api_key
        mode: 0400
        uid: '1000'
        gid: '1000'

secrets:
  db_password:
    external: true
  db_user:
    external: true
  api_key:
    file: ./secrets/api_key.txt
```

### **External Secrets Management**

#### **HashiCorp Vault Integration**
```dockerfile
# Application with Vault integration
FROM alpine:3.16

# Install Vault agent
RUN apk add --no-cache curl && \
    curl -O https://releases.hashicorp.com/vault/1.12.0/vault_1.12.0_linux_amd64.zip && \
    unzip vault_1.12.0_linux_amd64.zip && \
    mv vault /usr/local/bin/ && \
    rm vault_1.12.0_linux_amd64.zip

# Vault configuration
COPY vault-config.json /etc/vault/
COPY app /app/

# Entrypoint script for secret fetching
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/app/server"]
```

```bash
# entrypoint.sh
#!/bin/sh

# Authenticate with Vault
export VAULT_TOKEN=$(vault write -field=token auth/aws/login role=myapp-role)

# Fetch secrets
vault kv get -field=database_password secret/myapp > /tmp/db_password
vault kv get -field=api_key secret/myapp > /tmp/api_key

# Set environment variables
export DATABASE_PASSWORD=$(cat /tmp/db_password)
export API_KEY=$(cat /tmp/api_key)

# Clean up temporary files
rm /tmp/db_password /tmp/api_key

# Start application
exec "$@"
```

#### **AWS Secrets Manager**
```python
# Python application with AWS Secrets Manager
import boto3
import json
from botocore.exceptions import ClientError

def get_secret(secret_name, region_name="us-east-1"):
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e
    
    secret = get_secret_value_response['SecretString']
    return json.loads(secret)

# Usage in application
secrets = get_secret("myapp/production/database")
database_url = f"postgresql://{secrets['username']}:{secrets['password']}@{secrets['host']}:{secrets['port']}/{secrets['dbname']}"
```

---

## 📊 **Monitoring & Incident Response**

### **Security Monitoring Stack**

#### **Falco Runtime Security**
```yaml
version: '3.8'

services:
  falco:
    image: falcosecurity/falco:latest
    privileged: true
    volumes:
      - /var/run/docker.sock:/host/var/run/docker.sock
      - /dev:/host/dev
      - /proc:/host/proc:ro
      - /boot:/host/boot:ro
      - /lib/modules:/host/lib/modules:ro
      - /usr:/host/usr:ro
      - /etc:/host/etc:ro
      - ./falco-rules:/etc/falco/rules.d
    environment:
      - FALCO_GRPC_ENABLED=true
      - FALCO_GRPC_BIND_ADDRESS=0.0.0.0:5060
    ports:
      - "5060:5060"
      
  # Falco Sidekick for alert forwarding
  falcosidekick:
    image: falcosecurity/falcosidekick:latest
    depends_on:
      - falco
    environment:
      - FALCOSIDEKICK_LISTENPORT=2801
      - FALCOSIDEKICK_SLACK_WEBHOOKURL=${SLACK_WEBHOOK}
      - FALCOSIDEKICK_ELASTICSEARCH_HOSTPORT=elasticsearch:9200
    ports:
      - "2801:2801"
```

#### **Custom Falco Rules**
```yaml
# falco-rules/docker-security.yaml
- rule: Suspicious Container Activity
  desc: Detect suspicious activities in containers
  condition: >
    spawned_process and container and
    (proc.name in (nc, netcat, ncat, nmap, dig, nslookup, tcpdump))
  output: >
    Suspicious network tool executed in container
    (user=%user.name command=%proc.cmdline container=%container.name
     image=%container.image.repository)
  priority: WARNING
  tags: [container, network, suspicious]

- rule: Container Privilege Escalation
  desc: Detect privilege escalation attempts
  condition: >
    spawned_process and container and
    proc.name in (sudo, su, passwd, chsh, chfn) and
    not user.name in (root, service)
  output: >
    Privilege escalation attempt detected
    (user=%user.name command=%proc.cmdline container=%container.name)
  priority: CRITICAL
  tags: [container, privilege_escalation]

- rule: Sensitive File Access
  desc: Detect access to sensitive files
  condition: >
    open_read and container and
    fd.name in (/etc/passwd, /etc/shadow, /etc/sudoers,
                /root/.ssh/id_rsa, /home/*/.ssh/id_rsa)
  output: >
    Sensitive file accessed in container
    (file=%fd.name user=%user.name container=%container.name)
  priority: HIGH
  tags: [container, file_access]
```

### **Container Security Scanning**

#### **Runtime Vulnerability Assessment**
```bash
# Docker Bench Security
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
sudo sh docker-bench-security.sh

# Clair for vulnerability scanning
docker run -d --name clair-db postgres:latest
docker run -d --name clair --link clair-db:postgres quay.io/coreos/clair:latest

# Anchore for policy-based scanning
docker run -d --name anchore-db postgres:latest
docker run -d --name anchore-engine --link anchore-db:anchore-db anchore/anchore-engine:latest
```

#### **Continuous Security Monitoring**
```python
# Python security monitoring script
import docker
import json
import time
import logging
from datetime import datetime

class ContainerSecurityMonitor:
    def __init__(self):
        self.client = docker.from_env()
        self.logger = logging.getLogger(__name__)
        
    def check_container_security(self, container):
        security_issues = []
        
        # Check if running as root
        if container.attrs['Config']['User'] == '' or container.attrs['Config']['User'] == 'root':
            security_issues.append("Container running as root")
            
        # Check for privileged mode
        if container.attrs['HostConfig']['Privileged']:
            security_issues.append("Container running in privileged mode")
            
        # Check for host network
        if container.attrs['HostConfig']['NetworkMode'] == 'host':
            security_issues.append("Container using host network")
            
        # Check for mounted sensitive directories
        sensitive_mounts = ['/proc', '/sys', '/dev', '/var/run/docker.sock']
        for mount in container.attrs['Mounts']:
            if mount['Source'] in sensitive_mounts:
                security_issues.append(f"Sensitive directory mounted: {mount['Source']}")
                
        return security_issues
        
    def monitor_containers(self):
        while True:
            try:
                containers = self.client.containers.list()
                for container in containers:
                    issues = self.check_container_security(container)
                    if issues:
                        alert = {
                            'timestamp': datetime.now().isoformat(),
                            'container_id': container.id[:12],
                            'container_name': container.name,
                            'image': container.image.tags[0] if container.image.tags else 'unknown',
                            'security_issues': issues
                        }
                        self.logger.warning(f"Security issues detected: {json.dumps(alert)}")
                        
            except Exception as e:
                self.logger.error(f"Monitoring error: {e}")
                
            time.sleep(60)  # Check every minute

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    monitor = ContainerSecurityMonitor()
    monitor.monitor_containers()
```

---

## 📋 **Compliance & Governance**

### **Security Policies**

#### **Pod Security Standards (Kubernetes)**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

#### **OPA Gatekeeper Policies**
```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: containerrequirements
spec:
  crd:
    spec:
      names:
        kind: ContainerRequirements
      validation:
        openAPIV3Schema:
          type: object
          properties:
            allowedImages:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package containerrequirements
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not starts_with(container.image, input.parameters.allowedImages[_])
          msg := sprintf("Container image %v is not from an allowed registry", [container.image])
        }
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          container.securityContext.runAsRoot == true
          msg := "Container must not run as root"
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: ContainerRequirements
metadata:
  name: must-use-approved-images
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
  parameters:
    allowedImages:
      - "myregistry.com/"
      - "registry.redhat.io/"
```

### **Compliance Frameworks**

#### **CIS Docker Benchmark Implementation**
```bash
# CIS Docker Benchmark automated checking
#!/bin/bash

# 1.1.1 Ensure a separate partition for containers has been created
check_container_partition() {
    if mount | grep -q "/var/lib/docker"; then
        echo "PASS: Separate partition for containers exists"
    else
        echo "FAIL: No separate partition for containers"
    fi
}

# 1.1.2 Ensure only trusted users are allowed to control Docker daemon
check_docker_group() {
    docker_users=$(getent group docker | cut -d: -f4)
    if [ -z "$docker_users" ]; then
        echo "PASS: No users in docker group"
    else
        echo "WARN: Users in docker group: $docker_users"
    fi
}

# 2.1 Ensure network traffic is restricted between containers on the default bridge
check_icc() {
    icc_setting=$(docker system info 2>/dev/null | grep "Default bridge" -A 5 | grep "ICC" | awk '{print $2}')
    if [ "$icc_setting" = "false" ]; then
        echo "PASS: ICC is disabled"
    else
        echo "FAIL: ICC is enabled"
    fi
}

# Run all checks
check_container_partition
check_docker_group
check_icc
```

#### **NIST Cybersecurity Framework Mapping**
```yaml
# Security control mapping
controls:
  identify:
    - id: ID.AM-2
      description: Software platforms and applications within the organization are inventoried
      implementation: 
        - Container image inventory with Trivy scanning
        - SBOM generation for all images
        
  protect:
    - id: PR.AC-1
      description: Identities and credentials are managed for authorized devices and users
      implementation:
        - RBAC for Docker daemon access
        - Service account management
        
    - id: PR.DS-1
      description: Data-at-rest is protected
      implementation:
        - Encrypted container volumes
        - Secrets management with Vault
        
  detect:
    - id: DE.CM-1
      description: The network is monitored to detect potential cybersecurity events
      implementation:
        - Falco runtime security monitoring
        - Network traffic analysis
        
  respond:
    - id: RS.RP-1
      description: Response plan is executed during or after an event
      implementation:
        - Automated incident response playbooks
        - Container isolation procedures
        
  recover:
    - id: RC.RP-1
      description: Recovery plan is executed during or after an event
      implementation:
        - Container backup and restore procedures
        - Disaster recovery testing
```

### **Audit and Logging**

#### **Docker Daemon Audit Configuration**
```bash
# Configure Docker daemon for audit logging
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "audit-level": "info",
  "audit-file": "/var/log/docker-audit.log"
}
EOF

# Restart Docker daemon
sudo systemctl restart docker
```

#### **Centralized Security Logging**
```yaml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
      
  logstash:
    image: docker.elastic.co/logstash/logstash:7.17.0
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
      - /var/log:/var/log:ro
    depends_on:
      - elasticsearch
      
  kibana:
    image: docker.elastic.co/kibana/kibana:7.17.0
    ports:
      - "5601:5601"
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    depends_on:
      - elasticsearch
      
  # Security event collector
  filebeat:
    image: docker.elastic.co/beats/filebeat:7.17.0
    user: root
    volumes:
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - elasticsearch

volumes:
  elasticsearch_data:
```

---

## ✅ **Key Takeaways**

1. **Defense in Depth**: Implement multiple layers of security controls
2. **Image Security**: Scan, sign, and harden container images
3. **Runtime Protection**: Use Linux security modules and capabilities
4. **Network Segmentation**: Isolate services with proper network design
5. **Secrets Management**: Never embed secrets in images or code
6. **Monitoring**: Implement comprehensive security monitoring
7. **Compliance**: Map security controls to regulatory requirements
8. **Incident Response**: Prepare for security incidents with proper tooling

---

## 🎓 **Next Steps**

Ready for **[09-production-patterns](../09-production-patterns/)**? You'll learn:
- High availability architectures
- Monitoring and observability
- CI/CD pipelines
- Performance optimization
- Disaster recovery strategies

---

## 📚 **Additional Resources**

- [Docker Security Documentation](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Container Security Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)
- [Falco Runtime Security](https://falco.org/)
- [Docker Bench Security](https://github.com/docker/docker-bench-security)
