# 09 - Production Patterns: Enterprise Docker Deployment

## 🎯 **Learning Objectives**
Master production-grade Docker patterns for enterprise environments:
- High availability architectures
- Monitoring and observability
- CI/CD integration patterns
- Performance optimization
- Disaster recovery strategies
- Scaling and load balancing

---

## 📋 **Table of Contents**
1. [High Availability Architecture](#high-availability-architecture)
2. [Container Orchestration Patterns](#container-orchestration-patterns)
3. [Monitoring & Observability](#monitoring--observability)
4. [CI/CD Pipeline Integration](#cicd-pipeline-integration)
5. [Performance Optimization](#performance-optimization)
6. [Disaster Recovery & Backup](#disaster-recovery--backup)
7. [Auto-scaling Patterns](#auto-scaling-patterns)
8. [Production Troubleshooting](#production-troubleshooting)

---

## 🏗️ **High Availability Architecture**

### **Multi-Zone Deployment Pattern**
```yaml
# docker-compose-ha.yml - Production HA Setup
version: '3.8'

services:
  # Load Balancer (Multiple instances)
  nginx-lb-1:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    networks:
      - frontend
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      restart_policy:
        condition: any
        delay: 5s
        max_attempts: 3
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Application Tier (Auto-scaling)
  app:
    image: myapp:${APP_VERSION:-latest}
    environment:
      - NODE_ENV=production
      - DATABASE_URL_FILE=/run/secrets/db_url
      - REDIS_URL_FILE=/run/secrets/redis_url
    secrets:
      - db_url
      - redis_url
    networks:
      - frontend
      - backend
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        monitor: 60s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # Database Cluster (Primary-Replica)
  postgres-primary:
    image: postgres:13-alpine
    environment:
      POSTGRES_USER_FILE: /run/secrets/postgres_user
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
      POSTGRES_DB: myapp
      POSTGRES_REPLICATION_MODE: master
      POSTGRES_REPLICATION_USER_FILE: /run/secrets/replication_user
      POSTGRES_REPLICATION_PASSWORD_FILE: /run/secrets/replication_password
    volumes:
      - postgres_primary_data:/var/lib/postgresql/data
      - ./postgres/init:/docker-entrypoint-initdb.d
    networks:
      - backend
    secrets:
      - postgres_user
      - postgres_password
      - replication_user
      - replication_password
    deploy:
      placement:
        constraints:
          - node.labels.db-primary == true
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3

  postgres-replica:
    image: postgres:13-alpine
    environment:
      POSTGRES_USER_FILE: /run/secrets/postgres_user
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
      POSTGRES_DB: myapp
      POSTGRES_REPLICATION_MODE: slave
      POSTGRES_REPLICATION_USER_FILE: /run/secrets/replication_user
      POSTGRES_REPLICATION_PASSWORD_FILE: /run/secrets/replication_password
      POSTGRES_MASTER_SERVICE: postgres-primary
    volumes:
      - postgres_replica_data:/var/lib/postgresql/data
    networks:
      - backend
    secrets:
      - postgres_user
      - postgres_password
      - replication_user
      - replication_password
    deploy:
      replicas: 2
      placement:
        constraints:
          - node.labels.db-replica == true
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3

  # Redis Cluster
  redis-master:
    image: redis:6-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    volumes:
      - redis_master_data:/data
    networks:
      - backend
    deploy:
      placement:
        constraints:
          - node.labels.redis-master == true

  redis-replica:
    image: redis:6-alpine
    command: redis-server --slaveof redis-master 6379 --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_replica_data:/data
    networks:
      - backend
    deploy:
      replicas: 2
      placement:
        constraints:
          - node.labels.redis-replica == true

networks:
  frontend:
    driver: overlay
    attachable: true
  backend:
    driver: overlay
    internal: true

volumes:
  postgres_primary_data:
    driver: local
  postgres_replica_data:
    driver: local
  redis_master_data:
    driver: local
  redis_replica_data:
    driver: local

secrets:
  db_url:
    external: true
  redis_url:
    external: true
  postgres_user:
    external: true
  postgres_password:
    external: true
  replication_user:
    external: true
  replication_password:
    external: true
```

### **Blue-Green Deployment Pattern**
```bash
#!/bin/bash
# blue-green-deploy.sh

set -e

# Configuration
STACK_NAME="myapp"
BLUE_STACK="${STACK_NAME}-blue"
GREEN_STACK="${STACK_NAME}-green"
NEW_VERSION=$1

if [ -z "$NEW_VERSION" ]; then
    echo "Usage: $0 <new_version>"
    exit 1
fi

# Function to check service health
check_health() {
    local stack=$1
    local max_attempts=30
    local attempt=1
    
    echo "Checking health of $stack..."
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost/health >/dev/null 2>&1; then
            echo "✅ $stack is healthy"
            return 0
        fi
        echo "⏳ Attempt $attempt/$max_attempts - waiting for $stack to be healthy..."
        sleep 10
        ((attempt++))
    done
    
    echo "❌ $stack failed health check"
    return 1
}

# Get current active stack
CURRENT_ACTIVE=$(docker service ls --filter "name=${STACK_NAME}-" --format "{{.Name}}" | head -1)

if [[ "$CURRENT_ACTIVE" == *"blue"* ]]; then
    ACTIVE_STACK="$BLUE_STACK"
    INACTIVE_STACK="$GREEN_STACK"
    NEW_COLOR="green"
else
    ACTIVE_STACK="$GREEN_STACK"
    INACTIVE_STACK="$BLUE_STACK"
    NEW_COLOR="blue"
fi

echo "🔄 Current active: $ACTIVE_STACK"
echo "🚀 Deploying to: $INACTIVE_STACK with version $NEW_VERSION"

# Deploy new version to inactive stack
export APP_VERSION=$NEW_VERSION
docker stack deploy -c docker-compose-ha.yml $INACTIVE_STACK

# Wait for new stack to be healthy
if check_health $INACTIVE_STACK; then
    echo "🔀 Switching traffic to $INACTIVE_STACK"
    
    # Update load balancer to point to new stack
    sed -i "s/$ACTIVE_STACK/$INACTIVE_STACK/g" nginx/nginx.conf
    docker service update --force ${ACTIVE_STACK}_nginx-lb-1
    
    # Wait a bit for traffic to switch
    sleep 30
    
    # Verify new stack is serving traffic correctly
    if check_health $INACTIVE_STACK; then
        echo "✅ Deployment successful! $INACTIVE_STACK is now active"
        
        # Remove old stack
        echo "🗑️ Removing old stack: $ACTIVE_STACK"
        docker stack rm $ACTIVE_STACK
        
        echo "🎉 Blue-green deployment completed successfully!"
    else
        echo "❌ New stack failed post-switch health check"
        echo "🔙 Rolling back..."
        
        # Rollback
        sed -i "s/$INACTIVE_STACK/$ACTIVE_STACK/g" nginx/nginx.conf
        docker service update --force ${ACTIVE_STACK}_nginx-lb-1
        docker stack rm $INACTIVE_STACK
        
        exit 1
    fi
else
    echo "❌ New stack failed health check"
    docker stack rm $INACTIVE_STACK
    exit 1
fi
```

### **Circuit Breaker Pattern**
```javascript
// circuit-breaker.js - Application-level circuit breaker
class CircuitBreaker {
    constructor(service, options = {}) {
        this.service = service;
        this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
        this.failureCount = 0;
        this.successCount = 0;
        this.nextAttempt = Date.now();
        
        // Configuration
        this.failureThreshold = options.failureThreshold || 5;
        this.successThreshold = options.successThreshold || 2;
        this.timeout = options.timeout || 60000; // 1 minute
        this.monitor = options.monitor || false;
    }
    
    async call(...args) {
        if (this.state === 'OPEN') {
            if (this.nextAttempt <= Date.now()) {
                this.state = 'HALF_OPEN';
                this.successCount = 0;
                console.log('🔄 Circuit breaker: HALF_OPEN');
            } else {
                throw new Error('Circuit breaker is OPEN');
            }
        }
        
        try {
            const result = await this.service(...args);
            return this.onSuccess(result);
        } catch (error) {
            return this.onFailure(error);
        }
    }
    
    onSuccess(result) {
        this.failureCount = 0;
        
        if (this.state === 'HALF_OPEN') {
            this.successCount++;
            if (this.successCount >= this.successThreshold) {
                this.state = 'CLOSED';
                console.log('✅ Circuit breaker: CLOSED');
            }
        }
        
        return result;
    }
    
    onFailure(error) {
        this.failureCount++;
        
        if (this.failureCount >= this.failureThreshold) {
            this.state = 'OPEN';
            this.nextAttempt = Date.now() + this.timeout;
            console.log('🚨 Circuit breaker: OPEN');
        }
        
        throw error;
    }
    
    getState() {
        return {
            state: this.state,
            failureCount: this.failureCount,
            successCount: this.successCount,
            nextAttempt: this.nextAttempt
        };
    }
}

// Usage example
const databaseService = async (query) => {
    // Database call that might fail
    const response = await fetch('/api/database', {
        method: 'POST',
        body: JSON.stringify({ query })
    });
    
    if (!response.ok) {
        throw new Error(`Database error: ${response.status}`);
    }
    
    return response.json();
};

const protectedDatabaseService = new CircuitBreaker(databaseService, {
    failureThreshold: 3,
    successThreshold: 2,
    timeout: 30000
});

// Health check endpoint
app.get('/health', (req, res) => {
    const circuitState = protectedDatabaseService.getState();
    
    res.json({
        status: circuitState.state === 'OPEN' ? 'unhealthy' : 'healthy',
        timestamp: new Date().toISOString(),
        services: {
            database: circuitState
        }
    });
});
```

---

## 📊 **Monitoring & Observability**

### **Comprehensive Monitoring Stack**
```yaml
# monitoring-stack.yml
version: '3.8'

services:
  # Prometheus for metrics collection
  prometheus:
    image: prom/prometheus:latest
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/rules:/etc/prometheus/rules
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - monitoring
    deploy:
      placement:
        constraints:
          - node.role == manager

  # Grafana for visualization
  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    ports:
      - "3000:3000"
    networks:
      - monitoring
    depends_on:
      - prometheus

  # Node Exporter for host metrics
  node-exporter:
    image: prom/node-exporter:latest
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    ports:
      - "9100:9100"
    networks:
      - monitoring
    deploy:
      mode: global

  # cAdvisor for container metrics
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - "8080:8080"
    networks:
      - monitoring
    deploy:
      mode: global

  # AlertManager for alert handling
  alertmanager:
    image: prom/alertmanager:latest
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager_data:/alertmanager
    ports:
      - "9093:9093"
    networks:
      - monitoring

  # Elasticsearch for logs
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - monitoring

  # Logstash for log processing
  logstash:
    image: docker.elastic.co/logstash/logstash:7.17.0
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
      - ./logstash/config:/usr/share/logstash/config
    ports:
      - "5044:5044"
      - "5000:5000/tcp"
      - "5000:5000/udp"
      - "9600:9600"
    networks:
      - monitoring
    depends_on:
      - elasticsearch

  # Kibana for log visualization
  kibana:
    image: docker.elastic.co/kibana/kibana:7.17.0
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    ports:
      - "5601:5601"
    networks:
      - monitoring
    depends_on:
      - elasticsearch

  # Jaeger for distributed tracing
  jaeger:
    image: jaegertracing/all-in-one:latest
    environment:
      - COLLECTOR_ZIPKIN_HTTP_PORT=9411
    ports:
      - "5775:5775/udp"
      - "6831:6831/udp"
      - "6832:6832/udp"
      - "5778:5778"
      - "16686:16686"
      - "14268:14268"
      - "14250:14250"
      - "9411:9411"
    networks:
      - monitoring

networks:
  monitoring:
    driver: overlay
    attachable: true

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:
  elasticsearch_data:
```

### **Prometheus Configuration**
```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  # cAdvisor
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  # Application metrics
  - job_name: 'myapp'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/metrics'
    scrape_interval: 10s

  # Docker Daemon metrics
  - job_name: 'docker'
    static_configs:
      - targets: ['172.17.0.1:9323']
```

### **Alerting Rules**
```yaml
# prometheus/rules/docker-alerts.yml
groups:
- name: docker-alerts
  rules:
  - alert: ContainerDown
    expr: absent(up{job="cadvisor"})
    for: 30s
    labels:
      severity: critical
    annotations:
      summary: "Container monitoring is down"
      description: "cAdvisor has been down for more than 30 seconds."

  - alert: HighCPUUsage
    expr: rate(container_cpu_usage_seconds_total[5m]) * 100 > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage detected"
      description: "Container {{ $labels.name }} has CPU usage above 80%"

  - alert: HighMemoryUsage
    expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 85
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage detected"
      description: "Container {{ $labels.name }} has memory usage above 85%"

  - alert: ContainerRestarting
    expr: rate(container_start_time_seconds[5m]) > 0
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: "Container is restarting frequently"
      description: "Container {{ $labels.name }} has restarted {{ $value }} times in the last 5 minutes"

  - alert: DiskSpaceRunningLow
    expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Disk space running low"
      description: "Filesystem {{ $labels.mountpoint }} has less than 10% space remaining"
```

### **Application Metrics Integration**
```javascript
// app-metrics.js - Express.js application with metrics
const express = require('express');
const prometheus = require('prom-client');

const app = express();

// Create metrics
const httpDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequests = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const activeConnections = new prometheus.Gauge({
  name: 'active_connections',
  help: 'Number of active connections'
});

const databaseConnectionPool = new prometheus.Gauge({
  name: 'database_connection_pool_size',
  help: 'Current database connection pool size'
});

// Middleware for metrics collection
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    
    httpDuration
      .labels(req.method, route, res.statusCode)
      .observe(duration);
      
    httpRequests
      .labels(req.method, route, res.statusCode)
      .inc();
  });
  
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', prometheus.register.contentType);
  res.end(await prometheus.register.metrics());
});

// Business logic endpoints
app.get('/api/users', async (req, res) => {
  // Your business logic here
  res.json({ users: [] });
});

// Custom metrics updates
setInterval(() => {
  // Update custom metrics
  activeConnections.set(Math.floor(Math.random() * 100));
  databaseConnectionPool.set(Math.floor(Math.random() * 20) + 5);
}, 5000);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

---

## 🚀 **CI/CD Pipeline Integration**

### **GitLab CI/CD Pipeline**
```yaml
# .gitlab-ci.yml
stages:
  - test
  - security
  - build
  - deploy-staging
  - deploy-production

variables:
  DOCKER_REGISTRY: "registry.gitlab.com"
  DOCKER_IMAGE: "$DOCKER_REGISTRY/$CI_PROJECT_PATH"
  DOCKER_TAG: "$CI_COMMIT_REF_SLUG-$CI_COMMIT_SHORT_SHA"

# Test Stage
test:
  stage: test
  image: node:16-alpine
  services:
    - postgres:13
    - redis:6-alpine
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: test_user
    POSTGRES_PASSWORD: test_password
    POSTGRES_HOST_AUTH_METHOD: trust
  before_script:
    - npm ci
  script:
    - npm run lint
    - npm run test:unit
    - npm run test:integration
  coverage: '/Coverage: \d+\.\d+%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    paths:
      - coverage/
    expire_in: 1 week

# Security Scanning
security-scan:
  stage: security
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    # Build image for scanning
    - docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
    
    # Trivy vulnerability scanning
    - |
      docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        -v $PWD:/tmp \
        aquasec/trivy:latest image \
        --exit-code 1 \
        --severity HIGH,CRITICAL \
        --format template \
        --template "@contrib/gitlab.tpl" \
        --output /tmp/trivy-report.json \
        $DOCKER_IMAGE:$DOCKER_TAG
    
    # Container structure test
    - |
      curl -LO https://github.com/GoogleContainerTools/container-structure-test/releases/download/v1.11.0/container-structure-test-linux-amd64
      chmod +x container-structure-test-linux-amd64
      ./container-structure-test-linux-amd64 test --image $DOCKER_IMAGE:$DOCKER_TAG --config container-structure-test.yaml
  artifacts:
    reports:
      sast: trivy-report.json
    expire_in: 1 week
  allow_failure: false

# Build and Push
build:
  stage: build
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - |
      if [[ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]]; then
        export DOCKER_TAG="latest"
      fi
  script:
    # Build multi-platform image
    - docker buildx create --use
    - |
      docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
        --build-arg VCS_REF=$CI_COMMIT_SHA \
        --build-arg VERSION=$CI_COMMIT_TAG \
        -t $DOCKER_IMAGE:$DOCKER_TAG \
        -t $DOCKER_IMAGE:$CI_COMMIT_SHORT_SHA \
        --push .
  only:
    - main
    - develop
    - tags

# Deploy to Staging
deploy-staging:
  stage: deploy-staging
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  environment:
    name: staging
    url: https://staging.myapp.com
  before_script:
    - apk add --no-cache curl
    - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    - chmod +x kubectl
    - mv kubectl /usr/local/bin/
  script:
    # Deploy to staging environment
    - |
      kubectl set image deployment/myapp-deployment \
        myapp=$DOCKER_IMAGE:$DOCKER_TAG \
        --namespace=staging
    
    # Wait for rollout to complete
    - kubectl rollout status deployment/myapp-deployment --namespace=staging --timeout=300s
    
    # Run smoke tests
    - |
      for i in {1..30}; do
        if curl -f https://staging.myapp.com/health; then
          echo "Staging deployment successful!"
          break
        fi
        echo "Waiting for staging deployment... ($i/30)"
        sleep 10
      done
  only:
    - develop

# Deploy to Production
deploy-production:
  stage: deploy-production
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  environment:
    name: production
    url: https://myapp.com
  before_script:
    - apk add --no-cache curl
    - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    - chmod +x kubectl
    - mv kubectl /usr/local/bin/
  script:
    # Blue-Green deployment
    - |
      # Get current deployment
      CURRENT_COLOR=$(kubectl get deployment -l app=myapp --namespace=production -o jsonpath='{.items[0].metadata.labels.color}')
      if [ "$CURRENT_COLOR" = "blue" ]; then
        NEW_COLOR="green"
      else
        NEW_COLOR="blue"
      fi
      
      echo "Deploying to $NEW_COLOR environment"
      
      # Update deployment with new color
      kubectl patch deployment myapp-$NEW_COLOR \
        -p '{"spec":{"template":{"spec":{"containers":[{"name":"myapp","image":"'$DOCKER_IMAGE:$DOCKER_TAG'"}]}}}}' \
        --namespace=production
      
      # Wait for new deployment
      kubectl rollout status deployment/myapp-$NEW_COLOR --namespace=production --timeout=300s
      
      # Switch traffic
      kubectl patch service myapp-service \
        -p '{"spec":{"selector":{"color":"'$NEW_COLOR'"}}}' \
        --namespace=production
      
      # Verify deployment
      sleep 30
      if curl -f https://myapp.com/health; then
        echo "Production deployment successful!"
        # Scale down old deployment
        kubectl scale deployment myapp-$CURRENT_COLOR --replicas=0 --namespace=production
      else
        echo "Production deployment failed! Rolling back..."
        kubectl patch service myapp-service \
          -p '{"spec":{"selector":{"color":"'$CURRENT_COLOR'"}}}' \
          --namespace=production
        exit 1
      fi
  when: manual
  only:
    - main
    - tags
```

### **GitHub Actions Workflow**
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:6
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '16'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run linting
      run: npm run lint
    
    - name: Run tests
      run: |
        npm run test:unit
        npm run test:integration
      env:
        DATABASE_URL: postgres://postgres:postgres@localhost:5432/test_db
        REDIS_URL: redis://localhost:6379
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/lcov.info

  security:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} .
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  build-and-push:
    needs: [test, security]
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
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
          type=sha
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy-staging:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to staging
      run: |
        echo "Deploying to staging environment..."
        # Add your staging deployment logic here

  deploy-production:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to production
      run: |
        echo "Deploying to production environment..."
        # Add your production deployment logic here
```

---

## ⚡ **Performance Optimization**

### **Container Resource Optimization**
```dockerfile
# Optimized production Dockerfile
FROM node:18-alpine AS base

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app directory and user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    mkdir -p /app && \
    chown -R nodejs:nodejs /app

WORKDIR /app
USER nodejs

# Dependencies stage
FROM base AS dependencies

# Copy package files
COPY --chown=nodejs:nodejs package*.json ./

# Install dependencies with optimizations
RUN npm ci --only=production --silent && \
    npm cache clean --force

# Build stage
FROM base AS build

COPY --chown=nodejs:nodejs package*.json ./
RUN npm ci --silent

COPY --chown=nodejs:nodejs . .
RUN npm run build && \
    npm prune --production

# Production stage
FROM base AS production

# Copy production dependencies
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy built application
COPY --from=build --chown=nodejs:nodejs /app/dist ./dist
COPY --from=build --chown=nodejs:nodejs /app/package*.json ./

# Set NODE_ENV
ENV NODE_ENV=production \
    NODE_OPTIONS="--max-old-space-size=1024" \
    UV_THREADPOOL_SIZE=128

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node healthcheck.js || exit 1

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

### **Docker Compose Performance Optimization**
```yaml
# docker-compose-optimized.yml
version: '3.8'

services:
  app:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
    environment:
      - NODE_ENV=production
      - UV_THREADPOOL_SIZE=128
      - NODE_OPTIONS=--max-old-space-size=1536
    volumes:
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 100M
    networks:
      - app-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
      nproc:
        soft: 65536
        hard: 65536

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - nginx_cache:/var/cache/nginx
    networks:
      - app-network
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "3"

  redis:
    image: redis:6-alpine
    command: >
      redis-server
      --maxmemory 512mb
      --maxmemory-policy allkeys-lru
      --save 60 1000
      --appendonly yes
      --appendfsync everysec
    volumes:
      - redis_data:/data
    networks:
      - app-network
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 768M
        reservations:
          cpus: '0.25'
          memory: 512M

networks:
  app-network:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: "app-bridge"
      com.docker.network.driver.mtu: 1500

volumes:
  redis_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-data/redis
  nginx_cache:
    driver: local
```

### **Performance Monitoring Script**
```bash
#!/bin/bash
# performance-monitor.sh

# Configuration
THRESHOLD_CPU=80
THRESHOLD_MEMORY=85
THRESHOLD_DISK=90
LOG_FILE="/var/log/docker-performance.log"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check container performance
check_container_performance() {
    local container_id=$1
    local container_name=$2
    
    # Get container stats
    stats=$(docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemPerc}}\t{{.BlockIO}}\t{{.NetIO}}" "$container_id")
    
    # Extract CPU and Memory percentages
    cpu_percent=$(echo "$stats" | tail -n 1 | awk '{print $1}' | sed 's/%//')
    mem_percent=$(echo "$stats" | tail -n 1 | awk '{print $2}' | sed 's/%//')
    
    # Check CPU threshold
    if (( $(echo "$cpu_percent > $THRESHOLD_CPU" | bc -l) )); then
        log_message "⚠️  HIGH CPU: Container $container_name ($container_id) - CPU: ${cpu_percent}%"
        
        # Get top processes in container
        docker exec "$container_id" ps aux --sort=-%cpu | head -10 >> "$LOG_FILE"
    fi
    
    # Check Memory threshold
    if (( $(echo "$mem_percent > $THRESHOLD_MEMORY" | bc -l) )); then
        log_message "⚠️  HIGH MEMORY: Container $container_name ($container_id) - Memory: ${mem_percent}%"
        
        # Get memory details
        docker exec "$container_id" free -h >> "$LOG_FILE"
    fi
}

# Function to optimize system performance
optimize_system() {
    log_message "🔧 Running system optimizations..."
    
    # Clean up unused Docker resources
    docker system prune -f
    
    # Remove dangling images
    docker image prune -f
    
    # Remove unused volumes
    docker volume prune -f
    
    # Clean up build cache
    docker builder prune -f
    
    log_message "✅ System optimization completed"
}

# Main monitoring loop
main() {
    log_message "🚀 Starting Docker performance monitoring..."
    
    while true; do
        # Get all running containers
        mapfile -t containers < <(docker ps --format "{{.ID}}\t{{.Names}}")
        
        for container_line in "${containers[@]}"; do
            if [[ -n "$container_line" ]]; then
                container_id=$(echo "$container_line" | cut -f1)
                container_name=$(echo "$container_line" | cut -f2)
                
                check_container_performance "$container_id" "$container_name"
            fi
        done
        
        # Check disk space
        disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
        if [ "$disk_usage" -gt "$THRESHOLD_DISK" ]; then
            log_message "⚠️  HIGH DISK USAGE: ${disk_usage}%"
            optimize_system
        fi
        
        # Wait before next check
        sleep 60
    done
}

# Handle script termination
cleanup() {
    log_message "🛑 Performance monitoring stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start monitoring
main
```

---

## 🔄 **Auto-scaling Patterns**

### **Docker Swarm Auto-scaling**
```bash
#!/bin/bash
# swarm-autoscaler.sh

# Configuration
SERVICE_NAME="myapp_app"
MIN_REPLICAS=2
MAX_REPLICAS=10
CPU_THRESHOLD=70
MEMORY_THRESHOLD=80
SCALE_UP_STEP=2
SCALE_DOWN_STEP=1
CHECK_INTERVAL=30

# Function to get current service stats
get_service_stats() {
    local service_name=$1
    
    # Get service tasks
    tasks=$(docker service ps "$service_name" --format "{{.ID}}" --filter "desired-state=running")
    
    total_cpu=0
    total_memory=0
    task_count=0
    
    for task in $tasks; do
        # Get container ID for the task
        container_id=$(docker inspect "$task" --format "{{.Status.ContainerStatus.ContainerID}}" 2>/dev/null)
        
        if [[ -n "$container_id" ]]; then
            # Get container stats
            stats=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemPerc}}" "$container_id" 2>/dev/null)
            
            if [[ -n "$stats" ]]; then
                cpu=$(echo "$stats" | cut -d',' -f1 | sed 's/%//')
                memory=$(echo "$stats" | cut -d',' -f2 | sed 's/%//')
                
                total_cpu=$(echo "$total_cpu + $cpu" | bc)
                total_memory=$(echo "$total_memory + $memory" | bc)
                ((task_count++))
            fi
        fi
    done
    
    if [[ $task_count -gt 0 ]]; then
        avg_cpu=$(echo "scale=2; $total_cpu / $task_count" | bc)
        avg_memory=$(echo "scale=2; $total_memory / $task_count" | bc)
        
        echo "$avg_cpu,$avg_memory,$task_count"
    else
        echo "0,0,0"
    fi
}

# Function to scale service
scale_service() {
    local service_name=$1
    local new_replicas=$2
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Scaling $service_name to $new_replicas replicas"
    docker service scale "$service_name=$new_replicas"
}

# Function to get current replica count
get_replica_count() {
    local service_name=$1
    docker service inspect "$service_name" --format "{{.Spec.Mode.Replicated.Replicas}}"
}

# Main autoscaling logic
autoscale() {
    local service_name=$1
    
    # Get current stats
    stats=$(get_service_stats "$service_name")
    avg_cpu=$(echo "$stats" | cut -d',' -f1)
    avg_memory=$(echo "$stats" | cut -d',' -f2)
    current_replicas=$(get_replica_count "$service_name")
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Service: $service_name, Replicas: $current_replicas, CPU: ${avg_cpu}%, Memory: ${avg_memory}%"
    
    # Determine if scaling is needed
    should_scale_up=false
    should_scale_down=false
    
    # Check if we need to scale up
    if (( $(echo "$avg_cpu > $CPU_THRESHOLD" | bc -l) )) || (( $(echo "$avg_memory > $MEMORY_THRESHOLD" | bc -l) )); then
        if [[ $current_replicas -lt $MAX_REPLICAS ]]; then
            should_scale_up=true
        fi
    fi
    
    # Check if we can scale down (only if resource usage is low)
    if (( $(echo "$avg_cpu < $(($CPU_THRESHOLD - 20))" | bc -l) )) && (( $(echo "$avg_memory < $(($MEMORY_THRESHOLD - 20))" | bc -l) )); then
        if [[ $current_replicas -gt $MIN_REPLICAS ]]; then
            should_scale_down=true
        fi
    fi
    
    # Perform scaling
    if [[ "$should_scale_up" == true ]]; then
        new_replicas=$((current_replicas + SCALE_UP_STEP))
        if [[ $new_replicas -gt $MAX_REPLICAS ]]; then
            new_replicas=$MAX_REPLICAS
        fi
        scale_service "$service_name" "$new_replicas"
    elif [[ "$should_scale_down" == true ]]; then
        new_replicas=$((current_replicas - SCALE_DOWN_STEP))
        if [[ $new_replicas -lt $MIN_REPLICAS ]]; then
            new_replicas=$MIN_REPLICAS
        fi
        scale_service "$service_name" "$new_replicas"
    fi
}

# Main loop
echo "Starting autoscaler for service: $SERVICE_NAME"
echo "Configuration: Min=$MIN_REPLICAS, Max=$MAX_REPLICAS, CPU Threshold=$CPU_THRESHOLD%, Memory Threshold=$MEMORY_THRESHOLD%"

while true; do
    autoscale "$SERVICE_NAME"
    sleep "$CHECK_INTERVAL"
done
```

---

## 🆘 **Production Troubleshooting**

### **Container Debugging Toolkit**
```bash
#!/bin/bash
# debug-toolkit.sh

# Function to debug container issues
debug_container() {
    local container_name=$1
    
    echo "🔍 Debugging container: $container_name"
    echo "=" | head -c 50; echo
    
    # Basic container information
    echo "📋 Container Information:"
    docker inspect "$container_name" --format "{{json .}}" | jq '{
        Name: .Name,
        State: .State,
        Image: .Config.Image,
        Created: .Created,
        StartedAt: .State.StartedAt,
        RestartCount: .RestartCount,
        ExitCode: .State.ExitCode
    }'
    
    echo -e "\n🔧 Container Configuration:"
    docker inspect "$container_name" --format "{{json .}}" | jq '{
        Env: .Config.Env,
        Cmd: .Config.Cmd,
        WorkingDir: .Config.WorkingDir,
        User: .Config.User,
        Volumes: .Mounts
    }'
    
    # Resource usage
    echo -e "\n📊 Resource Usage:"
    docker stats --no-stream "$container_name"
    
    # Network information
    echo -e "\n🌐 Network Configuration:"
    docker inspect "$container_name" --format "{{json .NetworkSettings}}" | jq '{
        IPAddress: .IPAddress,
        Networks: .Networks,
        Ports: .Ports
    }'
    
    # Recent logs
    echo -e "\n📝 Recent Logs (last 50 lines):"
    docker logs --tail 50 --timestamps "$container_name"
    
    # Process list
    echo -e "\n⚡ Running Processes:"
    docker exec "$container_name" ps aux 2>/dev/null || echo "Cannot access processes (container might be stopped)"
    
    # Disk usage
    echo -e "\n💾 Disk Usage:"
    docker exec "$container_name" df -h 2>/dev/null || echo "Cannot access filesystem (container might be stopped)"
    
    # Open ports
    echo -e "\n🔌 Open Ports:"
    docker exec "$container_name" netstat -tlnp 2>/dev/null || echo "Cannot access network info (container might be stopped)"
}

# Function to debug Docker daemon
debug_daemon() {
    echo "🐳 Docker Daemon Information:"
    echo "=" | head -c 50; echo
    
    # Docker system info
    echo "📋 System Information:"
    docker system info
    
    # Docker version
    echo -e "\n🏷️ Version Information:"
    docker version
    
    # System resource usage
    echo -e "\n📊 System Resources:"
    docker system df
    
    # Running containers
    echo -e "\n🏃 Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
    
    # Docker events (last 100)
    echo -e "\n📋 Recent Events:"
    docker events --since 1h --until now | tail -10
}

# Function for network debugging
debug_network() {
    local network_name=$1
    
    echo "🌐 Network Debugging: $network_name"
    echo "=" | head -c 50; echo
    
    # Network information
    echo "📋 Network Details:"
    docker network inspect "$network_name"
    
    # Containers in network
    echo -e "\n🔗 Connected Containers:"
    docker network inspect "$network_name" --format "{{range .Containers}}{{.Name}} - {{.IPv4Address}}{{end}}"
    
    # Test connectivity between containers
    echo -e "\n🧪 Connectivity Tests:"
    containers=$(docker network inspect "$network_name" --format "{{range .Containers}}{{.Name}} {{end}}")
    for container in $containers; do
        echo "Testing from $container:"
        for target in $containers; do
            if [[ "$container" != "$target" ]]; then
                result=$(docker exec "$container" ping -c 1 "$target" 2>/dev/null && echo "✅ Success" || echo "❌ Failed")
                echo "  $container -> $target: $result"
            fi
        done
    done
}

# Function for performance analysis
analyze_performance() {
    local container_name=$1
    local duration=${2:-60}
    
    echo "⚡ Performance Analysis: $container_name (${duration}s)"
    echo "=" | head -c 50; echo
    
    # CPU and memory monitoring
    echo "📊 Resource Monitoring (${duration}s):"
    timeout "$duration" docker stats "$container_name" --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    # Container top processes
    echo -e "\n🔝 Top Processes:"
    docker exec "$container_name" top 2>/dev/null || echo "Cannot access process list"
    
    # I/O statistics
    echo -e "\n💿 I/O Statistics:"
    docker exec "$container_name" iostat 2>/dev/null || echo "iostat not available"
}

# Function to generate health report
generate_health_report() {
    local output_file="docker-health-report-$(date +%Y%m%d-%H%M%S).txt"
    
    echo "🏥 Generating Docker Health Report..."
    {
        echo "Docker Health Report - $(date)"
        echo "=" | head -c 80; echo
        
        debug_daemon
        echo -e "\n\n"
        
        echo "🏃 Container Analysis:"
        docker ps --format "{{.Names}}" | while read -r container; do
            if [[ -n "$container" ]]; then
                debug_container "$container"
                echo -e "\n" | head -c 80; echo
            fi
        done
        
        echo "🌐 Network Analysis:"
        docker network ls --format "{{.Name}}" | grep -v bridge | grep -v host | grep -v none | while read -r network; do
            if [[ -n "$network" ]]; then
                debug_network "$network"
                echo -e "\n" | head -c 80; echo
            fi
        done
        
    } > "$output_file"
    
    echo "✅ Health report generated: $output_file"
}

# Main script logic
case "${1:-help}" in
    container)
        if [[ -n "$2" ]]; then
            debug_container "$2"
        else
            echo "Usage: $0 container <container_name>"
        fi
        ;;
    daemon)
        debug_daemon
        ;;
    network)
        if [[ -n "$2" ]]; then
            debug_network "$2"
        else
            echo "Usage: $0 network <network_name>"
        fi
        ;;
    performance)
        if [[ -n "$2" ]]; then
            analyze_performance "$2" "$3"
        else
            echo "Usage: $0 performance <container_name> [duration_seconds]"
        fi
        ;;
    report)
        generate_health_report
        ;;
    help|*)
        echo "Docker Debug Toolkit"
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  container <name>     - Debug specific container"
        echo "  daemon              - Debug Docker daemon"
        echo "  network <name>      - Debug Docker network"
        echo "  performance <name>  - Analyze container performance"
        echo "  report              - Generate comprehensive health report"
        echo "  help                - Show this help message"
        ;;
esac
```

---

## ✅ **Key Takeaways**

1. **High Availability**: Implement redundancy at every layer
2. **Monitoring**: Comprehensive observability with metrics, logs, and traces
3. **CI/CD Integration**: Automated testing, security scanning, and deployment
4. **Performance**: Optimize containers and infrastructure for production workloads
5. **Auto-scaling**: Dynamic resource allocation based on demand
6. **Troubleshooting**: Systematic approach to debugging production issues
7. **Documentation**: Maintain runbooks and incident response procedures

---

## 🎓 **Next Steps**

Ready for **[10-real-world-projects](../10-real-world-projects/)**? You'll build:
- Complete microservices architecture
- E-commerce platform with Docker
- CI/CD pipeline implementation
- Monitoring and logging setup
- Real production scenarios

---

## 📚 **Additional Resources**

- [Docker Production Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Prometheus Monitoring](https://prometheus.io/docs/)
- [Grafana Dashboards](https://grafana.com/docs/)
- [ELK Stack Documentation](https://www.elastic.co/guide/)
- [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)
- [GitHub Actions](https://docs.github.com/en/actions)
