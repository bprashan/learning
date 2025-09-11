# 10 - Real-World Projects: Complete Docker Applications

## 🎯 **Learning Objectives**
Build production-ready applications with Docker:
- Full-stack microservices architecture
- E-commerce platform deployment
- CI/CD pipeline implementation
- Monitoring and observability setup
- Database clustering and persistence
- API gateway and service mesh

---

## 📋 **Table of Contents**
1. [Project 1: Microservices E-commerce Platform](#project-1-microservices-e-commerce-platform)
2. [Project 2: Blog Platform with CMS](#project-2-blog-platform-with-cms)
3. [Project 3: Real-time Chat Application](#project-3-real-time-chat-application)
4. [Project 4: DevOps Monitoring Stack](#project-4-devops-monitoring-stack)
5. [Project 5: Data Analytics Pipeline](#project-5-data-analytics-pipeline)
6. [Project 6: Multi-tenant SaaS Application](#project-6-multi-tenant-saas-application)

---

## 🛒 **Project 1: Microservices E-commerce Platform**

### **Architecture Overview**
```
┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend  │    │   API Gateway   │    │  Load Balancer  │
│  (React)    │◄──►│    (Kong)       │◄──►│     (Nginx)     │
└─────────────┘    └─────────────────┘    └─────────────────┘
                            │
       ┌────────────────────┼────────────────────┐
       │                    │                    │
   ┌───▼───┐         ┌──────▼──────┐      ┌──────▼──────┐
   │ User  │         │  Product    │      │  Order      │
   │Service│         │  Service    │      │  Service    │
   └───┬───┘         └──────┬──────┘      └──────┬──────┘
       │                    │                    │
   ┌───▼───┐         ┌──────▼──────┐      ┌──────▼──────┐
   │ User  │         │  Product    │      │  Order      │
   │  DB   │         │     DB      │      │     DB      │
   └───────┘         └─────────────┘      └─────────────┘
```

### **Project Structure**
```
ecommerce-platform/
├── services/
│   ├── user-service/
│   ├── product-service/
│   ├── order-service/
│   ├── notification-service/
│   └── payment-service/
├── frontend/
├── api-gateway/
├── infrastructure/
│   ├── docker/
│   ├── k8s/
│   └── monitoring/
├── scripts/
└── docker-compose.yml
```

### **Docker Compose Configuration**
```yaml
# docker-compose.yml
version: '3.8'

services:
  # API Gateway
  kong:
    image: kong:3.0-alpine
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-db
      KONG_PG_USER: kong
      KONG_PG_PASSWORD: kongpass
      KONG_PROXY_ACCESS_LOG: /dev/stdout
      KONG_ADMIN_ACCESS_LOG: /dev/stdout
      KONG_PROXY_ERROR_LOG: /dev/stderr
      KONG_ADMIN_ERROR_LOG: /dev/stderr
      KONG_ADMIN_LISTEN: 0.0.0.0:8001
    ports:
      - "8000:8000"
      - "8001:8001"
    networks:
      - ecommerce-network
    depends_on:
      - kong-db

  kong-db:
    image: postgres:13
    environment:
      POSTGRES_DB: kong
      POSTGRES_USER: kong
      POSTGRES_PASSWORD: kongpass
    volumes:
      - kong_data:/var/lib/postgresql/data
    networks:
      - ecommerce-network

  # User Service
  user-service:
    build: ./services/user-service
    environment:
      - NODE_ENV=production
      - DB_HOST=user-db
      - DB_NAME=users
      - DB_USER=userapp
      - DB_PASSWORD=userpass
      - JWT_SECRET=your-jwt-secret
      - REDIS_URL=redis://redis:6379
    networks:
      - ecommerce-network
    depends_on:
      - user-db
      - redis
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  user-db:
    image: postgres:13
    environment:
      POSTGRES_DB: users
      POSTGRES_USER: userapp
      POSTGRES_PASSWORD: userpass
    volumes:
      - user_db_data:/var/lib/postgresql/data
      - ./services/user-service/db/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - ecommerce-network

  # Product Service
  product-service:
    build: ./services/product-service
    environment:
      - NODE_ENV=production
      - DB_HOST=product-db
      - DB_NAME=products
      - DB_USER=productapp
      - DB_PASSWORD=productpass
      - ELASTICSEARCH_URL=http://elasticsearch:9200
    networks:
      - ecommerce-network
    depends_on:
      - product-db
      - elasticsearch
    deploy:
      replicas: 2

  product-db:
    image: postgres:13
    environment:
      POSTGRES_DB: products
      POSTGRES_USER: productapp
      POSTGRES_PASSWORD: productpass
    volumes:
      - product_db_data:/var/lib/postgresql/data
      - ./services/product-service/db/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - ecommerce-network

  # Order Service
  order-service:
    build: ./services/order-service
    environment:
      - NODE_ENV=production
      - DB_HOST=order-db
      - DB_NAME=orders
      - DB_USER=orderapp
      - DB_PASSWORD=orderpass
      - RABBITMQ_URL=amqp://rabbitmq:5672
      - USER_SERVICE_URL=http://user-service:3000
      - PRODUCT_SERVICE_URL=http://product-service:3000
    networks:
      - ecommerce-network
    depends_on:
      - order-db
      - rabbitmq
    deploy:
      replicas: 2

  order-db:
    image: postgres:13
    environment:
      POSTGRES_DB: orders
      POSTGRES_USER: orderapp
      POSTGRES_PASSWORD: orderpass
    volumes:
      - order_db_data:/var/lib/postgresql/data
      - ./services/order-service/db/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - ecommerce-network

  # Payment Service
  payment-service:
    build: ./services/payment-service
    environment:
      - NODE_ENV=production
      - DB_HOST=payment-db
      - DB_NAME=payments
      - DB_USER=paymentapp
      - DB_PASSWORD=paymentpass
      - STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
      - RABBITMQ_URL=amqp://rabbitmq:5672
    networks:
      - ecommerce-network
    depends_on:
      - payment-db
      - rabbitmq

  payment-db:
    image: postgres:13
    environment:
      POSTGRES_DB: payments
      POSTGRES_USER: paymentapp
      POSTGRES_PASSWORD: paymentpass
    volumes:
      - payment_db_data:/var/lib/postgresql/data
    networks:
      - ecommerce-network

  # Notification Service
  notification-service:
    build: ./services/notification-service
    environment:
      - NODE_ENV=production
      - RABBITMQ_URL=amqp://rabbitmq:5672
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_USER=${SMTP_USER}
      - SMTP_PASS=${SMTP_PASS}
    networks:
      - ecommerce-network
    depends_on:
      - rabbitmq

  # Frontend
  frontend:
    build: ./frontend
    ports:
      - "3000:80"
    environment:
      - REACT_APP_API_URL=http://localhost:8000
    networks:
      - ecommerce-network
    depends_on:
      - kong

  # Infrastructure Services
  redis:
    image: redis:6-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - ecommerce-network

  rabbitmq:
    image: rabbitmq:3-management-alpine
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: adminpass
    ports:
      - "15672:15672"
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - ecommerce-network

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - ecommerce-network

  # Monitoring
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./infrastructure/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - ecommerce-network

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./infrastructure/monitoring/grafana:/etc/grafana/provisioning
    networks:
      - ecommerce-network

networks:
  ecommerce-network:
    driver: bridge

volumes:
  kong_data:
  user_db_data:
  product_db_data:
  order_db_data:
  payment_db_data:
  redis_data:
  rabbitmq_data:
  elasticsearch_data:
  prometheus_data:
  grafana_data:
```

### **User Service Implementation**
```javascript
// services/user-service/src/server.js
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const redis = require('redis');
const promClient = require('prom-client');

const app = express();
app.use(express.json());

// Metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

const totalUsers = new promClient.Gauge({
  name: 'total_users',
  help: 'Total number of users'
});

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST,
  port: 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

// Redis connection
const redisClient = redis.createClient({
  url: process.env.REDIS_URL
});

redisClient.on('error', (err) => console.error('Redis error:', err));
redisClient.connect();

// Middleware for metrics
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
  });
  next();
});

// Authentication middleware
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    // Check if token is blacklisted
    const isBlacklisted = await redisClient.get(`blacklist:${token}`);
    if (isBlacklisted) {
      return res.status(401).json({ error: 'Token has been revoked' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(403).json({ error: 'Invalid token' });
  }
};

// Routes
app.post('/api/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName } = req.body;

    // Check if user exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const newUser = await pool.query(
      'INSERT INTO users (email, password, first_name, last_name, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING id, email, first_name, last_name',
      [email, hashedPassword, firstName, lastName]
    );

    // Update metrics
    const userCount = await pool.query('SELECT COUNT(*) FROM users');
    totalUsers.set(parseInt(userCount.rows[0].count));

    res.status(201).json({
      message: 'User created successfully',
      user: newUser.rows[0]
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await pool.query(
      'SELECT id, email, password, first_name, last_name FROM users WHERE email = $1',
      [email]
    );

    if (user.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check password
    const validPassword = await bcrypt.compare(password, user.rows[0].password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate JWT
    const token = jwt.sign(
      { 
        userId: user.rows[0].id, 
        email: user.rows[0].email 
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Cache user session
    await redisClient.setEx(
      `session:${user.rows[0].id}`,
      86400, // 24 hours
      JSON.stringify({
        userId: user.rows[0].id,
        email: user.rows[0].email,
        loginTime: new Date().toISOString()
      })
    );

    res.json({
      token,
      user: {
        id: user.rows[0].id,
        email: user.rows[0].email,
        firstName: user.rows[0].first_name,
        lastName: user.rows[0].last_name
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/logout', authenticateToken, async (req, res) => {
  try {
    const token = req.headers['authorization'].split(' ')[1];
    
    // Add token to blacklist
    const decoded = jwt.decode(token);
    const expiresIn = decoded.exp - Math.floor(Date.now() / 1000);
    
    if (expiresIn > 0) {
      await redisClient.setEx(`blacklist:${token}`, expiresIn, 'true');
    }

    // Remove session
    await redisClient.del(`session:${req.user.userId}`);

    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/profile', authenticateToken, async (req, res) => {
  try {
    const user = await pool.query(
      'SELECT id, email, first_name, last_name, created_at FROM users WHERE id = $1',
      [req.user.userId]
    );

    if (user.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: user.rows[0] });
  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Health check
app.get('/health', async (req, res) => {
  try {
    // Check database connection
    await pool.query('SELECT 1');
    
    // Check Redis connection
    await redisClient.ping();

    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  // Update user count metric
  try {
    const userCount = await pool.query('SELECT COUNT(*) FROM users');
    totalUsers.set(parseInt(userCount.rows[0].count));
  } catch (error) {
    console.error('Error updating metrics:', error);
  }

  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`User service running on port ${PORT}`);
});
```

### **User Service Dockerfile**
```dockerfile
# services/user-service/Dockerfile
FROM node:18-alpine AS base

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app directory and user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Dependencies stage
FROM base AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Development dependencies for building
FROM base AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# If you have a build step, add it here
# RUN npm run build

# Production stage
FROM base AS production
WORKDIR /app

# Copy production dependencies
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application code
COPY --chown=nodejs:nodejs . .

# Switch to non-root user
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => { process.exit(r.statusCode !== 200) }).on('error', () => process.exit(1))"

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/server.js"]
```

### **Database Migration Script**
```sql
-- services/user-service/db/init.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE
    ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### **Kong API Gateway Configuration**
```bash
#!/bin/bash
# scripts/setup-kong.sh

# Wait for Kong to be ready
echo "Waiting for Kong to be ready..."
until curl -f http://localhost:8001 >/dev/null 2>&1; do
    echo "Kong is not ready yet..."
    sleep 5
done

echo "Kong is ready! Configuring services and routes..."

# Add User Service
curl -i -X POST http://localhost:8001/services/ \
  --data "name=user-service" \
  --data "url=http://user-service:3000"

curl -i -X POST http://localhost:8001/services/user-service/routes \
  --data "hosts[]=localhost" \
  --data "paths[]=/api/users" \
  --data "strip_path=false"

# Add Product Service
curl -i -X POST http://localhost:8001/services/ \
  --data "name=product-service" \
  --data "url=http://product-service:3000"

curl -i -X POST http://localhost:8001/services/product-service/routes \
  --data "hosts[]=localhost" \
  --data "paths[]=/api/products" \
  --data "strip_path=false"

# Add Order Service
curl -i -X POST http://localhost:8001/services/ \
  --data "name=order-service" \
  --data "url=http://order-service:3000"

curl -i -X POST http://localhost:8001/services/order-service/routes \
  --data "hosts[]=localhost" \
  --data "paths[]=/api/orders" \
  --data "strip_path=false"

# Add Rate Limiting Plugin
curl -i -X POST http://localhost:8001/plugins/ \
  --data "name=rate-limiting" \
  --data "config.minute=100" \
  --data "config.hour=1000"

# Add JWT Plugin for protected routes
curl -i -X POST http://localhost:8001/plugins/ \
  --data "name=jwt" \
  --data "service.name=order-service"

# Add CORS Plugin
curl -i -X POST http://localhost:8001/plugins/ \
  --data "name=cors" \
  --data "config.origins=http://localhost:3000" \
  --data "config.methods=GET,POST,PUT,DELETE,OPTIONS" \
  --data "config.headers=Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,Authorization"

echo "Kong configuration completed!"
```

### **Frontend React Application**
```javascript
// frontend/src/App.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

function App() {
  const [user, setUser] = useState(null);
  const [products, setProducts] = useState([]);
  const [cart, setCart] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      fetchProfile();
    } else {
      setLoading(false);
    }
    fetchProducts();
  }, []);

  const fetchProfile = async () => {
    try {
      const response = await api.get('/api/users/profile');
      setUser(response.data.user);
    } catch (error) {
      console.error('Failed to fetch profile:', error);
      localStorage.removeItem('token');
    } finally {
      setLoading(false);
    }
  };

  const fetchProducts = async () => {
    try {
      const response = await api.get('/api/products');
      setProducts(response.data.products);
    } catch (error) {
      console.error('Failed to fetch products:', error);
    }
  };

  const login = async (email, password) => {
    try {
      const response = await api.post('/api/users/login', { email, password });
      localStorage.setItem('token', response.data.token);
      setUser(response.data.user);
      return { success: true };
    } catch (error) {
      return { 
        success: false, 
        error: error.response?.data?.error || 'Login failed' 
      };
    }
  };

  const logout = async () => {
    try {
      await api.post('/api/users/logout');
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      localStorage.removeItem('token');
      setUser(null);
    }
  };

  const addToCart = (product) => {
    setCart(prevCart => {
      const existingItem = prevCart.find(item => item.id === product.id);
      if (existingItem) {
        return prevCart.map(item =>
          item.id === product.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prevCart, { ...product, quantity: 1 }];
    });
  };

  const checkout = async () => {
    if (!user) {
      alert('Please log in to checkout');
      return;
    }

    try {
      const orderItems = cart.map(item => ({
        productId: item.id,
        quantity: item.quantity,
        price: item.price
      }));

      const response = await api.post('/api/orders', {
        items: orderItems,
        total: cart.reduce((sum, item) => sum + (item.price * item.quantity), 0)
      });

      alert('Order placed successfully!');
      setCart([]);
    } catch (error) {
      alert('Failed to place order: ' + (error.response?.data?.error || 'Unknown error'));
    }
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="App">
      <header className="header">
        <h1>Docker E-commerce</h1>
        <div className="auth-section">
          {user ? (
            <div>
              <span>Welcome, {user.firstName}!</span>
              <button onClick={logout}>Logout</button>
            </div>
          ) : (
            <LoginForm onLogin={login} />
          )}
        </div>
        <div className="cart-section">
          Cart ({cart.length}) 
          {cart.length > 0 && (
            <button onClick={checkout}>Checkout</button>
          )}
        </div>
      </header>

      <main>
        <div className="products-grid">
          {products.map(product => (
            <ProductCard 
              key={product.id} 
              product={product} 
              onAddToCart={addToCart}
            />
          ))}
        </div>
      </main>
    </div>
  );
}

const LoginForm = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    const result = await onLogin(email, password);
    
    if (!result.success) {
      alert(result.error);
    }
    
    setLoading(false);
  };

  return (
    <form onSubmit={handleSubmit} className="login-form">
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <input
        type="password"
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />
      <button type="submit" disabled={loading}>
        {loading ? 'Logging in...' : 'Login'}
      </button>
    </form>
  );
};

const ProductCard = ({ product, onAddToCart }) => {
  return (
    <div className="product-card">
      <img src={product.imageUrl} alt={product.name} />
      <h3>{product.name}</h3>
      <p>{product.description}</p>
      <div className="price">${product.price}</div>
      <button onClick={() => onAddToCart(product)}>
        Add to Cart
      </button>
    </div>
  );
};

export default App;
```

### **Deployment Scripts**
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

echo "🚀 Starting E-commerce Platform Deployment..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Build and start services
echo "📦 Building and starting services..."
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Setup Kong API Gateway
echo "🔧 Configuring API Gateway..."
./scripts/setup-kong.sh

# Run database migrations
echo "🗄️ Running database migrations..."
docker-compose exec user-service npm run migrate || true
docker-compose exec product-service npm run migrate || true
docker-compose exec order-service npm run migrate || true

# Seed initial data
echo "🌱 Seeding initial data..."
docker-compose exec product-service npm run seed || true

# Health checks
echo "🏥 Running health checks..."
./scripts/health-check.sh

echo "✅ Deployment completed successfully!"
echo "🌐 Frontend: http://localhost:3000"
echo "🔗 API Gateway: http://localhost:8000"
echo "📊 Monitoring: http://localhost:3001"
echo "🐰 RabbitMQ: http://localhost:15672"
```

### **Health Check Script**
```bash
#!/bin/bash
# scripts/health-check.sh

echo "Running health checks..."

services=(
    "http://localhost:8001|Kong API Gateway"
    "http://localhost:3000|Frontend"
    "http://localhost:8000/api/users/health|User Service"
    "http://localhost:8000/api/products/health|Product Service" 
    "http://localhost:8000/api/orders/health|Order Service"
    "http://localhost:9090|Prometheus"
    "http://localhost:3001|Grafana"
)

for service in "${services[@]}"; do
    url=$(echo $service | cut -d'|' -f1)
    name=$(echo $service | cut -d'|' -f2)
    
    if curl -f -s "$url" > /dev/null; then
        echo "✅ $name is healthy"
    else
        echo "❌ $name is not responding"
    fi
done

# Check database connections
echo ""
echo "Checking database connections..."

if docker-compose exec -T user-db pg_isready -U userapp -d users; then
    echo "✅ User database is ready"
else
    echo "❌ User database is not ready"
fi

if docker-compose exec -T product-db pg_isready -U productapp -d products; then
    echo "✅ Product database is ready"
else
    echo "❌ Product database is not ready"
fi

if docker-compose exec -T order-db pg_isready -U orderapp -d orders; then
    echo "✅ Order database is ready"
else
    echo "❌ Order database is not ready"
fi

# Check Redis
if docker-compose exec -T redis redis-cli ping | grep -q PONG; then
    echo "✅ Redis is ready"
else
    echo "❌ Redis is not ready"
fi

# Check RabbitMQ
if curl -f -s http://localhost:15672 > /dev/null; then
    echo "✅ RabbitMQ is ready"
else
    echo "❌ RabbitMQ is not ready"
fi
```

This comprehensive e-commerce platform demonstrates:

1. **Microservices Architecture**: Independent services with their own databases
2. **API Gateway**: Kong for routing, rate limiting, and authentication
3. **Message Queue**: RabbitMQ for asynchronous communication
4. **Caching**: Redis for session management and caching
5. **Search**: Elasticsearch for product search
6. **Monitoring**: Prometheus and Grafana for metrics
7. **Frontend**: React application consuming the APIs
8. **Security**: JWT authentication, input validation, and secure communication
9. **DevOps**: Automated deployment and health checking scripts

The project includes:
- ✅ User authentication and authorization
- ✅ Product catalog with search
- ✅ Shopping cart and order processing
- ✅ Payment integration (Stripe)
- ✅ Real-time notifications
- ✅ Comprehensive monitoring
- ✅ Automated deployment
- ✅ Health checks and error handling

---

## 📝 **Project 2: Blog Platform with CMS**

### **Architecture Overview**
```
┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Admin     │    │   Content API   │    │   Blog Frontend │
│   Panel     │◄──►│   (GraphQL)     │◄──►│   (Next.js)     │
└─────────────┘    └─────────────────┘    └─────────────────┘
                            │                       │
                    ┌───────▼────────┐      ┌───────▼────────┐
                    │   PostgreSQL   │      │     Redis      │
                    │   Database     │      │     Cache      │
                    └────────────────┘      └────────────────┘
```

### **Docker Compose Configuration**
```yaml
# blog-platform/docker-compose.yml
version: '3.8'

services:
  # Content API (GraphQL)
  content-api:
    build: ./api
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://bloguser:blogpass@postgres:5432/blog
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
      - UPLOAD_DIR=/app/uploads
    volumes:
      - uploads:/app/uploads
    networks:
      - blog-network
    depends_on:
      - postgres
      - redis
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '1.0'
          memory: 1G

  # Blog Frontend
  frontend:
    build: ./frontend
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:4000/graphql
      - NEXT_PUBLIC_UPLOAD_URL=http://localhost:4000/uploads
    ports:
      - "3000:3000"
    networks:
      - blog-network
    depends_on:
      - content-api

  # Admin Panel
  admin:
    build: ./admin
    environment:
      - REACT_APP_API_URL=http://localhost:4000/graphql
    ports:
      - "3001:80"
    networks:
      - blog-network
    depends_on:
      - content-api

  # Database
  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: blog
      POSTGRES_USER: bloguser
      POSTGRES_PASSWORD: blogpass
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./api/db/schema.sql:/docker-entrypoint-initdb.d/schema.sql
    networks:
      - blog-network

  # Cache
  redis:
    image: redis:6-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - blog-network

  # Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "4000:4000"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - uploads:/var/www/uploads:ro
    networks:
      - blog-network
    depends_on:
      - content-api
      - frontend
      - admin

networks:
  blog-network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
  uploads:
```

---

## 💬 **Project 3: Real-time Chat Application**

### **WebSocket Architecture**
```yaml
# chat-app/docker-compose.yml
version: '3.8'

services:
  # Chat API with Socket.IO
  chat-api:
    build: ./api
    environment:
      - NODE_ENV=production
      - MONGODB_URI=mongodb://mongo:27017/chatapp
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    networks:
      - chat-network
    depends_on:
      - mongo
      - redis
    deploy:
      replicas: 3

  # Chat Frontend
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:8000
      - REACT_APP_WS_URL=ws://localhost:8000
    networks:
      - chat-network

  # MongoDB for message storage
  mongo:
    image: mongo:5
    volumes:
      - mongo_data:/data/db
    networks:
      - chat-network

  # Redis for session and pub/sub
  redis:
    image: redis:6-alpine
    networks:
      - chat-network

  # Load Balancer with sticky sessions
  nginx:
    image: nginx:alpine
    ports:
      - "8000:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - chat-network
    depends_on:
      - chat-api

networks:
  chat-network:
    driver: bridge

volumes:
  mongo_data:
```

---

## 📊 **Project 4: DevOps Monitoring Stack**

### **Complete Observability Platform**
```yaml
# monitoring-stack/docker-compose.yml
version: '3.8'

services:
  # Prometheus for metrics
  prometheus:
    image: prom/prometheus:latest
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - monitoring

  # Grafana for visualization
  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel
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

  # AlertManager for alerts
  alertmanager:
    image: prom/alertmanager:latest
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    volumes:
      - ./alertmanager:/etc/alertmanager
      - alertmanager_data:/alertmanager
    ports:
      - "9093:9093"
    networks:
      - monitoring

  # ELK Stack for logs
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms2g -Xmx2g"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - monitoring

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

  logstash:
    image: docker.elastic.co/logstash/logstash:7.17.0
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
      - ./logstash/config:/usr/share/logstash/config
    ports:
      - "5044:5044"
      - "5000:5000"
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
      - "16686:16686"
      - "14268:14268"
    networks:
      - monitoring

  # Node exporter for host metrics
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

  # cAdvisor for container metrics
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    ports:
      - "8080:8080"
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:
  elasticsearch_data:
```

---

## 🔢 **Project 5: Data Analytics Pipeline**

### **Stream Processing Architecture**
```yaml
# analytics-pipeline/docker-compose.yml
version: '3.8'

services:
  # Apache Kafka for streaming
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    networks:
      - analytics

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    networks:
      - analytics

  # Apache Spark for processing
  spark-master:
    image: bitnami/spark:latest
    environment:
      - SPARK_MODE=master
      - SPARK_RPC_AUTHENTICATION_ENABLED=no
      - SPARK_RPC_ENCRYPTION_ENABLED=no
      - SPARK_LOCAL_STORAGE_ENCRYPTION_ENABLED=no
      - SPARK_SSL_ENABLED=no
    ports:
      - "8080:8080"
      - "7077:7077"
    networks:
      - analytics

  spark-worker:
    image: bitnami/spark:latest
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://spark-master:7077
      - SPARK_WORKER_MEMORY=2G
      - SPARK_WORKER_CORES=2
    depends_on:
      - spark-master
    networks:
      - analytics
    deploy:
      replicas: 2

  # ClickHouse for analytics database
  clickhouse:
    image: yandex/clickhouse-server:latest
    ports:
      - "8123:8123"
      - "9000:9000"
    volumes:
      - clickhouse_data:/var/lib/clickhouse
    networks:
      - analytics

  # Apache Superset for visualization
  superset:
    build: ./superset
    ports:
      - "8088:8088"
    environment:
      - SUPERSET_SECRET_KEY=your-secret-key
    networks:
      - analytics
    depends_on:
      - clickhouse

networks:
  analytics:
    driver: bridge

volumes:
  clickhouse_data:
```

---

## 🏢 **Project 6: Multi-tenant SaaS Application**

### **Tenant Isolation Architecture**
```yaml
# saas-platform/docker-compose.yml
version: '3.8'

services:
  # API Gateway with tenant routing
  api-gateway:
    build: ./gateway
    ports:
      - "8080:8080"
    environment:
      - TENANT_DB_HOST=tenant-db
      - SERVICE_REGISTRY_URL=http://consul:8500
    networks:
      - saas-network
    depends_on:
      - consul
      - tenant-db

  # Tenant management service
  tenant-service:
    build: ./services/tenant
    environment:
      - DATABASE_URL=postgresql://tenantuser:tenantpass@tenant-db:5432/tenants
      - REDIS_URL=redis://redis:6379
    networks:
      - saas-network
    depends_on:
      - tenant-db
      - redis

  # Core application service
  app-service:
    build: ./services/app
    environment:
      - TENANT_SERVICE_URL=http://tenant-service:3000
      - DATABASE_TEMPLATE=postgresql://appuser:apppass@app-db:5432/tenant_
    networks:
      - saas-network
    depends_on:
      - app-db
      - tenant-service
    deploy:
      replicas: 3

  # Service discovery
  consul:
    image: consul:latest
    ports:
      - "8500:8500"
    networks:
      - saas-network

  # Databases
  tenant-db:
    image: postgres:13
    environment:
      POSTGRES_DB: tenants
      POSTGRES_USER: tenantuser
      POSTGRES_PASSWORD: tenantpass
    volumes:
      - tenant_db_data:/var/lib/postgresql/data
    networks:
      - saas-network

  app-db:
    image: postgres:13
    environment:
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: apppass
    volumes:
      - app_db_data:/var/lib/postgresql/data
      - ./scripts/create-tenant-dbs.sh:/docker-entrypoint-initdb.d/create-tenant-dbs.sh
    networks:
      - saas-network

  # Shared services
  redis:
    image: redis:6-alpine
    networks:
      - saas-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    networks:
      - saas-network
    depends_on:
      - api-gateway

networks:
  saas-network:
    driver: bridge

volumes:
  tenant_db_data:
  app_db_data:
```

---

## 🚀 **Deployment and CI/CD Examples**

### **Production Deployment Script**
```bash
#!/bin/bash
# scripts/production-deploy.sh

set -e

PROJECT_NAME=${1:-"docker-projects"}
ENVIRONMENT=${2:-"production"}

echo "🚀 Deploying $PROJECT_NAME to $ENVIRONMENT..."

# Load environment-specific configuration
if [ -f ".env.$ENVIRONMENT" ]; then
    source ".env.$ENVIRONMENT"
else
    echo "❌ Environment file .env.$ENVIRONMENT not found"
    exit 1
fi

# Pre-deployment checks
echo "🔍 Running pre-deployment checks..."
./scripts/health-check.sh pre-deploy

# Backup current deployment
echo "💾 Creating backup..."
./scripts/backup.sh

# Deploy with blue-green strategy
echo "🔄 Starting blue-green deployment..."

# Deploy to green environment
docker-compose -f docker-compose.yml -f docker-compose.$ENVIRONMENT.yml up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 60

# Run health checks
echo "🏥 Running health checks..."
if ./scripts/health-check.sh; then
    echo "✅ Health checks passed"
    
    # Switch traffic to new deployment
    echo "🔀 Switching traffic..."
    ./scripts/switch-traffic.sh
    
    # Clean up old containers
    echo "🧹 Cleaning up..."
    docker system prune -f
    
    echo "🎉 Deployment completed successfully!"
else
    echo "❌ Health checks failed, rolling back..."
    ./scripts/rollback.sh
    exit 1
fi
```

### **Kubernetes Deployment Examples**
```yaml
# k8s/microservices-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: myregistry/user-service:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: user-service-secrets
              key: database-url
        - name: REDIS_URL
          value: "redis://redis-service:6379"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: ClusterIP
```

---

## 📊 **Performance Benchmarking**

### **Load Testing with Artillery**
```javascript
// load-tests/ecommerce-load-test.yml
config:
  target: 'http://localhost:8000'
  phases:
    - duration: 60
      arrivalRate: 5
      name: "Warm up"
    - duration: 120
      arrivalRate: 10
      name: "Ramp up load"
    - duration: 300
      arrivalRate: 20
      name: "Sustained load"
  payload:
    path: "./users.csv"
    fields:
      - "email"
      - "password"

scenarios:
  - name: "User Registration and Shopping"
    weight: 70
    flow:
      - post:
          url: "/api/users/register"
          json:
            email: "{{ email }}"
            password: "{{ password }}"
            firstName: "Test"
            lastName: "User"
      - post:
          url: "/api/users/login"
          json:
            email: "{{ email }}"
            password: "{{ password }}"
          capture:
            - json: "$.token"
              as: "authToken"
      - get:
          url: "/api/products"
          headers:
            Authorization: "Bearer {{ authToken }}"
      - post:
          url: "/api/orders"
          headers:
            Authorization: "Bearer {{ authToken }}"
          json:
            items:
              - productId: "{{ $randomString() }}"
                quantity: "{{ $randomInt(1, 5) }}"
                price: "{{ $randomInt(10, 100) }}"

  - name: "Product Browsing"
    weight: 30
    flow:
      - get:
          url: "/api/products"
      - get:
          url: "/api/products/{{ $randomString() }}"
```

---

## ✅ **Key Takeaways from Real-World Projects**

### **Architecture Patterns**
1. **Microservices**: Independent, scalable services
2. **API Gateway**: Single entry point for client requests
3. **Event-Driven**: Asynchronous communication with message queues
4. **CQRS**: Separate read/write operations for better performance
5. **Circuit Breaker**: Fault tolerance and resilience

### **DevOps Best Practices**
1. **Infrastructure as Code**: Docker Compose and Kubernetes manifests
2. **CI/CD Pipelines**: Automated testing, building, and deployment
3. **Monitoring**: Comprehensive observability with metrics, logs, and traces
4. **Security**: Authentication, authorization, and secret management
5. **Scalability**: Auto-scaling and load balancing

### **Production Considerations**
1. **High Availability**: Multi-zone deployments and redundancy
2. **Disaster Recovery**: Backup and restore procedures
3. **Performance**: Optimization and caching strategies
4. **Cost Optimization**: Resource allocation and efficiency
5. **Compliance**: Security standards and audit trails

---

## 🎓 **Next Steps**

Ready for **[11-docker-internals](../11-docker-internals/)**? You'll learn:
- Docker architecture deep dive
- Container runtime internals
- Networking implementation
- Storage drivers and performance
- Advanced troubleshooting techniques

---

## 📚 **Additional Resources**

- [Docker Samples Repository](https://github.com/docker/awesome-compose)
- [Microservices Patterns](https://microservices.io/patterns/)
- [Kubernetes Examples](https://github.com/kubernetes/examples)
- [Production Best Practices](https://12factor.net/)
- [Docker Security](https://docs.docker.com/engine/security/)
