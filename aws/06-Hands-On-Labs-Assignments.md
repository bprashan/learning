# AWS Hands-On Labs & Practice Assignments

> **🚀 Hands-On Philosophy**: "I hear and I forget. I see and I remember. I do and I understand." - These labs are designed to build muscle memory for AWS services through real-world scenarios.

## 🎯 Lab Success Framework
- **Build**: Follow the step-by-step instructions
- **Break**: Intentionally introduce failures to learn troubleshooting
- **Optimize**: Improve the solution for cost, performance, or security
- **Document**: Create your own troubleshooting guides

## Lab Environment Setup

### Prerequisites
- AWS Free Tier Account
- AWS CLI installed and configured
- Basic understanding of networking concepts
- Command line familiarity

### 💸 Cost Management (Critical!)
- Set up billing alerts for $10, $25, $50
- Use AWS Cost Explorer to monitor spending
- Always clean up resources after labs
- Utilize AWS Free Tier eligible services when possible

**⚠️ Cost Horror Stories**: Students have received $500+ bills from forgotten resources. Don't be that person!

### 🛡️ Security Best Practices for Labs
```bash
# Always use temporary credentials
aws configure set aws_access_key_id YOUR_KEY
aws configure set aws_secret_access_key YOUR_SECRET
aws configure set default.region us-east-1

# Tag everything for easy cleanup
aws ec2 create-tags --resources INSTANCE_ID --tags Key=Purpose,Value=Learning
```

---

## Phase 1 Labs: Foundation Services

### Lab 1.1: VPC and Networking Fundamentals
**🎯 Objective**: Create a production-ready VPC with public and private subnets

**🤔 Before You Start**: Can you explain why we need both public and private subnets? What security risks does a public subnet introduce?

**Real-World Context**: You're a DevOps engineer at a startup. The CTO wants to move from a single EC2 instance to a proper 3-tier architecture. This is your first step.

**Steps:**
1. **Create VPC**
   ```
   CIDR: 10.0.0.0/16
   DNS hostnames: Enabled
   DNS resolution: Enabled
   ```

2. **Create Subnets**
   ```
   Public Subnet 1: 10.0.1.0/24 (us-east-1a)
   Public Subnet 2: 10.0.2.0/24 (us-east-1b)
   Private Subnet 1: 10.0.11.0/24 (us-east-1a)
   Private Subnet 2: 10.0.12.0/24 (us-east-1b)
   Database Subnet 1: 10.0.21.0/24 (us-east-1a)
   Database Subnet 2: 10.0.22.0/24 (us-east-1b)
   ```

3. **Configure Gateways**
   - Internet Gateway for public access
   - NAT Gateway in public subnet for private subnet internet access

4. **Set up Route Tables**
   - Public route table with 0.0.0.0/0 → Internet Gateway
   - Private route table with 0.0.0.0/0 → NAT Gateway

5. **Security Groups**
   - Web tier SG (80, 443 from internet)
   - App tier SG (8080 from web tier)
   - DB tier SG (3306 from app tier)

**🔍 Learning Checkpoints**:
- After creating the VPC: "Can you explain why we chose /16 instead of /24?"
- After subnets: "What happens if we put the database in a public subnet?"
- After security groups: "Why is the database only accessible from the app tier?"

**Validation**:
- Launch EC2 in public subnet, verify internet access
- Launch EC2 in private subnet, verify outbound internet via NAT
- Test security group rules between tiers

**🚨 Troubleshooting Challenge**: 
Intentionally misconfigure a route table and document how you'd diagnose the connectivity issue. This simulates a real-world incident.

**💡 Cost Optimization Note**: 
NAT Gateways cost ~$45/month. For dev environments, consider NAT instances (~$8/month) instead.

### 🎯 Knowledge Check Quiz
1. What's the maximum number of VPCs per region per account?
2. Can security groups span multiple VPCs?
3. What's the difference between 0.0.0.0/0 and 10.0.0.0/16 in a route table?

*Answers: 1) 5 (can be increased), 2) No, 3) 0.0.0.0/0 is all internet traffic, 10.0.0.0/16 is internal VPC traffic*

### Lab 1.2: IAM Security Implementation
**🎯 Objective**: Implement least privilege access with IAM

**📚 Business Context**: You're setting up AWS access for a growing team. The CISO demands zero-trust principles and regular audit capabilities.

**🎭 Scenarios to Implement**:
1. **Developer Role**
   ```json
   Permissions:
   - EC2 read-only in dev environment
   - S3 full access to dev buckets
   - CloudWatch logs read access
   - No production access
   ```

2. **DevOps Role**
   ```json
   Permissions:
   - EC2 full access across environments
   - IAM pass role for EC2
   - CloudFormation full access
   - Systems Manager access
   ```

3. **Auditor Role**
   ```json
   Permissions:
   - Read-only access to all services
   - CloudTrail access
   - Config access
   - Cost Explorer access
   ```

**Tasks:**
- Create custom policies for each role
- Set up cross-account access
- Implement MFA enforcement
- Configure password policy
- Test role switching

### Lab 1.3: S3 Security and Lifecycle Management
**Objective**: Implement comprehensive S3 security and cost optimization

**Implementation:**
1. **Bucket Creation**
   ```
   Bucket: company-data-lake-[your-initials]
   Region: us-east-1
   Versioning: Enabled
   Encryption: SSE-S3 default
   ```

2. **Lifecycle Policy**
   ```json
   {
     "Rules": [
       {
         "Status": "Enabled",
         "Filter": {"Prefix": "logs/"},
         "Transitions": [
           {
             "Days": 30,
             "StorageClass": "STANDARD_IA"
           },
           {
             "Days": 90,
             "StorageClass": "GLACIER"
           },
           {
             "Days": 365,
             "StorageClass": "DEEP_ARCHIVE"
           }
         ]
       }
     ]
   }
   ```

3. **Security Configuration**
   - Block all public access
   - Bucket policy for specific IAM roles
   - CloudTrail for access logging
   - Event notifications to SNS

**Validation:**
- Upload files with different prefixes
- Verify lifecycle transitions (simulate with reduced timeframes)
- Test access from different IAM roles
- Monitor costs in Cost Explorer

---

## Phase 2 Labs: Intermediate Services

### Lab 2.1: Auto Scaling Web Application
**Objective**: Deploy auto-scaling web application with load balancer

**Architecture:**
```
Internet → ALB → Auto Scaling Group → EC2 Instances → RDS
```

**Implementation Steps:**

1. **Launch Template Creation**
   ```bash
   # User Data Script
   #!/bin/bash
   yum update -y
   yum install -y httpd
   systemctl start httpd
   systemctl enable httpd
   echo "<h1>Web Server $(hostname -f)</h1>" > /var/www/html/index.html
   
   # Install CloudWatch agent
   wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
   rpm -U ./amazon-cloudwatch-agent.rpm
   ```

2. **Application Load Balancer**
   - Target group with health checks
   - Security group allowing HTTP/HTTPS
   - Multiple AZ configuration

3. **Auto Scaling Group**
   ```
   Min: 2 instances
   Max: 10 instances
   Desired: 2 instances
   Target Tracking: CPU Utilization 70%
   ```

4. **Stress Testing**
   ```bash
   # Install stress testing tool
   sudo amazon-linux-extras install epel
   sudo yum install stress -y
   
   # Generate CPU load
   stress --cpu 8 --timeout 300s
   ```

**Monitoring:**
- CloudWatch dashboard with key metrics
- SNS notifications for scaling events
- Cost tracking for different load levels

### Lab 2.2: Database High Availability Setup
**Objective**: Configure RDS with Multi-AZ and read replicas

**Database Configuration:**
1. **Primary RDS Instance**
   ```
   Engine: MySQL 8.0
   Instance: db.t3.medium
   Multi-AZ: Enabled
   Backup: 7 days retention
   Encryption: Enabled
   ```

2. **Read Replica Setup**
   - Create read replica in same region
   - Create cross-region read replica
   - Configure application to use read replicas for queries

3. **Performance Testing**
   ```sql
   -- Create test database and tables
   CREATE DATABASE ecommerce;
   USE ecommerce;
   
   CREATE TABLE products (
     id INT AUTO_INCREMENT PRIMARY KEY,
     name VARCHAR(255),
     price DECIMAL(10,2),
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   
   -- Insert test data
   INSERT INTO products (name, price) VALUES 
   ('Product 1', 19.99),
   ('Product 2', 29.99);
   ```

4. **Monitoring Setup**
   - Performance Insights enabled
   - CloudWatch custom metrics
   - Enhanced monitoring

**Failover Testing:**
- Simulate primary instance failure
- Measure RTO and RPO
- Validate application connectivity

### Lab 2.3: Serverless API Development
**Objective**: Build serverless API with Lambda and API Gateway

**Architecture:**
```
Client → API Gateway → Lambda → DynamoDB
```

**Implementation:**

1. **DynamoDB Table Setup**
   ```json
   {
     "TableName": "Users",
     "KeySchema": [
       {
         "AttributeName": "userId",
         "KeyType": "HASH"
       }
     ],
     "AttributeDefinitions": [
       {
         "AttributeName": "userId",
         "AttributeType": "S"
       }
     ],
     "BillingMode": "PAY_PER_REQUEST"
   }
   ```

2. **Lambda Function (Node.js)**
   ```javascript
   const AWS = require('aws-sdk');
   const dynamoDB = new AWS.DynamoDB.DocumentClient();
   
   exports.handler = async (event) => {
     const { httpMethod, pathParameters, body } = event;
     
     switch (httpMethod) {
       case 'GET':
         return await getUser(pathParameters.userId);
       case 'POST':
         return await createUser(JSON.parse(body));
       case 'PUT':
         return await updateUser(pathParameters.userId, JSON.parse(body));
       case 'DELETE':
         return await deleteUser(pathParameters.userId);
       default:
         return {
           statusCode: 405,
           body: JSON.stringify({ message: 'Method not allowed' })
         };
     }
   };
   
   async function getUser(userId) {
     const params = {
       TableName: 'Users',
       Key: { userId }
     };
     
     const result = await dynamoDB.get(params).promise();
     return {
       statusCode: 200,
       headers: {
         'Content-Type': 'application/json',
         'Access-Control-Allow-Origin': '*'
       },
       body: JSON.stringify(result.Item)
     };
   }
   ```

3. **API Gateway Configuration**
   - REST API with resource paths
   - CORS configuration
   - Request/response transformations
   - API keys and usage plans

4. **Testing and Monitoring**
   ```bash
   # Test API endpoints
   curl -X POST https://api-id.execute-api.region.amazonaws.com/prod/users \
     -H "Content-Type: application/json" \
     -d '{"name":"John Doe","email":"john@example.com"}'
   
   curl https://api-id.execute-api.region.amazonaws.com/prod/users/123
   ```

---

## Phase 3 Labs: Advanced Services

### Lab 3.1: Container Orchestration with ECS
**Objective**: Deploy microservices application using ECS Fargate

**Application Architecture:**
```
ALB → ECS Service (Frontend) → ECS Service (Backend API) → RDS
```

**Implementation:**

1. **Dockerfile for Frontend (React)**
   ```dockerfile
   FROM node:14-alpine AS builder
   WORKDIR /app
   COPY package*.json ./
   RUN npm install
   COPY . .
   RUN npm run build
   
   FROM nginx:alpine
   COPY --from=builder /app/build /usr/share/nginx/html
   EXPOSE 80
   CMD ["nginx", "-g", "daemon off;"]
   ```

2. **ECS Task Definition**
   ```json
   {
     "family": "frontend-task",
     "networkMode": "awsvpc",
     "requiresCompatibilities": ["FARGATE"],
     "cpu": "256",
     "memory": "512",
     "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
     "containerDefinitions": [
       {
         "name": "frontend-container",
         "image": "your-account.dkr.ecr.region.amazonaws.com/frontend:latest",
         "portMappings": [
           {
             "containerPort": 80,
             "protocol": "tcp"
           }
         ],
         "logConfiguration": {
           "logDriver": "awslogs",
           "options": {
             "awslogs-group": "/ecs/frontend",
             "awslogs-region": "us-east-1",
             "awslogs-stream-prefix": "ecs"
           }
         }
       }
     ]
   }
   ```

3. **ECS Service Configuration**
   - Auto Scaling based on CPU and memory
   - Service discovery with Cloud Map
   - Load balancer integration
   - Health checks

4. **CI/CD Pipeline**
   ```yaml
   # buildspec.yml for CodeBuild
   version: 0.2
   phases:
     pre_build:
       commands:
         - echo Logging in to Amazon ECR...
         - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
     build:
       commands:
         - echo Build started on `date`
         - echo Building the Docker image...
         - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
         - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
     post_build:
       commands:
         - echo Build completed on `date`
         - echo Pushing the Docker image...
         - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
   ```

### Lab 3.2: Event-Driven Architecture with SQS/SNS
**Objective**: Build asynchronous processing system

**Architecture:**
```
API Gateway → Lambda (Publisher) → SNS → SQS → Lambda (Processors) → DynamoDB
```

**Implementation:**

1. **Order Processing Workflow**
   ```javascript
   // Order Publisher Lambda
   const AWS = require('aws-sdk');
   const sns = new AWS.SNS();
   
   exports.handler = async (event) => {
     const order = JSON.parse(event.body);
     
     const message = {
       orderId: order.id,
       customerId: order.customerId,
       items: order.items,
       total: order.total,
       timestamp: new Date().toISOString()
     };
     
     const params = {
       TopicArn: process.env.ORDER_TOPIC_ARN,
       Message: JSON.stringify(message),
       MessageAttributes: {
         orderType: {
           DataType: 'String',
           StringValue: order.type
         }
       }
     };
     
     await sns.publish(params).promise();
     
     return {
       statusCode: 200,
       body: JSON.stringify({ orderId: order.id, status: 'processing' })
     };
   };
   ```

2. **SQS Queue Configuration**
   ```json
   {
     "QueueName": "order-processing-queue",
     "Attributes": {
       "VisibilityTimeoutSeconds": "300",
       "MaxReceiveCount": "3",
       "MessageRetentionPeriod": "1209600"
     },
     "RedrivePolicy": {
       "deadLetterTargetArn": "arn:aws:sqs:region:account:dlq-queue",
       "maxReceiveCount": 3
     }
   }
   ```

3. **Order Processor Lambda**
   ```javascript
   exports.handler = async (event) => {
     for (const record of event.Records) {
       const message = JSON.parse(record.body);
       const orderData = JSON.parse(message.Message);
       
       try {
         // Process order logic
         await processOrder(orderData);
         
         // Update order status
         await updateOrderStatus(orderData.orderId, 'completed');
         
       } catch (error) {
         console.error('Order processing failed:', error);
         throw error; // Will send to DLQ after retries
       }
     }
   };
   ```

4. **Monitoring and Alerting**
   - CloudWatch metrics for queue depth
   - Dead letter queue monitoring
   - SNS notifications for failures
   - X-Ray tracing for end-to-end visibility

---

## Phase 4 Labs: Architect Level

### Lab 4.1: Multi-Region Disaster Recovery
**Objective**: Implement automated disaster recovery across regions

**Architecture:**
```
Primary Region (us-east-1):
- ECS Cluster with Applications
- RDS with Cross-Region Read Replica
- S3 with Cross-Region Replication

Secondary Region (us-west-2):
- Standby ECS Cluster
- RDS Read Replica (promotable)
- S3 Replica
```

**Implementation:**

1. **Infrastructure as Code (CloudFormation)**
   ```yaml
   AWSTemplateFormatVersion: '2010-09-09'
   Parameters:
     Environment:
       Type: String
       Default: production
     
   Resources:
     VPC:
       Type: AWS::EC2::VPC
       Properties:
         CidrBlock: 10.0.0.0/16
         EnableDnsHostnames: true
         EnableDnsSupport: true
         Tags:
           - Key: Name
             Value: !Sub ${Environment}-vpc
   
     # RDS with Cross-Region Replica
     PrimaryDatabase:
       Type: AWS::RDS::DBInstance
       Properties:
         Engine: mysql
         DBInstanceClass: db.t3.medium
         MultiAZ: true
         BackupRetentionPeriod: 7
         StorageEncrypted: true
   ```

2. **Automated Failover Lambda**
   ```python
   import boto3
   import json
   
   def lambda_handler(event, context):
       route53 = boto3.client('route53')
       rds = boto3.client('rds')
       
       # Health check failed - initiate failover
       if event['source'] == 'aws.route53':
           # Promote read replica to primary
           response = rds.promote_read_replica(
               DBInstanceIdentifier='secondary-db-instance'
           )
           
           # Update Route 53 records to point to secondary region
           route53.change_resource_record_sets(
               HostedZoneId='Z123456789',
               ChangeBatch={
                   'Changes': [{
                       'Action': 'UPSERT',
                       'ResourceRecordSet': {
                           'Name': 'api.company.com',
                           'Type': 'A',
                           'SetIdentifier': 'primary',
                           'Failover': 'PRIMARY',
                           'AliasTarget': {
                               'DNSName': 'secondary-alb.us-west-2.elb.amazonaws.com',
                               'EvaluateTargetHealth': True
                           }
                       }
                   }]
               }
           )
       
       return {'statusCode': 200}
   ```

3. **Recovery Testing Automation**
   ```bash
   #!/bin/bash
   # Disaster Recovery Testing Script
   
   echo "Starting DR Test..."
   
   # 1. Create point-in-time snapshot
   aws rds create-db-snapshot \
     --db-instance-identifier production-db \
     --db-snapshot-identifier dr-test-$(date +%Y%m%d)
   
   # 2. Simulate primary region failure
   aws route53 change-resource-record-sets \
     --hosted-zone-id Z123456789 \
     --change-batch file://failover-changeset.json
   
   # 3. Validate secondary region functionality
   curl -f https://api.company.com/health || exit 1
   
   # 4. Measure RTO and RPO
   echo "DR Test completed successfully"
   ```

### Lab 4.2: Enterprise Multi-Account Setup
**Objective**: Implement AWS Organizations with Control Tower

**Account Structure:**
```
Master Account (Billing)
├── Core OU
│   ├── Log Archive Account
│   ├── Audit Account
│   └── Shared Services Account
├── Production OU
│   ├── Prod Account 1
│   └── Prod Account 2
└── Non-Production OU
    ├── Dev Account
    ├── Test Account
    └── Staging Account
```

**Implementation:**

1. **Service Control Policy (SCP)**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Deny",
         "Action": [
           "ec2:TerminateInstances",
           "rds:DeleteDBInstance"
         ],
         "Resource": "*",
         "Condition": {
           "StringNotEquals": {
             "aws:PrincipalTag/Department": "DevOps"
           }
         }
       },
       {
         "Effect": "Deny",
         "Action": "ec2:RunInstances",
         "Resource": "arn:aws:ec2:*:*:instance/*",
         "Condition": {
           "ForAllValues:StringNotEquals": {
             "ec2:InstanceType": [
               "t3.micro",
               "t3.small",
               "t3.medium"
             ]
           }
         }
       }
     ]
   }
   ```

2. **Cross-Account Role Setup**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::SHARED-SERVICES-ACCOUNT:root"
         },
         "Action": "sts:AssumeRole",
         "Condition": {
           "StringEquals": {
             "sts:ExternalId": "unique-external-id"
           }
         }
       }
     ]
   }
   ```

3. **Automated Account Provisioning**
   ```python
   import boto3
   from botocore.exceptions import ClientError
   
   def create_account(account_name, email, organizational_unit):
       organizations = boto3.client('organizations')
       
       try:
           # Create account
           response = organizations.create_account(
               Email=email,
               AccountName=account_name
           )
           
           account_id = response['CreateAccountStatus']['AccountId']
           
           # Move to appropriate OU
           organizations.move_account(
               AccountId=account_id,
               SourceParentId='root',
               DestinationParentId=organizational_unit
           )
           
           # Apply baseline configuration
           apply_account_baseline(account_id)
           
           return account_id
           
       except ClientError as e:
           print(f"Error creating account: {e}")
           return None
   ```

---

## Practice Scenarios

### Scenario 1: E-commerce Platform Migration
**Business Context:**
- Legacy on-premises e-commerce platform
- 1M+ daily active users
- Peak traffic during sales events (10x normal)
- Global customer base
- 99.99% availability requirement

**Your Tasks:**
1. Design migration strategy
2. Plan for traffic spikes
3. Implement global distribution
4. Set up monitoring and alerting
5. Calculate cost projections

### Scenario 2: Financial Services Compliance
**Business Context:**
- Investment banking application
- PCI DSS compliance required
- Real-time transaction processing
- Zero data loss tolerance
- Regulatory audit requirements

**Your Tasks:**
1. Design secure architecture
2. Implement compliance controls
3. Set up audit logging
4. Plan disaster recovery
5. Create security documentation

### Scenario 3: IoT Data Processing Platform
**Business Context:**
- Manufacturing IoT sensors
- 100,000+ devices sending data
- Real-time analytics required
- Historical data analysis
- Machine learning predictions

**Your Tasks:**
1. Design data ingestion pipeline
2. Implement real-time processing
3. Set up data lake architecture
4. Build ML inference pipeline
5. Plan for scaling to 1M devices

---

## Assessment Criteria

### Technical Competency
- [ ] Correct service selection for requirements
- [ ] Scalable and resilient architecture design
- [ ] Security best practices implementation
- [ ] Cost optimization considerations
- [ ] Monitoring and observability setup

### Operational Excellence
- [ ] Infrastructure as Code usage
- [ ] Automated deployment pipelines
- [ ] Disaster recovery planning
- [ ] Performance optimization
- [ ] Documentation quality

### Problem-Solving Skills
- [ ] Requirement analysis and clarification
- [ ] Trade-off evaluation
- [ ] Risk assessment and mitigation
- [ ] Creative solution design
- [ ] Implementation planning

### Communication
- [ ] Clear architecture documentation
- [ ] Business value articulation
- [ ] Technical presentation skills
- [ ] Stakeholder engagement
- [ ] Knowledge transfer capability
