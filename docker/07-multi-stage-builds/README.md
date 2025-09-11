# 07 - Multi-Stage Builds: Advanced Build Optimization

## 🎯 **Learning Objectives**
Master advanced Docker build optimization techniques for production:
- Advanced multi-stage build patterns
- Build performance optimization
- Security-focused build strategies
- CI/CD integration patterns
- Build cache optimization
- Cross-platform builds

---

## 📋 **Table of Contents**
1. [Multi-Stage Architecture](#multi-stage-architecture)
2. [Advanced Build Patterns](#advanced-build-patterns)
3. [Performance Optimization](#performance-optimization)
4. [Security Hardening](#security-hardening)
5. [CI/CD Integration](#cicd-integration)
6. [Cross-Platform Builds](#cross-platform-builds)
7. [Build Cache Strategies](#build-cache-strategies)
8. [Production Examples](#production-examples)

---

## 🏗️ **Multi-Stage Architecture**

### **Multi-Stage Build Concept**
```
┌─────────────────────────────────────────────────┐
│              Build Process Flow                 │
├─────────────────────────────────────────────────┤
│  Stage 1: Dependencies  │  Stage 2: Build       │
│  ┌─────────────────────┐│  ┌───────────────────┐ │
│  │ • Install tools     ││  │ • Compile code    │ │
│  │ • Download deps     ││  │ • Run tests       │ │
│  │ • Setup build env   ││  │ • Generate assets │ │
│  └─────────────────────┘│  └───────────────────┘ │
├─────────────────────────┼─────────────────────────┤
│  Stage 3: Production    │  Final Image            │
│  ┌─────────────────────┐│  ┌───────────────────┐ │
│  │ • Runtime only      ││  │ • Minimal size    │ │
│  │ • No build tools    ││  │ • Security focused│ │
│  │ • Optimized layers  ││  │ • Fast deployment │ │
│  └─────────────────────┘│  └───────────────────┘ │
└─────────────────────────┴─────────────────────────┘
```

### **Basic Multi-Stage Pattern**
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### **Stage Naming and Targeting**
```dockerfile
# Multiple named stages
FROM node:18-alpine AS base
WORKDIR /app
COPY package*.json ./

FROM base AS dependencies
RUN npm ci

FROM base AS development
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
CMD ["npm", "run", "dev"]

FROM dependencies AS test
COPY . .
RUN npm test

FROM dependencies AS build
COPY . .
RUN npm run build

FROM nginx:alpine AS production
COPY --from=build /app/dist /usr/share/nginx/html
```

Build specific stages:
```bash
# Build development image
docker build --target development -t myapp:dev .

# Build test image
docker build --target test -t myapp:test .

# Build production image (default final stage)
docker build -t myapp:prod .
```

---

## 🔧 **Advanced Build Patterns**

### **Parallel Build Stages**
```dockerfile
# Base stage with common dependencies
FROM node:18-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Frontend build (parallel stage 1)
FROM base AS frontend-build
COPY frontend/ ./frontend/
WORKDIR /app/frontend
RUN npm run build

# Backend build (parallel stage 2)
FROM base AS backend-build
COPY backend/ ./backend/
WORKDIR /app/backend
RUN npm run build

# API documentation (parallel stage 3)
FROM base AS docs-build
COPY docs/ ./docs/
WORKDIR /app/docs
RUN npm run build:docs

# Combine all builds in final stage
FROM nginx:alpine AS production
# Copy frontend
COPY --from=frontend-build /app/frontend/dist /usr/share/nginx/html
# Copy backend assets
COPY --from=backend-build /app/backend/public /usr/share/nginx/html/api
# Copy documentation
COPY --from=docs-build /app/docs/dist /usr/share/nginx/html/docs

COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### **Conditional Build Stages**
```dockerfile
ARG BUILD_ENV=production
ARG INCLUDE_TESTS=false

FROM node:18-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Development dependencies (conditional)
FROM base AS dev-deps
RUN if [ "$BUILD_ENV" = "development" ]; then \
        npm install --only=dev; \
    fi

# Testing stage (conditional)
FROM dev-deps AS test
COPY . .
RUN if [ "$INCLUDE_TESTS" = "true" ]; then \
        npm test && npm run lint; \
    fi

# Build stage
FROM base AS build
COPY --from=test /app ./
RUN npm run build

# Production stage
FROM nginx:alpine AS production
COPY --from=build /app/dist /usr/share/nginx/html
```

Build with conditions:
```bash
# Development build with tests
docker build \
  --build-arg BUILD_ENV=development \
  --build-arg INCLUDE_TESTS=true \
  -t myapp:dev .

# Production build without tests
docker build \
  --build-arg BUILD_ENV=production \
  --build-arg INCLUDE_TESTS=false \
  -t myapp:prod .
```

### **Language-Specific Patterns**

#### **Go Multi-Stage Build**
```dockerfile
# Build stage
FROM golang:1.19-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o main .

# Production stage
FROM scratch AS production

# Copy ca-certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy binary
COPY --from=builder /app/main /main

# Expose port
EXPOSE 8080

# Run binary
ENTRYPOINT ["/main"]
```

#### **Python Multi-Stage Build**
```dockerfile
# Build stage
FROM python:3.11-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim AS production

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Run application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

#### **Java Multi-Stage Build**
```dockerfile
# Build stage
FROM maven:3.8.6-openjdk-17 AS builder

WORKDIR /app

# Copy pom.xml and download dependencies (for caching)
COPY pom.xml .
RUN mvn dependency:resolve

# Copy source and build
COPY src ./src
RUN mvn clean package -DskipTests

# Extract JAR layers for better caching
RUN mkdir -p target/dependency && \
    cd target/dependency && \
    jar -xf ../*.jar

# Production stage
FROM openjdk:17-jre-slim AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r spring && useradd -r -g spring spring

# Copy JAR layers for better caching
COPY --from=builder --chown=spring:spring /app/target/dependency/BOOT-INF/lib /app/lib
COPY --from=builder --chown=spring:spring /app/target/dependency/META-INF /app/META-INF
COPY --from=builder --chown=spring:spring /app/target/dependency/BOOT-INF/classes /app

# Switch to non-root user
USER spring

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run application
ENTRYPOINT ["java", "-cp", "app:app/lib/*", "com.example.Application"]
```

---

## ⚡ **Performance Optimization**

### **Build Cache Optimization**

#### **Dockerfile Layer Ordering**
```dockerfile
# ❌ Poor caching - code changes invalidate all layers
FROM node:18-alpine
WORKDIR /app
COPY . .                          # Code changes invalidate everything below
RUN npm install                   # Reinstalls on every code change
RUN npm run build
CMD ["npm", "start"]

# ✅ Optimized caching - dependencies cached separately
FROM node:18-alpine AS base
WORKDIR /app

# Install dependencies first (rarely change)
COPY package*.json ./
RUN npm ci --only=production

# Copy code last (changes frequently)
COPY . .
RUN npm run build

CMD ["npm", "start"]
```

#### **BuildKit Cache Mounts**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM node:18-alpine AS builder

WORKDIR /app

# Use cache mount for npm cache
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Use cache mount for build cache
COPY . .
RUN --mount=type=cache,target=/app/.next/cache \
    npm run build

FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
CMD ["node", "server.js"]
```

#### **External Cache Sources**
```dockerfile
# Use external cache for dependencies
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Build with cache from previous stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build
```

Build with external cache:
```bash
# Build with registry cache
docker build \
  --cache-from myapp:cache \
  --tag myapp:latest \
  --tag myapp:cache \
  .

# Push cache image
docker push myapp:cache
```

### **Multi-Platform Optimization**
```dockerfile
# syntax=docker/dockerfile:1.4
ARG TARGETPLATFORM
ARG BUILDPLATFORM

FROM --platform=$BUILDPLATFORM node:18-alpine AS builder
WORKDIR /app

# Install platform-specific dependencies
RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM"

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage with target platform
FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/server.js"]
```

Build for multiple platforms:
```bash
# Setup buildx
docker buildx create --name multiplatform --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --tag myapp:latest \
  --push .
```

---

## 🔒 **Security Hardening**

### **Minimal Base Images**
```dockerfile
# Ultra-minimal Go binary
FROM golang:1.19-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o app .

# Scratch base (no OS, just binary)
FROM scratch AS production
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/app /app
ENTRYPOINT ["/app"]

# Alternative: Distroless
FROM gcr.io/distroless/static AS production-distroless
COPY --from=builder /app/app /app
ENTRYPOINT ["/app"]
```

### **Security Scanning Integration**
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm audit --audit-level=high
RUN npm ci
COPY . .
RUN npm run build

# Security scan stage
FROM builder AS security-scan
RUN npm audit --audit-level=moderate --audit-level=high

# Production stage
FROM node:18-alpine AS production
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001
WORKDIR /app
COPY --from=builder --chown=nextjs:nodejs /app/dist ./
USER nextjs
CMD ["node", "server.js"]
```

### **Secrets Handling**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM alpine:3.16 AS builder

# Use secret mount (not stored in layers)
RUN --mount=type=secret,id=api_key \
    API_KEY=$(cat /run/secrets/api_key) && \
    curl -H "Authorization: Bearer $API_KEY" \
         https://api.example.com/data > /tmp/data.json

# Production stage without secrets
FROM alpine:3.16 AS production
COPY --from=builder /tmp/data.json /app/data.json
CMD ["app"]
```

Build with secrets:
```bash
echo "secret123" | docker build \
  --secret id=api_key,src=- \
  -t secure-app .
```

---

## 🚀 **CI/CD Integration**

### **GitLab CI Multi-Stage Pipeline**
```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - security
  - deploy

variables:
  DOCKER_BUILDKIT: 1
  DOCKER_DRIVER: overlay2

build:
  stage: build
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    # Build all stages with cache
    - docker build 
        --target test 
        --cache-from $CI_REGISTRY_IMAGE:test-cache
        --tag $CI_REGISTRY_IMAGE:test-$CI_COMMIT_SHA
        --tag $CI_REGISTRY_IMAGE:test-cache
        .
    - docker build 
        --target production 
        --cache-from $CI_REGISTRY_IMAGE:cache
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        --tag $CI_REGISTRY_IMAGE:cache
        .
    - docker push $CI_REGISTRY_IMAGE:test-$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:test-cache
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:cache

test:
  stage: test
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  script:
    - docker run --rm $CI_REGISTRY_IMAGE:test-$CI_COMMIT_SHA

security-scan:
  stage: security
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  script:
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock
        aquasec/trivy image $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

deploy:
  stage: deploy
  image: docker:20.10.16
  script:
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
```

### **GitHub Actions Multi-Stage Workflow**
```yaml
# .github/workflows/docker.yml
name: Docker Multi-Stage Build

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-
      
      - name: Build and test
        uses: docker/build-push-action@v4
        with:
          context: .
          target: test
          load: true
          tags: ${{ env.IMAGE_NAME }}:test
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Run tests
        run: docker run --rm ${{ env.IMAGE_NAME }}:test
      
      - name: Build and push production
        uses: docker/build-push-action@v4
        with:
          context: .
          target: production
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### **Jenkins Pipeline**
```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-registry.com'
        IMAGE_NAME = 'myapp'
        DOCKER_BUILDKIT = '1'
    }
    
    stages {
        stage('Build') {
            parallel {
                stage('Build Test Image') {
                    steps {
                        script {
                            def testImage = docker.build(
                                "${IMAGE_NAME}:test-${BUILD_NUMBER}",
                                "--target test --cache-from ${IMAGE_NAME}:test-cache ."
                            )
                        }
                    }
                }
                
                stage('Build Production Image') {
                    steps {
                        script {
                            def prodImage = docker.build(
                                "${IMAGE_NAME}:${BUILD_NUMBER}",
                                "--target production --cache-from ${IMAGE_NAME}:cache ."
                            )
                        }
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                sh "docker run --rm ${IMAGE_NAME}:test-${BUILD_NUMBER}"
            }
        }
        
        stage('Security Scan') {
            steps {
                sh """
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy image ${IMAGE_NAME}:${BUILD_NUMBER}
                """
            }
        }
        
        stage('Push') {
            when {
                branch 'main'
            }
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry-credentials') {
                        def image = docker.image("${IMAGE_NAME}:${BUILD_NUMBER}")
                        image.push()
                        image.push("latest")
                        
                        // Push cache images
                        def testCache = docker.image("${IMAGE_NAME}:test-cache")
                        testCache.push()
                        def prodCache = docker.image("${IMAGE_NAME}:cache")
                        prodCache.push()
                    }
                }
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f'
        }
    }
}
```

---

## 🌐 **Cross-Platform Builds**

### **Platform-Specific Optimizations**
```dockerfile
# syntax=docker/dockerfile:1.4
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

FROM --platform=$BUILDPLATFORM golang:1.19-alpine AS builder

WORKDIR /app

# Install platform-specific build tools
RUN case "$TARGETARCH" in \
        amd64) apk add --no-cache gcc-x86_64-linux-gnu ;; \
        arm64) apk add --no-cache gcc-aarch64-linux-gnu ;; \
        arm) apk add --no-cache gcc-arm-linux-gnueabihf ;; \
    esac

# Copy source
COPY . .

# Build for target platform
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0 \
    go build -o app-$TARGETARCH .

# Production stage
FROM alpine:3.16 AS production

ARG TARGETARCH

# Copy the correct binary for target architecture
COPY --from=builder /app/app-$TARGETARCH /app

# Install platform-specific runtime dependencies
RUN case "$TARGETARCH" in \
        amd64) echo "Setting up for x86_64" ;; \
        arm64) echo "Setting up for ARM64" ;; \
        arm) echo "Setting up for ARM32" ;; \
    esac

ENTRYPOINT ["/app"]
```

### **Buildx Configuration**
```bash
# Create builder instance
docker buildx create \
  --name multiplatform \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --tag myapp:latest \
  --push .

# Build platform-specific tags
docker buildx build \
  --platform linux/amd64 \
  --tag myapp:amd64 \
  --push .

docker buildx build \
  --platform linux/arm64 \
  --tag myapp:arm64 \
  --push .
```

---

## 🧪 **Production Examples**

### **Full-Stack Application**
```dockerfile
# syntax=docker/dockerfile:1.4
# Multi-stage build for full-stack application

# Base Node.js stage
FROM node:18-alpine AS node-base
WORKDIR /app
RUN apk add --no-cache libc6-compat

# Frontend dependencies
FROM node-base AS frontend-deps
COPY frontend/package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Backend dependencies  
FROM node-base AS backend-deps
COPY backend/package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Frontend build
FROM frontend-deps AS frontend-build
COPY frontend/ ./
RUN --mount=type=cache,target=./.next/cache \
    npm run build

# Backend build
FROM backend-deps AS backend-build
COPY backend/ ./
RUN npm run build

# Backend production dependencies
FROM node-base AS backend-prod-deps
COPY backend/package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production

# Final production stage
FROM node:18-alpine AS production

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

WORKDIR /app

# Copy backend
COPY --from=backend-build --chown=nextjs:nodejs /app/dist ./backend/
COPY --from=backend-prod-deps --chown=nextjs:nodejs /app/node_modules ./backend/node_modules/

# Copy frontend
COPY --from=frontend-build --chown=nextjs:nodejs /app/.next/standalone ./frontend/
COPY --from=frontend-build --chown=nextjs:nodejs /app/.next/static ./frontend/.next/static/
COPY --from=frontend-build --chown=nextjs:nodejs /app/public ./frontend/public/

# Copy startup script
COPY --chown=nextjs:nodejs start.sh ./
RUN chmod +x start.sh

USER nextjs

EXPOSE 3000 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health && curl -f http://localhost:8000/health

CMD ["./start.sh"]
```

### **Microservice with Testing**
```dockerfile
# syntax=docker/dockerfile:1.4
ARG BUILD_ENV=production

# Base stage
FROM node:18-alpine AS base
WORKDIR /app
RUN apk add --no-cache dumb-init

# Dependencies
FROM base AS deps
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Development dependencies (conditional)
FROM deps AS dev-deps
ARG BUILD_ENV
RUN if [ "$BUILD_ENV" = "development" ]; then \
        npm install --only=dev; \
    fi

# Linting stage
FROM dev-deps AS lint
COPY . .
RUN npm run lint

# Testing stage
FROM dev-deps AS test
COPY . .
RUN npm test -- --coverage --watchAll=false
RUN npm run test:integration

# Security audit
FROM deps AS audit
RUN npm audit --audit-level=high

# Build stage
FROM deps AS build
COPY . .
RUN npm run build

# Production stage
FROM base AS production

# Copy built application
COPY --from=build /app/dist ./dist/
COPY --from=deps /app/node_modules ./node_modules/

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S service -u 1001 -G nodejs

USER service

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

---

## 📊 **Advanced Build Cache Strategies**

### **Registry Cache**
```bash
# Build with registry cache
docker build \
  --cache-from myregistry.com/myapp:cache \
  --tag myapp:latest \
  .

# Push cache layers
docker tag myapp:latest myregistry.com/myapp:cache
docker push myregistry.com/myapp:cache
```

### **Local Cache Export/Import**
```bash
# Export build cache
docker buildx build \
  --cache-to type=local,dest=./cache \
  --tag myapp:latest \
  .

# Import build cache
docker buildx build \
  --cache-from type=local,src=./cache \
  --tag myapp:latest \
  .
```

### **GitHub Actions Cache**
```dockerfile
# In GitHub Actions workflow
- name: Build with cache
  uses: docker/build-push-action@v4
  with:
    context: .
    push: true
    tags: ${{ env.IMAGE_NAME }}:latest
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

## 🔧 **Debugging Multi-Stage Builds**

### **Build Debugging Techniques**
```bash
# Build specific stage for debugging
docker build --target builder -t debug-builder .

# Run shell in build stage
docker run -it debug-builder sh

# Inspect intermediate layers
docker build --rm=false .
docker images -a

# Use dive to analyze layers
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest myapp:latest
```

### **Build Arguments for Debugging**
```dockerfile
ARG DEBUG=false

# Debug stage (conditional)
FROM builder AS debug
ARG DEBUG
RUN if [ "$DEBUG" = "true" ]; then \
        apk add --no-cache curl vim htop && \
        echo "Debug tools installed"; \
    fi

# Production inherits from debug
FROM debug AS production
# Remove debug tools in production
RUN if [ "$DEBUG" != "true" ]; then \
        apk del curl vim htop 2>/dev/null || true; \
    fi
```

---

## ✅ **Key Takeaways**

1. **Build Optimization**: Use multi-stage builds to minimize final image size
2. **Cache Strategy**: Optimize layer ordering and use BuildKit cache features
3. **Security**: Implement secrets handling and minimal base images
4. **CI/CD Integration**: Design builds for automated pipelines
5. **Cross-Platform**: Support multiple architectures with buildx
6. **Performance**: Leverage parallel builds and external caches
7. **Debugging**: Master techniques for troubleshooting build issues

---

## 🎓 **Next Steps**

Ready for **[08-docker-security](../08-docker-security/)**? You'll learn:
- Container security fundamentals
- Image vulnerability scanning
- Runtime security monitoring
- Security best practices
- Compliance and governance

---

## 📚 **Additional Resources**

- [Multi-Stage Builds Documentation](https://docs.docker.com/develop/dev-best-practices/#use-multi-stage-builds)
- [BuildKit Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Docker Build Cache](https://docs.docker.com/develop/dev-best-practices/#leverage-build-cache)
- [Cross-Platform Builds](https://docs.docker.com/buildx/working-with-buildx/#build-multi-platform-images)
