# 06 - Docker Compose: Orchestrating Multi-Container Applications

## 🎯 **Learning Objectives**
Master Docker Compose for production-grade multi-container applications:
- Service definition and orchestration
- Advanced Compose patterns and best practices
- Environment management and configuration
- Production deployment strategies
- Scaling and load balancing
- Debugging and troubleshooting

---

## 📋 **Table of Contents**
1. [Compose Architecture Overview](#compose-architecture-overview)
2. [Service Definition Mastery](#service-definition-mastery)
3. [Advanced Networking](#advanced-networking)
4. [Volume and Data Management](#volume-and-data-management)
5. [Environment Management](#environment-management)
6. [Production Patterns](#production-patterns)
7. [Scaling and Performance](#scaling-and-performance)
8. [Debugging and Troubleshooting](#debugging-and-troubleshooting)

---

## 🏗️ **Compose Architecture Overview**

### **Docker Compose Stack**
```
┌─────────────────────────────────────────────────┐
│                Docker Compose                   │
│              (Orchestration Layer)              │
├─────────────────────────────────────────────────┤
│                 Services                        │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │   Web   │ │   API   │ │Database │           │
│  └─────────┘ └─────────┘ └─────────┘           │
├─────────────────────────────────────────────────┤
│              Networks & Volumes                 │
│   ┌──────────┐    ┌────────────────┐           │
│   │ Networks │    │    Volumes     │           │
│   └──────────┘    └────────────────┘           │
├─────────────────────────────────────────────────┤
│               Docker Engine                     │
└─────────────────────────────────────────────────┘
```

### **Compose File Versions**
```yaml
# Version 3.x (Recommended for production)
version: '3.8'

# Version 2.x (Legacy, still supported)
version: '2.4'

# No version (Legacy format)
```

### **Key Compose Concepts**
- **Services**: Containers that make up your application
- **Networks**: Communication channels between services
- **Volumes**: Persistent data storage
- **Configs**: Non-sensitive configuration data
- **Secrets**: Sensitive configuration data (Swarm mode)

---

## 🔧 **Service Definition Mastery**

### **Basic Service Structure**
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    container_name: web-server
    ports:
      - "80:80"
    restart: unless-stopped
    
  app:
    build: .
    container_name: app-server
    depends_on:
      - database
    environment:
      - NODE_ENV=production
    
  database:
    image: postgres:13
    container_name: postgres-db
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: admin
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    secrets:
      - db_password

volumes:
  postgres_data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### **Advanced Build Configuration**
```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
      args:
        - NODE_ENV=production
        - API_URL=https://api.example.com
        - BUILD_VERSION=${BUILD_VERSION}
      target: production
      cache_from:
        - node:18-alpine
        - frontend:build-cache
    image: frontend:${VERSION:-latest}
    
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        - ENVIRONMENT=${ENVIRONMENT}
      labels:
        - "com.example.version=${VERSION}"
        - "com.example.build-date=${BUILD_DATE}"
    image: backend:${VERSION:-latest}
```

### **Health Checks and Dependencies**
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    depends_on:
      api:
        condition: service_healthy
    
  api:
    build: ./api
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    depends_on:
      database:
        condition: service_healthy
      redis:
        condition: service_started
        
  database:
    image: postgres:13
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: secret
      
  redis:
    image: redis:alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### **Resource Limits and Constraints**
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      update_config:
        parallelism: 2
        delay: 10s
        failure_action: rollback
        
  database:
    image: postgres:13
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
      placement:
        constraints:
          - node.role == manager
          - node.labels.storage == ssd
```

---

## 🌐 **Advanced Networking**

### **Custom Networks Configuration**
```yaml
version: '3.8'

services:
  frontend:
    image: nginx:alpine
    networks:
      - public
      - internal
    ports:
      - "80:80"
      - "443:443"
      
  api:
    build: ./api
    networks:
      - internal
      - database
    expose:
      - "3000"
      
  database:
    image: postgres:13
    networks:
      - database
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: secret

networks:
  public:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: public-bridge
  
  internal:
    driver: bridge
    internal: true
    
  database:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
```

### **External Networks**
```yaml
version: '3.8'

services:
  app:
    image: my-app:latest
    networks:
      - existing-network
      - new-network

networks:
  existing-network:
    external: true
    name: production-network
    
  new-network:
    driver: bridge
```

### **Network Aliases and Service Discovery**
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    networks:
      app-network:
        aliases:
          - frontend
          - www
          - web-server
          
  api:
    build: ./api
    networks:
      app-network:
        aliases:
          - backend
          - api-server
    environment:
      DATABASE_URL: postgresql://user:pass@db:5432/myapp
      REDIS_URL: redis://cache:6379
      
  database:
    image: postgres:13
    networks:
      app-network:
        aliases:
          - db
          - postgres
          
  redis:
    image: redis:alpine
    networks:
      app-network:
        aliases:
          - cache

networks:
  app-network:
    driver: bridge
```

---

## 💾 **Volume and Data Management**

### **Volume Types and Configuration**
```yaml
version: '3.8'

services:
  database:
    image: postgres:13
    volumes:
      # Named volume (managed by Docker)
      - postgres_data:/var/lib/postgresql/data
      
      # Bind mount (host directory)
      - ./postgres-config:/etc/postgresql/conf.d:ro
      
      # tmpfs mount (memory-based)
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 1G
          
      # Volume with specific options
      - type: volume
        source: postgres_logs
        target: /var/log/postgresql
        volume:
          nocopy: true
          
  backup:
    image: postgres:13
    volumes:
      # Shared volume for backups
      - postgres_data:/var/lib/postgresql/data:ro
      - backup_storage:/backups
    command: |
      bash -c "
        while true; do
          sleep 3600
          pg_dump -h database -U postgres myapp > /backups/backup-$$(date +%Y%m%d-%H%M%S).sql
        done
      "
    depends_on:
      - database

volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: ext4
      device: /dev/sdb1
      
  postgres_logs:
    driver: local
    
  backup_storage:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nfs.example.com,rw
      device: ":/exports/backups"
```

### **External Volumes**
```yaml
version: '3.8'

services:
  app:
    image: my-app:latest
    volumes:
      - existing-data:/app/data
      - new-logs:/app/logs

volumes:
  existing-data:
    external: true
    name: production-data
    
  new-logs:
    driver: local
```

### **Volume Backup Strategies**
```yaml
version: '3.8'

services:
  database:
    image: postgres:13
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: secret
      
  backup:
    image: postgres:13
    volumes:
      - postgres_data:/source:ro
      - backup_archive:/backups
    environment:
      PGPASSWORD: secret
    command: |
      bash -c "
        # Wait for database to be ready
        until pg_isready -h database -U postgres; do
          echo 'Waiting for database...'
          sleep 5
        done
        
        # Continuous backup loop
        while true; do
          timestamp=$$(date +%Y%m%d-%H%M%S)
          echo 'Creating backup: backup-$$timestamp'
          
          # SQL dump
          pg_dump -h database -U postgres myapp > /backups/sql-dump-$$timestamp.sql
          
          # File-level backup
          tar czf /backups/files-backup-$$timestamp.tar.gz -C /source .
          
          # Cleanup old backups (keep last 7 days)
          find /backups -name '*.sql' -mtime +7 -delete
          find /backups -name '*.tar.gz' -mtime +7 -delete
          
          sleep 86400  # Daily backup
        done
      "
    depends_on:
      - database

volumes:
  postgres_data:
  backup_archive:
```

---

## 🔐 **Environment Management**

### **Environment Variable Strategies**
```yaml
version: '3.8'

services:
  app:
    build: ./app
    environment:
      # Direct assignment
      NODE_ENV: production
      PORT: 3000
      
      # From host environment
      DATABASE_URL: ${DATABASE_URL}
      
      # With default values
      LOG_LEVEL: ${LOG_LEVEL:-info}
      
      # Array format
      - FEATURE_FLAGS=feature1,feature2,feature3
      
    # Environment file
    env_file:
      - .env
      - .env.production
      - ./config/${ENVIRONMENT}.env
```

### **Multi-Environment Configuration**
```yaml
# docker-compose.yml (base configuration)
version: '3.8'

services:
  app:
    build: ./app
    ports:
      - "${PORT:-3000}:3000"
    environment:
      NODE_ENV: ${NODE_ENV:-development}
    volumes:
      - ./app:/usr/src/app
    depends_on:
      - database

  database:
    image: postgres:13
    environment:
      POSTGRES_DB: ${DB_NAME:-myapp}
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-secret}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

```yaml
# docker-compose.override.yml (development overrides)
version: '3.8'

services:
  app:
    volumes:
      - ./app:/usr/src/app
      - /usr/src/app/node_modules
    environment:
      DEBUG: "app:*"
      HOT_RELOAD: true
    command: npm run dev
    
  database:
    ports:
      - "5432:5432"
```

```yaml
# docker-compose.prod.yml (production overrides)
version: '3.8'

services:
  app:
    restart: unless-stopped
    volumes: []  # Remove development volumes
    environment:
      NODE_ENV: production
    command: npm start
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
          
  database:
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres-config:/etc/postgresql/conf.d:ro
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

### **Secrets Management**
```yaml
version: '3.8'

services:
  app:
    image: my-app:latest
    secrets:
      - db_password
      - api_key
      - ssl_cert
      - ssl_key
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
      API_KEY_FILE: /run/secrets/api_key
      SSL_CERT_FILE: /run/secrets/ssl_cert
      SSL_KEY_FILE: /run/secrets/ssl_key
      
  database:
    image: postgres:13
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
    
  api_key:
    external: true
    name: production_api_key
    
  ssl_cert:
    file: ./ssl/cert.pem
    
  ssl_key:
    file: ./ssl/key.pem
```

### **Configuration Files**
```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    configs:
      - source: nginx_config
        target: /etc/nginx/nginx.conf
        mode: 0644
      - source: site_config
        target: /etc/nginx/conf.d/default.conf
        
  app:
    build: ./app
    configs:
      - source: app_config
        target: /app/config/production.yml
        uid: '1000'
        gid: '1000'
        mode: 0600

configs:
  nginx_config:
    file: ./config/nginx.conf
    
  site_config:
    external: true
    name: production_site_config
    
  app_config:
    file: ./config/app-production.yml
```

---

## 🏭 **Production Patterns**

### **Complete LAMP Stack**
```yaml
version: '3.8'

services:
  # Load Balancer / Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/sites:/etc/nginx/conf.d:ro
      - ./ssl:/etc/nginx/ssl:ro
      - web_content:/var/www/html:ro
    depends_on:
      - php-fpm
    networks:
      - frontend
    restart: unless-stopped
    
  # PHP Application Server
  php-fpm:
    build: ./php
    volumes:
      - web_content:/var/www/html
      - ./php/php.ini:/usr/local/etc/php/php.ini:ro
    environment:
      DB_HOST: mysql
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD_FILE: /run/secrets/db_password
      REDIS_HOST: redis
    secrets:
      - db_password
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - frontend
      - backend
    restart: unless-stopped
    
  # Database
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - mysql_root_password
      - db_password
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/my.cnf:/etc/mysql/conf.d/custom.cnf:ro
    networks:
      - backend
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 5
    restart: unless-stopped
    
  # Cache
  redis:
    image: redis:alpine
    volumes:
      - redis_data:/data
      - ./redis/redis.conf:/etc/redis/redis.conf:ro
    command: redis-server /etc/redis/redis.conf
    networks:
      - backend
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
    
  # Background Jobs
  worker:
    build: ./php
    volumes:
      - web_content:/var/www/html
    environment:
      DB_HOST: mysql
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD_FILE: /run/secrets/db_password
      REDIS_HOST: redis
    secrets:
      - db_password
    command: php artisan queue:work --sleep=3 --tries=3
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - backend
    restart: unless-stopped

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  web_content:
  mysql_data:
  redis_data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
  mysql_root_password:
    file: ./secrets/mysql_root_password.txt
```

### **Microservices Architecture**
```yaml
version: '3.8'

services:
  # API Gateway
  api-gateway:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./gateway/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - user-service
      - order-service
      - product-service
    networks:
      - public
      - internal
    restart: unless-stopped
    
  # User Service
  user-service:
    build: ./services/user
    environment:
      SERVICE_NAME: user-service
      DATABASE_URL: postgresql://user:${USER_DB_PASSWORD}@user-db:5432/users
      REDIS_URL: redis://shared-cache:6379/0
    secrets:
      - user_db_password
    depends_on:
      user-db:
        condition: service_healthy
      shared-cache:
        condition: service_started
    networks:
      - internal
      - user-db-network
      - shared-cache-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
    
  # Order Service
  order-service:
    build: ./services/order
    environment:
      SERVICE_NAME: order-service
      DATABASE_URL: postgresql://order:${ORDER_DB_PASSWORD}@order-db:5432/orders
      USER_SERVICE_URL: http://user-service:3000
      PRODUCT_SERVICE_URL: http://product-service:3000
      RABBITMQ_URL: amqp://guest:guest@message-queue:5672
    secrets:
      - order_db_password
    depends_on:
      order-db:
        condition: service_healthy
      message-queue:
        condition: service_started
    networks:
      - internal
      - order-db-network
      - message-queue-network
    restart: unless-stopped
    
  # Product Service
  product-service:
    build: ./services/product
    environment:
      SERVICE_NAME: product-service
      DATABASE_URL: postgresql://product:${PRODUCT_DB_PASSWORD}@product-db:5432/products
      ELASTICSEARCH_URL: http://search-engine:9200
    secrets:
      - product_db_password
    depends_on:
      product-db:
        condition: service_healthy
      search-engine:
        condition: service_started
    networks:
      - internal
      - product-db-network
      - search-network
    restart: unless-stopped
    
  # Databases
  user-db:
    image: postgres:13
    environment:
      POSTGRES_DB: users
      POSTGRES_USER: user
      POSTGRES_PASSWORD_FILE: /run/secrets/user_db_password
    secrets:
      - user_db_password
    volumes:
      - user_db_data:/var/lib/postgresql/data
    networks:
      - user-db-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d users"]
      interval: 30s
      timeout: 10s
      retries: 5
    restart: unless-stopped
    
  order-db:
    image: postgres:13
    environment:
      POSTGRES_DB: orders
      POSTGRES_USER: order
      POSTGRES_PASSWORD_FILE: /run/secrets/order_db_password
    secrets:
      - order_db_password
    volumes:
      - order_db_data:/var/lib/postgresql/data
    networks:
      - order-db-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U order -d orders"]
      interval: 30s
      timeout: 10s
      retries: 5
    restart: unless-stopped
    
  product-db:
    image: postgres:13
    environment:
      POSTGRES_DB: products
      POSTGRES_USER: product
      POSTGRES_PASSWORD_FILE: /run/secrets/product_db_password
    secrets:
      - product_db_password
    volumes:
      - product_db_data:/var/lib/postgresql/data
    networks:
      - product-db-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U product -d products"]
      interval: 30s
      timeout: 10s
      retries: 5
    restart: unless-stopped
    
  # Infrastructure Services
  shared-cache:
    image: redis:alpine
    volumes:
      - cache_data:/data
    networks:
      - shared-cache-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
    
  message-queue:
    image: rabbitmq:3-management
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD}
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - message-queue-network
    ports:
      - "15672:15672"  # Management UI
    restart: unless-stopped
    
  search-engine:
    image: elasticsearch:7.17.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - search-network
    restart: unless-stopped

networks:
  public:
    driver: bridge
  internal:
    driver: bridge
    internal: true
  user-db-network:
    driver: bridge
    internal: true
  order-db-network:
    driver: bridge
    internal: true
  product-db-network:
    driver: bridge
    internal: true
  shared-cache-network:
    driver: bridge
    internal: true
  message-queue-network:
    driver: bridge
    internal: true
  search-network:
    driver: bridge
    internal: true

volumes:
  user_db_data:
  order_db_data:
  product_db_data:
  cache_data:
  rabbitmq_data:
  elasticsearch_data:

secrets:
  user_db_password:
    file: ./secrets/user_db_password.txt
  order_db_password:
    file: ./secrets/order_db_password.txt
  product_db_password:
    file: ./secrets/product_db_password.txt
```

---

## 📈 **Scaling and Performance**

### **Horizontal Scaling**
```yaml
version: '3.8'

services:
  # Load Balancer
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - app
    networks:
      - frontend
      
  # Scalable Application
  app:
    build: ./app
    environment:
      DATABASE_URL: postgresql://user:pass@database:5432/myapp
      REDIS_URL: redis://redis:6379
    depends_on:
      database:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - frontend
      - backend
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
      restart_policy:
        condition: on-failure
        max_attempts: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        
  # Shared Database
  database:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 30s
      timeout: 10s
      retries: 5
      
  # Shared Cache
  redis:
    image: redis:alpine
    volumes:
      - redis_data:/data
    networks:
      - backend

networks:
  frontend:
    driver: overlay
    attachable: true
  backend:
    driver: overlay
    internal: true

volumes:
  postgres_data:
  redis_data:
```

### **Auto-scaling with Docker Swarm**
```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml myapp

# Scale services
docker service scale myapp_app=5

# Update service with zero downtime
docker service update --image myapp:v2 myapp_app

# Monitor services
docker service ls
docker service ps myapp_app
```

### **Performance Monitoring Stack**
```yaml
version: '3.8'

services:
  # Application (example)
  app:
    image: my-app:latest
    ports:
      - "3000:3000"
    networks:
      - monitoring
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=3000"
      - "prometheus.path=/metrics"
      
  # Prometheus
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
    networks:
      - monitoring
      
  # Grafana
  grafana:
    image: grafana/grafana
    ports:
      - "3001:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards:ro
      - ./grafana/datasources:/etc/grafana/provisioning/datasources:ro
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    networks:
      - monitoring
      
  # Node Exporter
  node-exporter:
    image: prom/node-exporter
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points'
      - '^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)($$|/)'
    networks:
      - monitoring
      
  # cAdvisor
  cadvisor:
    image: gcr.io/cadvisor/cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus_data:
  grafana_data:
```

---

## 🔍 **Debugging and Troubleshooting**

### **Compose Debugging Commands**
```bash
# View service logs
docker-compose logs service_name
docker-compose logs -f --tail=100 service_name

# View all logs
docker-compose logs -f

# Check service status
docker-compose ps
docker-compose top

# Validate compose file
docker-compose config
docker-compose config --services

# Check networks and volumes
docker-compose ps --services
docker network ls
docker volume ls

# Execute commands in services
docker-compose exec service_name bash
docker-compose run --rm service_name command

# Restart services
docker-compose restart service_name
docker-compose down && docker-compose up -d
```

### **Health Check Integration**
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    depends_on:
      api:
        condition: service_healthy
        
  api:
    build: ./api
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    environment:
      HEALTH_CHECK_ENDPOINT: /health
      HEALTH_CHECK_TIMEOUT: 5000
```

### **Common Issues and Solutions**

#### **Issue 1: Services Can't Communicate**
```bash
# Check network connectivity
docker-compose exec service1 ping service2
docker-compose exec service1 nslookup service2

# Verify network configuration
docker network inspect $(docker-compose ps -q | head -1 | xargs docker inspect --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}')

# Solution: Ensure services are on same network
```

#### **Issue 2: Volume Mount Problems**
```bash
# Check volume mounts
docker-compose ps
docker inspect $(docker-compose ps -q service_name)

# Verify volume exists and permissions
docker volume ls
docker volume inspect volume_name

# Solution examples in compose file:
```
```yaml
services:
  app:
    volumes:
      - ./app:/usr/src/app:delegated  # For performance on macOS
      - app_data:/app/data
      - type: bind
        source: ./config
        target: /app/config
        read_only: true
```

#### **Issue 3: Environment Variables**
```bash
# Check environment variables
docker-compose config

# Debug specific service environment
docker-compose exec service_name env

# Show resolved values
docker-compose config --resolve-deps
```

### **Development vs Production**
```bash
# Development
docker-compose up

# Production with specific override
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Testing environment
docker-compose -f docker-compose.yml -f docker-compose.test.yml run --rm tests
```

---

## 🧪 **Advanced Compose Patterns**

### **Blue-Green Deployment**
```yaml
# docker-compose.blue-green.yml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx-bg.conf:/etc/nginx/nginx.conf:ro
    environment:
      ACTIVE_ENV: ${ACTIVE_ENV:-blue}
    networks:
      - public
      - blue
      - green
      
  # Blue Environment
  app-blue:
    image: myapp:${BLUE_VERSION:-latest}
    networks:
      - blue
      - database
    environment:
      VERSION: ${BLUE_VERSION:-latest}
      COLOR: blue
      
  # Green Environment  
  app-green:
    image: myapp:${GREEN_VERSION:-latest}
    networks:
      - green
      - database
    environment:
      VERSION: ${GREEN_VERSION:-latest}
      COLOR: green
      
  database:
    image: postgres:13
    networks:
      - database
    volumes:
      - postgres_data:/var/lib/postgresql/data

networks:
  public:
  blue:
  green:
  database:

volumes:
  postgres_data:
```

### **Feature Flagging**
```yaml
version: '3.8'

services:
  app:
    image: myapp:latest
    environment:
      FEATURE_NEW_UI: ${FEATURE_NEW_UI:-false}
      FEATURE_ADVANCED_SEARCH: ${FEATURE_ADVANCED_SEARCH:-false}
      FEATURE_BETA_API: ${FEATURE_BETA_API:-false}
    volumes:
      - ./feature-config.json:/app/config/features.json:ro
```

### **Canary Deployment Preparation**
```yaml
version: '3.8'

services:
  # Load balancer with traffic splitting
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx-canary.conf:/etc/nginx/nginx.conf:ro
    environment:
      CANARY_WEIGHT: ${CANARY_WEIGHT:-10}  # 10% traffic to canary
      
  # Stable version (90% traffic)
  app-stable:
    image: myapp:${STABLE_VERSION}
    deploy:
      replicas: 9
    environment:
      VERSION: ${STABLE_VERSION}
      
  # Canary version (10% traffic)
  app-canary:
    image: myapp:${CANARY_VERSION}
    deploy:
      replicas: 1
    environment:
      VERSION: ${CANARY_VERSION}
```

---

## ✅ **Key Takeaways**

1. **Service Orchestration**: Master multi-container application design
2. **Network Architecture**: Implement proper service isolation and communication
3. **Volume Management**: Design robust data persistence strategies
4. **Environment Management**: Handle multiple deployment environments effectively
5. **Production Readiness**: Apply health checks, restart policies, and resource limits
6. **Scaling Strategies**: Plan for horizontal scaling and performance optimization
7. **Debugging Skills**: Troubleshoot complex multi-service applications

---

## 🎓 **Next Steps**

Ready for **[07-multi-stage-builds](../07-multi-stage-builds/)**? You'll learn:
- Advanced build optimization techniques
- Security-focused build patterns
- CI/CD integration strategies
- Performance optimization patterns
- Production-ready build pipelines

---

## 📚 **Additional Resources**

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Swarm with Compose](https://docs.docker.com/engine/swarm/stack-deploy/)
- [Production Best Practices](https://docs.docker.com/compose/production/)
- [Compose CLI Reference](https://docs.docker.com/compose/reference/)
