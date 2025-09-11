# 03 - Dockerfile Basics: Building Production-Ready Images

## 🎯 **Learning Objectives**
Master the art of creating efficient, secure, and production-ready Docker images:
- Advanced Dockerfile instructions and best practices
- Multi-stage build patterns for optimization
- Security hardening techniques
- Image optimization strategies
- Real-world Dockerfile examples

---

## 📋 **Table of Contents**
1. [Dockerfile Fundamentals](#dockerfile-fundamentals)
2. [Essential Instructions](#essential-instructions)
3. [Multi-Stage Builds](#multi-stage-builds)
4. [Security Best Practices](#security-best-practices)
5. [Optimization Strategies](#optimization-strategies)
6. [Real-World Examples](#real-world-examples)
7. [Advanced Techniques](#advanced-techniques)
8. [Production Patterns](#production-patterns)

---

## 📝 **Dockerfile Fundamentals**

### **What is a Dockerfile?**
A Dockerfile is a text file containing instructions to build Docker images automatically. Each instruction creates a new layer in the image.

### **Basic Structure**
```dockerfile
# Comment: Dockerfile syntax
FROM base_image:tag
LABEL maintainer="you@company.com"
RUN instruction
COPY source destination
EXPOSE port
CMD ["executable", "param1", "param2"]
```

### **Build Context**
The build context is the directory sent to Docker daemon during build:
```bash
# Current directory as context
docker build -t myapp:latest .

# Specific directory as context
docker build -t myapp:latest /path/to/context

# Remote context
docker build -t myapp:latest https://github.com/user/repo.git#branch:subdir
```

### **Dockerfile vs Docker Image vs Container**
```
Dockerfile  ──build──>  Image  ──run──>  Container
    │                    │                  │
 Recipe            Template           Running Instance
```

---

## 🔧 **Essential Instructions**

### **FROM - Base Image Selection**
```dockerfile
# Official base images (recommended)
FROM node:18-alpine
FROM python:3.11-slim
FROM nginx:1.23-alpine
FROM ubuntu:22.04

# Multi-platform base
FROM --platform=$BUILDPLATFORM node:18-alpine

# Scratch (empty base)
FROM scratch
COPY binary /
ENTRYPOINT ["/binary"]
```

### **RUN - Execute Commands**
```dockerfile
# Single command
RUN apt-get update

# Multiple commands (efficient)
RUN apt-get update && \
    apt-get install -y \
        curl \
        git \
        vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Using different shells
RUN ["/bin/bash", "-c", "echo hello"]

# Alpine package management
RUN apk add --no-cache \
    curl \
    git \
    && rm -rf /var/cache/apk/*
```

### **COPY vs ADD**
```dockerfile
# COPY (preferred for simple file copying)
COPY package.json /app/
COPY src/ /app/src/
COPY --chown=1000:1000 app.py /app/

# ADD (auto-extraction and remote URLs)
ADD https://example.com/file.tar.gz /tmp/
ADD archive.tar.gz /app/  # Auto-extracts

# Best practice: Use COPY unless you need ADD's features
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
```

### **WORKDIR - Set Working Directory**
```dockerfile
# Set working directory
WORKDIR /app

# Create directory if it doesn't exist
WORKDIR /app/src

# Use absolute paths (recommended)
WORKDIR /usr/src/app

# Avoid using cd in RUN
# ❌ Bad
RUN cd /app && npm install

# ✅ Good
WORKDIR /app
RUN npm install
```

### **ENV - Environment Variables**
```dockerfile
# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV PATH=/app/bin:$PATH

# Multiple variables
ENV NODE_ENV=production \
    PORT=3000 \
    DEBUG=false

# Use in subsequent instructions
ENV APP_HOME=/app
WORKDIR $APP_HOME
COPY . $APP_HOME
```

### **ARG - Build Arguments**
```dockerfile
# Define build arguments
ARG NODE_VERSION=18
ARG BUILD_DATE
ARG VERSION=1.0.0

FROM node:${NODE_VERSION}-alpine

# Use build args
LABEL build_date=${BUILD_DATE}
LABEL version=${VERSION}

# ARG after FROM (scope reset)
FROM node:18-alpine
ARG BUILD_ENV=production
RUN echo "Building for: $BUILD_ENV"
```

Build with arguments:
```bash
docker build \
  --build-arg NODE_VERSION=16 \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VERSION=2.0.0 \
  -t myapp:latest .
```

### **EXPOSE - Port Documentation**
```dockerfile
# Document exposed ports (metadata only)
EXPOSE 3000
EXPOSE 8080/tcp
EXPOSE 53/udp

# Multiple ports
EXPOSE 80 443 22
```

### **USER - Security**
```dockerfile
# Create non-root user
RUN groupadd -r appuser && \
    useradd -r -g appuser appuser

# Switch to non-root user
USER appuser

# Numeric UID/GID (recommended for security)
USER 1001:1001

# Switch back to root if needed
USER root
RUN apt-get update
USER appuser
```

### **CMD vs ENTRYPOINT**

#### **CMD - Default Command**
```dockerfile
# Exec form (preferred)
CMD ["node", "server.js"]

# Shell form
CMD node server.js

# Can be overridden
docker run myapp npm test  # Overrides CMD
```

#### **ENTRYPOINT - Fixed Command**
```dockerfile
# Always executes, cannot be overridden
ENTRYPOINT ["node", "server.js"]

# Combined with CMD for default parameters
ENTRYPOINT ["node"]
CMD ["server.js"]
```

#### **Best Practice Combination**
```dockerfile
# Flexible entry point
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "server.js"]

# docker-entrypoint.sh handles initialization
```

---

## 🏗️ **Multi-Stage Builds**

### **Why Multi-Stage Builds?**
- **Smaller final images**: Remove build dependencies
- **Security**: Fewer attack surfaces
- **Efficiency**: Faster deployments
- **Clean separation**: Build vs runtime environments

### **Basic Multi-Stage Pattern**
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Production stage
FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY src ./src
USER node
EXPOSE 3000
CMD ["node", "src/server.js"]
```

### **Advanced Multi-Stage Examples**

#### **Go Application**
```dockerfile
# Build stage
FROM golang:1.19-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# Production stage (minimal)
FROM scratch
COPY --from=builder /app/main /main
EXPOSE 8080
ENTRYPOINT ["/main"]
```

#### **React Application**
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### **Python Application with Virtual Environment**
```dockerfile
# Build stage
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN python -m venv venv && \
    . venv/bin/activate && \
    pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim AS production
WORKDIR /app
COPY --from=builder /app/venv ./venv
COPY . .
ENV PATH="/app/venv/bin:$PATH"
USER nobody
CMD ["python", "app.py"]
```

### **Parallel Multi-Stage Builds**
```dockerfile
# Base development dependencies
FROM node:18-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Development stage
FROM base AS development
COPY . .
CMD ["npm", "run", "dev"]

# Testing stage
FROM base AS test
COPY . .
RUN npm test

# Production build
FROM base AS build
COPY . .
RUN npm run build

# Production runtime
FROM nginx:alpine AS production
COPY --from=build /app/dist /usr/share/nginx/html
```

Build specific stages:
```bash
# Build development image
docker build --target development -t myapp:dev .

# Build test image
docker build --target test -t myapp:test .

# Build production image
docker build --target production -t myapp:prod .
```

---

## 🔒 **Security Best Practices**

### **Base Image Security**
```dockerfile
# Use official, maintained base images
FROM node:18-alpine  # Official Node.js on Alpine

# Use specific tags, avoid 'latest'
FROM node:18.12.1-alpine3.16

# Use minimal base images
FROM alpine:3.16      # 5MB
FROM distroless/java  # No shell, package manager
FROM scratch          # Empty base
```

### **User Management**
```dockerfile
# Create non-root user
FROM alpine:3.16
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set proper ownership
COPY --chown=appuser:appgroup app.py /app/

# Switch to non-root user
USER appuser

# Numeric user (security scanners prefer)
USER 1001:1001
```

### **Filesystem Security**
```dockerfile
# Read-only root filesystem
FROM alpine:3.16
RUN mkdir /app && \
    chown 1001:1001 /app
USER 1001:1001
WORKDIR /app

# Runtime: docker run --read-only --tmpfs /tmp myapp
```

### **Secrets Management**
```dockerfile
# ❌ Don't embed secrets
ENV API_KEY=secret123  # Visible in image layers

# ✅ Use runtime secrets
# Pass via environment or mount
# docker run -e API_KEY_FILE=/run/secrets/api_key myapp

# ✅ Multi-stage to remove secrets
FROM alpine AS secrets
ARG API_KEY
RUN echo "$API_KEY" > /tmp/key && \
    process_with_key && \
    rm /tmp/key

FROM alpine AS final
COPY --from=secrets /processed_data /app/
```

### **Package Security**
```dockerfile
# Update packages
FROM ubuntu:22.04
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        package1 \
        package2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Remove package managers (production)
FROM alpine:3.16 AS builder
RUN apk add --no-cache build-base
# ... build process

FROM alpine:3.16 AS production
RUN apk add --no-cache --purge ca-certificates
COPY --from=builder /app/binary /app/
```

### **Vulnerability Scanning**
```dockerfile
# Add labels for tracking
LABEL org.opencontainers.image.source="https://github.com/user/repo"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.created="2023-01-01T00:00:00Z"
```

Scan images:
```bash
# Docker Scout
docker scout cves myapp:latest
docker scout recommendations myapp:latest

# Trivy
trivy image myapp:latest

# Snyk
snyk container test myapp:latest
```

---

## 🚀 **Optimization Strategies**

### **Layer Optimization**

#### **Combine RUN Instructions**
```dockerfile
# ❌ Multiple layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean

# ✅ Single layer
RUN apt-get update && \
    apt-get install -y \
        curl \
        git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

#### **Order Instructions by Change Frequency**
```dockerfile
# Least frequently changed first
FROM node:18-alpine
WORKDIR /app

# System dependencies (rarely change)
RUN apk add --no-cache git python3 make g++

# Application dependencies (change occasionally)
COPY package*.json ./
RUN npm ci --only=production

# Application code (changes frequently)
COPY src ./src

# Runtime configuration (changes frequently)
ENV NODE_ENV=production
CMD ["node", "src/server.js"]
```

### **Size Optimization**

#### **Use .dockerignore**
```dockerignore
# .dockerignore
node_modules
npm-debug.log*
.git
.gitignore
README.md
Dockerfile*
.dockerignore
.env*
coverage/
.nyc_output
dist/
build/
*.log
```

#### **Minimize Layers and Size**
```dockerfile
FROM alpine:3.16

# Install and clean in same layer
RUN apk add --no-cache \
    curl=7.83.1-r0 \
    git=2.36.2-r0 \
    && rm -rf /var/cache/apk/*

# Remove build dependencies after use
RUN apk add --no-cache --virtual .build-deps \
    build-base \
    python3-dev \
    && pip install some-package \
    && apk del .build-deps
```

#### **Multi-Stage Size Comparison**
```dockerfile
# Single stage: ~200MB
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
CMD ["node", "dist/server.js"]

# Multi-stage: ~50MB
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/server.js"]
```

### **Build Cache Optimization**

#### **Leverage BuildKit**
```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
docker build -t myapp .

# Or per build
DOCKER_BUILDKIT=1 docker build -t myapp .
```

#### **Cache Mount Points**
```dockerfile
# syntax=docker/dockerfile:1
FROM golang:1.19-alpine

# Cache Go modules
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Cache build cache
RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -o main .
```

#### **Bind Mounts for Development**
```dockerfile
# syntax=docker/dockerfile:1
FROM node:18-alpine
WORKDIR /app

# Development with bind mount
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci
```

---

## 🌟 **Real-World Examples**

### **Example 1: Node.js Web Application**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM node:18-alpine AS base

# Install dependencies for native modules
RUN apk add --no-cache \
    dumb-init \
    && addgroup -g 1001 -S nodejs \
    && adduser -S nextjs -u 1001

# Dependencies stage
FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production && \
    npm cache clean --force

# Build stage
FROM base AS builder
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci
COPY . .
RUN npm run build

# Production stage
FROM base AS production
WORKDIR /app
ENV NODE_ENV=production

# Copy built application
COPY --from=deps --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

USER nextjs
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

### **Example 2: Python Flask Application**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM python:3.11-slim as base

# System dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid appuser --shell /bin/bash --create-home appuser

# Dependencies stage
FROM base AS deps
WORKDIR /app
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# Production stage
FROM python:3.11-slim AS production

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 appuser \
    && useradd --uid 1000 --gid appuser --shell /bin/bash --create-home appuser

WORKDIR /app

# Copy Python dependencies
COPY --from=deps /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=deps /usr/local/bin /usr/local/bin

# Copy application
COPY --chown=appuser:appuser . .

USER appuser
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]
```

### **Example 3: Java Spring Boot Application**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM eclipse-temurin:17-jdk-alpine AS base

# Dependencies stage
FROM base AS deps
WORKDIR /app
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw dependency:resolve

# Build stage
FROM deps AS build
COPY src src
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw package -DskipTests

# Extract JAR layers
FROM build AS extract
WORKDIR /app
RUN java -Djarmode=layertools -jar target/*.jar extract

# Production stage
FROM eclipse-temurin:17-jre-alpine AS production

# Create non-root user
RUN addgroup -g 1001 -S spring && \
    adduser -u 1001 -S spring -G spring

WORKDIR /app

# Copy JAR layers for better caching
COPY --from=extract --chown=spring:spring app/dependencies/ ./
COPY --from=extract --chown=spring:spring app/spring-boot-loader/ ./
COPY --from=extract --chown=spring:spring app/snapshot-dependencies/ ./
COPY --from=extract --chown=spring:spring app/application/ ./

USER spring
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
```

### **Example 4: Static Website with Nginx**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine AS production

# Copy built assets
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create non-root user for nginx
RUN addgroup -g 1001 -S nginx-user && \
    adduser -u 1001 -D -S -G nginx-user nginx-user

# Change ownership of nginx directories
RUN chown -R nginx-user:nginx-user /var/cache/nginx && \
    chown -R nginx-user:nginx-user /var/log/nginx && \
    chown -R nginx-user:nginx-user /etc/nginx/conf.d

# Change nginx port to non-privileged
RUN sed -i.bak 's/listen\s*80;/listen 8080;/' /etc/nginx/conf.d/default.conf

USER nginx-user
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

---

## 🔬 **Advanced Techniques**

### **BuildKit Advanced Features**

#### **Secrets Management**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM alpine
RUN --mount=type=secret,id=api_key \
    API_KEY=$(cat /run/secrets/api_key) && \
    curl -H "Authorization: Bearer $API_KEY" https://api.example.com/data
```

Build with secrets:
```bash
echo "secret123" | docker build \
    --secret id=api_key,src=- \
    -t myapp .
```

#### **SSH Mount for Private Repositories**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM alpine
RUN apk add --no-cache git openssh-client
RUN --mount=type=ssh \
    git clone git@github.com:private/repo.git /app
```

Build with SSH:
```bash
docker build --ssh default -t myapp .
```

#### **Cache Mounts**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM golang:1.19
WORKDIR /app
COPY go.mod go.sum ./

# Cache Go modules
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .

# Cache build artifacts
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o main .
```

### **Custom Build Arguments**
```dockerfile
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG BUILDOS
ARG BUILDARCH
ARG TARGETOS
ARG TARGETARCH

FROM --platform=$BUILDPLATFORM alpine AS base
RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM"

# Platform-specific logic
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        echo "ARM64 specific setup"; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
        echo "AMD64 specific setup"; \
    fi
```

### **Heredoc Syntax**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM alpine

RUN <<EOF
apk add --no-cache curl
curl -O https://example.com/file.tar.gz
tar -xzf file.tar.gz
rm file.tar.gz
EOF

COPY <<EOF /app/config.yaml
server:
  port: 8080
  host: 0.0.0.0
database:
  url: postgresql://db:5432/app
EOF
```

---

## 🏭 **Production Patterns**

### **Health Checks**
```dockerfile
# HTTP health check
HEALTHCHECK --interval=30s \
            --timeout=10s \
            --start-period=60s \
            --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Custom script health check
COPY healthcheck.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/healthcheck.sh
HEALTHCHECK --interval=30s CMD healthcheck.sh

# Database health check
HEALTHCHECK --interval=30s \
    CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1
```

### **Signal Handling**
```dockerfile
# Install init system for proper signal handling
RUN apk add --no-cache dumb-init

# Use dumb-init as entrypoint
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]

# Alternative: tini
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "server.js"]
```

### **Configuration Management**
```dockerfile
# Environment-based configuration
ENV NODE_ENV=production
ENV LOG_LEVEL=info
ENV DB_POOL_SIZE=10

# Configuration file templating
COPY config.template.yaml /app/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "server.js"]
```

### **Logging Configuration**
```dockerfile
# Configure log rotation
RUN mkdir -p /app/logs && \
    touch /app/logs/app.log && \
    chown -R appuser:appuser /app/logs

# Use structured logging
ENV LOG_FORMAT=json
ENV LOG_LEVEL=info

# Log to stdout (container best practice)
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log
```

### **Graceful Shutdown**
```dockerfile
# docker-entrypoint.sh example
COPY <<EOF /usr/local/bin/docker-entrypoint.sh
#!/bin/sh
set -e

# Function to handle shutdown
shutdown() {
    echo "Shutting down gracefully..."
    kill -TERM "$child" 2>/dev/null
    wait "$child"
}

# Set trap for graceful shutdown
trap shutdown TERM INT

# Start application
exec "$@" &
child=$!
wait "$child"
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
```

---

## 📊 **Best Practices Checklist**

### **Security ✅**
- [ ] Use official base images with specific tags
- [ ] Run as non-root user (numeric UID preferred)
- [ ] Don't embed secrets in layers
- [ ] Keep packages updated
- [ ] Use read-only filesystem when possible
- [ ] Implement proper health checks
- [ ] Scan images for vulnerabilities

### **Performance ✅**
- [ ] Use multi-stage builds for production
- [ ] Order instructions by change frequency
- [ ] Combine RUN instructions to reduce layers
- [ ] Use .dockerignore to exclude unnecessary files
- [ ] Leverage build cache with BuildKit
- [ ] Use Alpine or distroless base images
- [ ] Implement proper signal handling

### **Maintainability ✅**
- [ ] Add descriptive labels
- [ ] Use meaningful build argument names
- [ ] Document complex instructions with comments
- [ ] Pin dependency versions
- [ ] Use consistent naming conventions
- [ ] Implement proper logging strategies
- [ ] Version your images semantically

### **Production Readiness ✅**
- [ ] Configure health checks
- [ ] Implement graceful shutdown
- [ ] Set appropriate resource limits
- [ ] Configure log management
- [ ] Use init systems for signal handling
- [ ] Implement configuration management
- [ ] Test in production-like environments

---

## 🧪 **Advanced Practice Labs**

### **Lab 1: Multi-Stage Optimization**
Create a Dockerfile that reduces image size by 80%:
```dockerfile
# Challenge: Optimize this single-stage build
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
RUN npm test
CMD ["npm", "start"]
```

### **Lab 2: Security Hardening**
Implement all security best practices:
```dockerfile
# Challenge: Secure this Dockerfile
FROM ubuntu:latest
RUN apt-get update && apt-get install -y python3 pip
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
USER root
CMD python3 app.py
```

### **Lab 3: Build Performance**
Optimize build time using caching:
```dockerfile
# Challenge: Make this build faster on code changes
FROM python:3.11
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
RUN python setup.py install
CMD ["python", "app.py"]
```

---

## ✅ **Key Takeaways**

1. **Multi-Stage Builds**: Essential for production-ready images
2. **Security First**: Never run as root, scan for vulnerabilities
3. **Layer Optimization**: Order and combine instructions wisely
4. **Cache Leverage**: Use BuildKit features for faster builds
5. **Production Patterns**: Health checks, signal handling, logging
6. **Real-World Testing**: Always test in production-like environments

---

## 🎓 **Next Steps**

Ready for **[04-docker-networking](../04-docker-networking/)**? You'll explore:
- Advanced networking concepts
- Service discovery patterns
- Load balancing strategies
- Network security implementation
- Production networking architectures

---

## 📚 **Additional Resources**

- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [BuildKit Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Multi-Stage Builds](https://docs.docker.com/develop/dev-best-practices/#use-multi-stage-builds)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Image Vulnerability Scanning](https://docs.docker.com/scout/)
