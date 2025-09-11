# Phase 3: Advanced Services (Weeks 7-9)

## Week 7: Container Services & Orchestration

### Amazon ECS (Elastic Container Service)

#### ECS Core Concepts
1. **Cluster**: Logical grouping of compute resources
2. **Task Definition**: Blueprint for running containers
3. **Service**: Maintains desired count of tasks
4. **Task**: Running instance of task definition

#### ECS Launch Types
1. **EC2 Launch Type**
   - You manage EC2 instances
   - More control over infrastructure
   - Cost optimization with Reserved Instances
   - Custom AMIs and instance types

2. **Fargate Launch Type**
   - Serverless container platform
   - AWS manages infrastructure
   - Pay for vCPU and memory used
   - No EC2 instances to manage

#### Important Notes

##### Task Definition Structure
```json
{
  "family": "web-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "web-container",
      "image": "nginx:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ]
    }
  ]
}
```

##### ECS vs EKS vs Fargate
| Feature | ECS | EKS | Fargate |
|---------|-----|-----|---------|
| Orchestration | AWS Native | Kubernetes | Serverless |
| Learning Curve | Low | High | Low |
| Flexibility | Medium | High | Low |
| Management | AWS Managed | Self/AWS Managed | Fully Managed |

### Amazon EKS (Elastic Kubernetes Service)

#### EKS Architecture
1. **Control Plane**: Managed by AWS
2. **Data Plane**: Worker nodes (EC2 or Fargate)
3. **Add-ons**: CNI, CoreDNS, kube-proxy
4. **RBAC**: Role-based access control

#### EKS Features
- **Managed Control Plane**: HA across multiple AZs
- **Fargate Integration**: Serverless pods
- **AWS Integration**: ALB, EBS, EFS, Secrets Manager
- **Cluster Autoscaler**: Automatic node scaling
- **Pod Security**: Pod security standards

#### Kubernetes on AWS Best Practices
- Use namespaces for multi-tenancy
- Implement resource quotas and limits
- Use Horizontal Pod Autoscaler (HPA)
- Configure cluster autoscaler
- Implement proper RBAC policies

### Container Security & Best Practices

#### Security Considerations
1. **Image Security**
   - Scan images for vulnerabilities
   - Use minimal base images
   - Sign container images
   - Regular image updates

2. **Runtime Security**
   - Run containers as non-root
   - Use read-only file systems
   - Implement network policies
   - Monitor container behavior

3. **Secrets Management**
   - Use AWS Secrets Manager
   - Avoid secrets in environment variables
   - Rotate secrets regularly
   - Use IAM roles for service accounts

### Assignment 3.1: Container Architecture Design
**Scenario**: Migrate monolithic application to microservices on containers

**Requirements**:
1. 5 microservices (user, product, order, payment, notification)
2. Different scaling requirements per service
3. CI/CD pipeline integration
4. Service mesh for inter-service communication
5. Centralized logging and monitoring
6. Blue-green deployment capability

**Deliverables**:
- Container orchestration platform selection (ECS vs EKS)
- Service architecture design
- Networking and service discovery strategy
- Security implementation plan
- CI/CD pipeline design
- Monitoring and logging framework

---

## Week 8: Serverless Computing

### AWS Lambda

#### Lambda Fundamentals
1. **Function**: Code that runs in response to events
2. **Runtime**: Execution environment (Node.js, Python, Java, etc.)
3. **Handler**: Entry point for function execution
4. **Context**: Runtime information and methods
5. **Layers**: Shared code and dependencies

#### Lambda Features
- **Event Sources**: 200+ AWS services integration
- **Concurrency**: Up to 1000 concurrent executions (default)
- **Dead Letter Queues**: Error handling
- **Versions & Aliases**: Function versioning
- **Environment Variables**: Configuration management

#### Important Notes

##### Lambda Limits and Quotas
```
Execution Limits:
- Timeout: 15 minutes maximum
- Memory: 128 MB to 10,240 MB
- Payload: 6 MB (synchronous), 256 KB (asynchronous)
- /tmp storage: 512 MB to 10,240 MB
- Environment variables: 4 KB total

Concurrency:
- Default: 1000 concurrent executions per region
- Burst concurrency: 500-3000 (varies by region)
- Reserved concurrency: Guarantee for critical functions
```

##### Lambda Best Practices
- Keep functions small and focused
- Minimize cold start impact
- Use connection pooling for databases
- Implement proper error handling
- Monitor with CloudWatch and X-Ray

### Amazon API Gateway

#### API Gateway Types
1. **REST API**: Full-featured API management
2. **HTTP API**: Lower cost, higher performance
3. **WebSocket API**: Real-time bidirectional communication

#### API Gateway Features
- **Authentication**: Cognito, Lambda authorizers, IAM
- **Rate Limiting**: Throttling and quotas
- **Caching**: Response caching for performance
- **CORS**: Cross-origin resource sharing
- **Stage Management**: dev, staging, production

### Amazon EventBridge (CloudWatch Events)

#### EventBridge Concepts
1. **Events**: JSON objects describing state changes
2. **Event Bus**: Receives and routes events
3. **Rules**: Match events and route to targets
4. **Targets**: Destinations for events

#### Event Patterns
```json
{
  "source": ["aws.ec2"],
  "detail-type": ["EC2 Instance State-change Notification"],
  "detail": {
    "state": ["stopped"]
  }
}
```

### Step Functions

#### State Machine Types
1. **Standard Workflows**: Long-running, exactly-once execution
2. **Express Workflows**: Short-duration, high-rate execution

#### State Types
- **Task**: Execute work (Lambda, ECS, etc.)
- **Choice**: Conditional branching
- **Parallel**: Execute parallel branches
- **Wait**: Delay execution
- **Pass**: Pass input to output
- **Fail/Succeed**: End execution

### Assignment 3.2: Serverless Application Architecture
**Scenario**: Build serverless order processing system

**Requirements**:
1. Order submission via API
2. Payment processing with external service
3. Inventory validation and update
4. Email/SMS notifications
5. Order status tracking
6. Analytics and reporting
7. Error handling and retry logic

**Deliverables**:
- API Gateway configuration
- Lambda function design
- Step Functions workflow
- EventBridge event routing
- Error handling strategy
- Monitoring and observability plan

---

## Week 9: Message Queuing & Security

### Amazon SQS (Simple Queue Service)

#### Queue Types
1. **Standard Queue**
   - At-least-once delivery
   - Nearly unlimited throughput
   - Best-effort ordering

2. **FIFO Queue**
   - Exactly-once processing
   - Strict ordering (within group)
   - Up to 300 TPS (3000 with batching)

#### SQS Features
- **Dead Letter Queues**: Handle message failures
- **Long Polling**: Reduce empty receives
- **Message Attributes**: Metadata for messages
- **Batch Operations**: Send/receive multiple messages
- **Server-Side Encryption**: Message encryption

#### Important Notes

##### SQS Message Lifecycle
```
1. Producer sends message to queue
2. Message becomes available for consumers
3. Consumer receives and processes message
4. Consumer deletes message from queue
5. If not deleted, message becomes visible again
```

##### Visibility Timeout
- Period when message is invisible to other consumers
- Default: 30 seconds, Max: 12 hours
- Should be longer than processing time
- Can be changed per message

### Amazon SNS (Simple Notification Service)

#### SNS Concepts
1. **Topic**: Communication channel
2. **Publisher**: Sends messages to topic
3. **Subscriber**: Receives messages from topic
4. **Message**: Data sent through topic

#### Subscription Types
- **HTTP/HTTPS**: Web endpoints
- **Email/Email-JSON**: Email notifications
- **SMS**: Text messages
- **SQS**: Queue integration
- **Lambda**: Function triggers
- **Mobile Push**: iOS, Android, Windows

#### SNS Features
- **Message Filtering**: Attribute-based filtering
- **Message Attributes**: Metadata for routing
- **Delivery Retry**: Automatic retry policies
- **Dead Letter Queues**: Failed delivery handling

### Security Services

#### AWS WAF (Web Application Firewall)
1. **Web ACLs**: Rules to allow/block requests
2. **Rules**: Conditions for filtering traffic
3. **Rate Limiting**: Protect against DDoS
4. **Managed Rules**: AWS and third-party rule sets

#### AWS Shield
1. **Shield Standard**: Free DDoS protection
2. **Shield Advanced**: Enhanced DDoS protection
   - 24/7 DDoS Response Team
   - Cost protection
   - Advanced attack diagnostics

#### AWS Secrets Manager
- **Secret Rotation**: Automatic credential rotation
- **Cross-Region Replication**: Multi-region secrets
- **Fine-grained Access**: IAM and resource policies
- **Integration**: RDS, DocumentDB, Redshift

#### AWS Systems Manager
1. **Parameter Store**: Configuration management
2. **Session Manager**: Secure shell access
3. **Patch Manager**: OS and software patching
4. **Run Command**: Remote command execution
5. **State Manager**: Configuration compliance

### Assignment 3.3: Secure Messaging Architecture
**Scenario**: Design secure, scalable messaging system for financial services

**Requirements**:
1. Order processing with guaranteed delivery
2. Real-time fraud detection alerts
3. Regulatory compliance logging
4. Multi-region disaster recovery
5. PCI DSS compliance
6. End-to-end encryption
7. Audit trail for all transactions

**Deliverables**:
- Message queue architecture (SQS/SNS)
- Security implementation (WAF, Shield, Secrets Manager)
- Encryption strategy (at rest and in transit)
- Compliance monitoring framework
- Disaster recovery plan
- Performance and scalability design

### Phase 3 Summary Assessment
**Comprehensive Assignment**: Design a modern, cloud-native application platform

**Scenario**: Multi-tenant SaaS platform with the following requirements:
- Microservices architecture with containers
- Event-driven serverless components
- Real-time messaging and notifications
- Multi-tenant security isolation
- Global scalability and performance
- Compliance with SOC 2 and GDPR
- CI/CD automation
- Comprehensive monitoring and logging

**Deliverables**:
1. Container orchestration strategy (ECS/EKS)
2. Serverless architecture design (Lambda, API Gateway)
3. Event-driven architecture (EventBridge, SQS, SNS)
4. Security framework (WAF, Shield, IAM, encryption)
5. CI/CD pipeline design
6. Multi-tenant isolation strategy
7. Monitoring and observability plan
8. Disaster recovery and business continuity
9. Cost optimization recommendations
10. Compliance and governance framework
