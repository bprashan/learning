# Phase 2: Intermediate Services (Weeks 4-6)

## Week 4: Compute & Storage Services

### Amazon EC2 (Elastic Compute Cloud)

#### Key Topics
1. **Instance Types & Families**
   - General Purpose (T3, M5, M6i)
   - Compute Optimized (C5, C6i)
   - Memory Optimized (R5, R6i, X1e)
   - Storage Optimized (I3, D3)
   - Accelerated Computing (P4, G4)

2. **Pricing Models**
   - On-Demand
   - Reserved Instances (Standard, Convertible)
   - Spot Instances
   - Savings Plans
   - Dedicated Hosts/Instances

3. **Instance Lifecycle**
   - Launch, Stop, Terminate, Hibernate
   - Instance Store vs EBS-backed
   - User Data and Metadata
   - Placement Groups

#### Important Notes

##### Instance Type Selection
```
Naming Convention: m5.large
- m: Instance family
- 5: Generation
- large: Size

Memory to vCPU Ratios:
- General Purpose: 1:4 (1 vCPU : 4 GiB RAM)
- Memory Optimized: 1:8 or higher
- Compute Optimized: 1:2
```

##### Placement Groups
- **Cluster**: High network performance (same AZ)
- **Partition**: Distributed across partitions (different racks)
- **Spread**: Distributed across distinct hardware

### Amazon S3 (Simple Storage Service)

#### Key Topics
1. **Storage Classes**
   - Standard
   - Intelligent-Tiering
   - Standard-IA (Infrequent Access)
   - One Zone-IA
   - Glacier Instant Retrieval
   - Glacier Flexible Retrieval
   - Glacier Deep Archive

2. **S3 Features**
   - Versioning
   - Cross-Region Replication (CRR)
   - Same-Region Replication (SRR)
   - Transfer Acceleration
   - Multipart Upload

3. **Security & Access Control**
   - Bucket Policies
   - Access Control Lists (ACLs)
   - Pre-signed URLs
   - S3 Block Public Access

#### Important Notes

##### Storage Class Transition Rules
```
Data Lifecycle Example:
Day 0-30: S3 Standard
Day 30-90: S3 Standard-IA
Day 90-365: S3 Glacier Flexible Retrieval
Day 365+: S3 Glacier Deep Archive
```

##### S3 Consistency Model
- **Read-after-write**: Immediately consistent for new objects
- **Eventually consistent**: Updates to existing objects (legacy)
- **Strong consistency**: All operations (current)

### Amazon EBS (Elastic Block Store)

#### Volume Types
1. **gp3**: General Purpose SSD (latest generation)
2. **gp2**: General Purpose SSD (previous generation)
3. **io2**: Provisioned IOPS SSD (high performance)
4. **io1**: Provisioned IOPS SSD (previous generation)
5. **st1**: Throughput Optimized HDD
6. **sc1**: Cold HDD

#### EBS Features
- Snapshots and Point-in-time recovery
- Encryption at rest and in transit
- Multi-Attach (io1/io2 only)
- Elastic Volumes (resize on the fly)

### Assignment 2.1: Compute & Storage Architecture
**Scenario**: Design compute and storage for a video processing platform

**Requirements**:
1. Video upload service (handles 10GB+ files)
2. Processing queue (CPU intensive transcoding)
3. Content delivery (global distribution)
4. Archive storage (7-year retention)
5. Cost optimization for varying workloads

**Deliverables**:
- EC2 instance strategy (types, pricing models)
- S3 storage design with lifecycle policies
- EBS configuration for processing nodes
- Cost optimization recommendations

---

## Week 5: Database Services

### Amazon RDS (Relational Database Service)

#### Database Engines
1. **MySQL** - Open source, web applications
2. **PostgreSQL** - Advanced open source, JSON support
3. **MariaDB** - MySQL fork with enhanced features
4. **Oracle** - Enterprise applications
5. **SQL Server** - Microsoft applications
6. **Aurora** - Cloud-native (MySQL/PostgreSQL compatible)

#### RDS Features
- **Multi-AZ**: Synchronous replication for HA
- **Read Replicas**: Asynchronous replication for scaling
- **Automated Backups**: Point-in-time recovery
- **Encryption**: At rest and in transit
- **Performance Insights**: Database performance monitoring

#### Important Notes

##### Multi-AZ vs Read Replicas
| Feature | Multi-AZ | Read Replicas |
|---------|----------|---------------|
| Purpose | High Availability | Read Scaling |
| Replication | Synchronous | Asynchronous |
| Endpoint | Single | Multiple |
| Failover | Automatic | Manual promotion |
| Cross-Region | No | Yes |

### Amazon Aurora

#### Key Features
- **Aurora MySQL**: 5x faster than MySQL
- **Aurora PostgreSQL**: 3x faster than PostgreSQL
- **Aurora Serverless**: Auto-scaling capacity
- **Global Database**: Cross-region replication
- **Backtrack**: Rewind database without restores

#### Aurora Architecture
- **Storage**: Automatically scales from 10GB to 128TB
- **Compute**: Up to 15 read replicas
- **Availability**: 6 copies across 3 AZs
- **Recovery**: Self-healing storage

### Amazon DynamoDB

#### Key Concepts
1. **Tables, Items, Attributes**
2. **Primary Keys**: Partition key + Sort key
3. **Secondary Indexes**: GSI and LSI
4. **Capacity Modes**: Provisioned vs On-Demand
5. **Consistency Models**: Eventually vs Strongly consistent

#### DynamoDB Features
- **Global Tables**: Multi-region replication
- **DynamoDB Streams**: Change data capture
- **Point-in-Time Recovery**: 35-day backup window
- **Encryption**: Server-side encryption
- **DAX**: Microsecond latency caching

#### Important Notes

##### Partition Key Design
```
Good: CustomerID#ProductID (high cardinality)
Bad: Status (low cardinality)

Best Practices:
- High cardinality for even distribution
- Avoid hot partitions
- Use composite keys when needed
```

### Assignment 2.2: Database Architecture Design
**Scenario**: Multi-tier application with complex data requirements

**Requirements**:
1. User authentication and profiles (relational)
2. Product catalog with search (document store)
3. Real-time analytics (time-series data)
4. Session management (key-value store)
5. Cross-region disaster recovery
6. 99.99% availability requirement

**Deliverables**:
- Database technology selection matrix
- RDS Multi-AZ configuration
- DynamoDB table design
- Backup and recovery strategy
- Performance optimization plan

---

## Week 6: Load Balancing, Auto Scaling & Monitoring

### Elastic Load Balancing (ELB)

#### Load Balancer Types
1. **Application Load Balancer (ALB)**
   - Layer 7 (HTTP/HTTPS)
   - Content-based routing
   - WebSocket support
   - Target groups

2. **Network Load Balancer (NLB)**
   - Layer 4 (TCP/UDP)
   - Ultra-high performance
   - Static IP addresses
   - Preserve source IP

3. **Gateway Load Balancer (GWLB)**
   - Layer 3 (IP)
   - Third-party appliances
   - Transparent proxy

#### Load Balancer Features
- **Health Checks**: Monitor target health
- **SSL Termination**: Offload SSL processing
- **Cross-Zone Load Balancing**: Even distribution across AZs
- **Connection Draining**: Graceful instance removal

### Auto Scaling

#### Auto Scaling Components
1. **Launch Template/Configuration**: Instance specifications
2. **Auto Scaling Group**: Scaling policies and constraints
3. **Scaling Policies**: When and how to scale
4. **CloudWatch Metrics**: Scaling triggers

#### Scaling Policies
- **Target Tracking**: Maintain specific metric value
- **Step Scaling**: Incremental scaling based on alarm
- **Simple Scaling**: Basic scaling policy
- **Scheduled Scaling**: Predictable load patterns

#### Important Notes

##### Auto Scaling Best Practices
```
Metrics for Scaling:
- CPU Utilization (most common)
- Memory Utilization (custom metric)
- Request Count per Target
- Custom Application Metrics

Scaling Strategies:
- Scale out early, scale in conservatively
- Use multiple metrics for complex applications
- Test scaling policies under load
```

### Amazon CloudWatch

#### CloudWatch Components
1. **Metrics**: Performance data from AWS services
2. **Alarms**: Notifications based on metric thresholds
3. **Logs**: Centralized log management
4. **Events**: React to AWS service changes
5. **Dashboards**: Visualization and monitoring

#### Key Metrics by Service
- **EC2**: CPU, Memory, Disk, Network
- **RDS**: DB Connections, CPU, Freeable Memory
- **S3**: Number of Objects, Bucket Size
- **ALB**: Request Count, Target Response Time

### Assignment 2.3: Scalable Architecture Implementation
**Scenario**: Design auto-scaling architecture for seasonal e-commerce platform

**Requirements**:
1. Traffic varies 10x between peak and off-peak
2. Black Friday traffic spike (100x normal)
3. Multiple application tiers (web, app, cache)
4. Global user base with regional presence
5. 2-second response time SLA
6. Cost optimization during low-traffic periods

**Deliverables**:
- Auto Scaling group configuration
- Load balancer setup (ALB + NLB)
- CloudWatch monitoring strategy
- Scaling policies and thresholds
- Cost optimization plan

### Phase 2 Summary Assessment
**Comprehensive Assignment**: Design a complete scalable application infrastructure

**Scenario**: Video streaming platform with the following requirements:
- 10 million global users
- Video upload, processing, and streaming
- Real-time chat and comments
- User analytics and recommendations
- 99.9% availability during peak hours
- Variable traffic patterns
- Multi-region presence

**Deliverables**:
1. Compute architecture with auto-scaling
2. Storage strategy for multiple data types
3. Database design for different use cases
4. Load balancing and traffic distribution
5. Monitoring and alerting framework
6. Performance optimization recommendations
7. Cost management strategy
