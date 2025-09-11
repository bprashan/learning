# AWS Troubleshooting Playbook

> **🔥 Real-World Scenarios**: Every AWS architect faces these issues. Learn to diagnose and fix problems like a pro with this practical troubleshooting guide.

## 🎯 Troubleshooting Methodology

### The 5-Step AWS Debugging Process
1. **Gather Data**: What exactly is failing?
2. **Check Fundamentals**: Network, IAM, service limits
3. **Isolate Variables**: Test one component at a time
4. **Verify Assumptions**: Don't assume, validate
5. **Document Solution**: Build your knowledge base

### 🛠️ Essential Troubleshooting Tools
```bash
# AWS CLI debugging
aws --debug s3 ls  # See what's happening under the hood
aws sts get-caller-identity  # Verify credentials
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name]'

# Network connectivity
nc -zv hostname port  # Test port connectivity
dig hostname  # DNS resolution
traceroute hostname  # Network path

# System diagnostics
curl -I http://169.254.169.254/latest/meta-data/  # Instance metadata
cat /var/log/cloud-init.log  # EC2 startup logs
```

---

## 🚨 Common Emergency Scenarios

### Scenario 1: "The Website is Down!"

**📞 The Call**: "Our e-commerce site is showing 502 errors. It's Black Friday and we're losing thousands of dollars per minute!"

#### 🔍 Diagnostic Checklist
```
Quick Wins (2 minutes):
□ Check AWS Status Page (status.aws.amazon.com)
□ Verify load balancer health checks
□ Check Auto Scaling group instances
□ Review CloudWatch alarms

Deeper Investigation (5 minutes):
□ Examine ALB target groups
□ Check security group rules
□ Review application logs
□ Verify database connectivity
```

#### 💡 Solution Walkthrough

**Step 1: Load Balancer Investigation**
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...

# Common issues:
# - All targets unhealthy
# - Health check path returning errors
# - Security group blocking health checks
```

**Step 2: Instance Health Check**
```bash
# SSH to instance and check application
sudo systemctl status nginx
curl -I localhost:80
tail -f /var/log/nginx/error.log
```

**Step 3: Database Connectivity**
```bash
# Test database connection
mysql -h database-endpoint -u username -p
# Check for connection limits, deadlocks, or performance issues
```

**🏆 Resolution**: Often caused by:
- Failed health checks due to misconfigured health check path
- Database connection pool exhaustion
- Security group changes blocking traffic
- Auto Scaling policies not triggered

---

### Scenario 2: "Can't Connect to Database"

**📞 The Call**: "Our application can't connect to RDS. It was working yesterday!"

#### 🔍 The Detective Work

**Evidence Gathering**:
```bash
# Test connectivity
telnet rds-endpoint 3306
nslookup rds-endpoint

# Check security groups
aws rds describe-db-instances --db-instance-identifier mydb
aws ec2 describe-security-groups --group-ids sg-xxxxxx
```

#### 🎯 Common Culprits & Solutions

**1. Security Group Changes**
```bash
# Problem: Someone modified security groups
# Solution: Add application server security group to RDS security group
aws ec2 authorize-security-group-ingress \
  --group-id sg-rds-security-group \
  --protocol tcp \
  --port 3306 \
  --source-group sg-app-security-group
```

**2. VPC Route Table Issues**
```bash
# Problem: Route tables misconfigured
# Check route tables for database subnets
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=subnet-xxxxx"
```

**3. NACL Blocking Traffic**
```bash
# Problem: Network ACL denying traffic
# NACLs are stateless - need inbound AND outbound rules
aws ec2 describe-network-acls --filters "Name=association.subnet-id,Values=subnet-xxxxx"
```

**🏆 Pro Tip**: Create a database connectivity test script:
```bash
#!/bin/bash
DB_HOST="your-rds-endpoint"
DB_PORT="3306"

echo "Testing DNS resolution..."
nslookup $DB_HOST

echo "Testing port connectivity..."
nc -zv $DB_HOST $DB_PORT

echo "Testing MySQL connection..."
mysql -h $DB_HOST -u testuser -p testdb -e "SELECT 1;"
```

---

### Scenario 3: "S3 Access Denied"

**📞 The Call**: "I'm getting Access Denied when trying to upload to S3, but I'm the admin!"

#### 🔍 S3 Permission Matrix

S3 access requires BOTH:
- **IAM permissions** (what the user can do)
- **Bucket policies** (what the bucket allows)
- **ACLs** (legacy, but still can block)

#### 🕵️ Investigation Process

**Step 1: Check IAM Permissions**
```bash
# Test user's actual permissions
aws sts get-caller-identity
aws s3 ls s3://bucket-name --debug
```

**Step 2: Examine Bucket Policy**
```bash
aws s3api get-bucket-policy --bucket bucket-name
```

**Step 3: Check Bucket ACL**
```bash
aws s3api get-bucket-acl --bucket bucket-name
```

#### 🎯 Common Solutions

**Problem**: Bucket policy denying access
```json
{
  "Effect": "Deny",
  "Principal": "*",
  "Action": "s3:*",
  "Resource": "arn:aws:s3:::bucket/*"
}
```
**Solution**: Modify to allow specific principals or remove deny-all.

**Problem**: Cross-account access issues
```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::ACCOUNT-B:root"
  },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::bucket/*"
}
```

---

### Scenario 4: "Lambda Function Timing Out"

**📞 The Call**: "Our payment processing Lambda is timing out and customers can't complete purchases!"

#### 🔍 Lambda Debugging Arsenal

**CloudWatch Logs Investigation**:
```bash
# Stream real-time logs
aws logs tail /aws/lambda/payment-processor --follow

# Search for specific errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/payment-processor \
  --filter-pattern "ERROR"
```

#### 🎯 Timeout Troubleshooting

**1. Cold Start Issues**
```python
import time
start_time = time.time()

def lambda_handler(event, context):
    # Your code here
    
    execution_time = time.time() - start_time
    print(f"Execution time: {execution_time}")
    return response
```

**2. VPC Configuration Problems**
- Lambda in VPC = slower cold starts
- Need NAT Gateway for internet access
- ENI creation delays

**3. Database Connection Pooling**
```python
# BAD: Creates new connection each time
import mysql.connector
def lambda_handler(event, context):
    conn = mysql.connector.connect(host='rds-endpoint')
    # Process...
    conn.close()

# GOOD: Reuse connections
import mysql.connector
conn = None

def lambda_handler(event, context):
    global conn
    if conn is None:
        conn = mysql.connector.connect(host='rds-endpoint')
    # Process...
```

---

### Scenario 5: "Unexpected AWS Bill"

**📞 The Call**: "Our AWS bill jumped from $1,000 to $10,000 this month. What happened?!"

#### 🔍 Cost Detective Work

**Step 1: Cost Explorer Investigation**
```bash
# Check top services by cost
aws ce get-cost-and-usage \
  --time-period Start=2023-10-01,End=2023-10-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

**Step 2: Resource Inventory**
```bash
# Find expensive resources
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name]'
aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]'
```

#### 🎯 Common Cost Culprits

**1. Forgotten Resources**
- EC2 instances left running
- RDS instances in non-production
- Load balancers with no targets
- NAT Gateways with no traffic

**2. Data Transfer Costs**
- Cross-region replication
- CloudFront origin requests
- NAT Gateway data processing

**3. Storage Costs**
- EBS snapshots accumulating
- S3 storage class not optimized
- Log files growing unchecked

**🛠️ Cost Optimization Script**:
```bash
#!/bin/bash
echo "=== Cost Optimization Audit ==="

echo "Stopped EC2 instances (still incurring EBS costs):"
aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped"

echo "Unattached EBS volumes:"
aws ec2 describe-volumes --filters "Name=status,Values=available"

echo "Load balancers with no targets:"
aws elbv2 describe-load-balancers --query 'LoadBalancers[?State.Code==`active`]'

echo "RDS instances by cost (estimate):"
aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass,Engine]'
```

---

## 🔧 Advanced Troubleshooting Techniques

### Network Packet Analysis
```bash
# Capture packets on EC2
sudo tcpdump -i eth0 -w capture.pcap
sudo tcpdump -i eth0 host database-endpoint

# Analyze with netstat
netstat -an | grep :80
ss -tulpn | grep :443
```

### VPC Flow Logs Analysis
```bash
# Enable VPC Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-xxxxxx \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name VPCFlowLogs

# Query common patterns
# REJECT traffic (security groups blocking)
aws logs filter-log-events \
  --log-group-name VPCFlowLogs \
  --filter-pattern "REJECT"
```

### X-Ray Distributed Tracing
```python
from aws_xray_sdk.core import xray_recorder

@xray_recorder.capture('database_query')
def get_user_data(user_id):
    # Database query here
    pass

# This helps identify slow components in microservices
```

---

## 🎯 Troubleshooting Cheat Sheets

### Quick Reference: Service-Specific Issues

#### EC2 Troubleshooting
```
Can't SSH:
□ Security group allows port 22
□ NACL allows SSH traffic
□ Key pair is correct
□ Instance is running
□ Public IP assigned (if needed)

Instance won't start:
□ Check service limits
□ Verify AMI exists
□ Check instance type availability in AZ
□ Review user data script errors
```

#### RDS Troubleshooting
```
Connection refused:
□ Security group allows database port
□ Subnet group configured correctly
□ Multi-AZ deployment didn't change endpoint
□ Parameter group settings

Performance issues:
□ Check Performance Insights
□ Review slow query logs
□ Monitor connections
□ Check read replica lag
```

#### Lambda Troubleshooting
```
Function errors:
□ Check CloudWatch logs
□ Verify IAM permissions
□ Review timeout settings
□ Check memory allocation

VPC connectivity:
□ Verify subnet configuration
□ Check route tables
□ Ensure NAT Gateway for internet
□ Review security groups
```

### 🏆 Pro Troubleshooting Tips

1. **Always check the basics first**: Network, IAM, service limits
2. **Use CloudWatch metrics**: They tell the story of what happened
3. **Enable detailed monitoring**: Worth the small cost for troubleshooting
4. **Create test scripts**: Automate common diagnostic checks
5. **Document everything**: Build your team's troubleshooting knowledge base

### 📚 Emergency Contacts Checklist

Keep these handy for real emergencies:
- AWS Support (if you have a support plan)
- Internal escalation procedures
- Vendor contact information
- Database administrator contacts
- Network team contacts

Remember: **Stay calm, work systematically, and document your findings!**
