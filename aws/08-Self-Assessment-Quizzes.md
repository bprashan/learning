# AWS Learning Self-Assessment & Quizzes

> **🎯 Purpose**: Regular self-assessment helps identify knowledge gaps and reinforces learning. Use these quizzes to gauge your progress and readiness for the next phase.

## How to Use This Assessment Guide

### 📊 Scoring System
- **90-100%**: Excellent! Ready for advanced topics
- **80-89%**: Good understanding, review weak areas
- **70-79%**: Needs improvement, revisit concepts
- **Below 70%**: Requires significant review

### 📚 Assessment Schedule
- **Weekly**: Quick knowledge checks (10-15 questions)
- **Phase End**: Comprehensive assessment (50+ questions)
- **Pre-Interview**: Full scenario-based evaluation

---

## Phase 1 Assessment: Foundation Services

### Week 1: Global Infrastructure & Core Concepts

#### Quick Knowledge Check (15 Questions)

**1. AWS Global Infrastructure**
Q: Which of the following is true about AWS Availability Zones?
a) They are isolated from each other but connected via high-speed links
b) They are always in different countries
c) They share the same physical infrastructure
d) They are connected via public internet

**Answer**: a) They are isolated from each other but connected via high-speed links

---

**2. Region Selection**
Q: Your application serves users primarily in Germany and France, with some users in Spain. For GDPR compliance, which region should be your primary choice?
a) us-east-1 (cheapest option)
b) eu-west-1 (Ireland)
c) eu-central-1 (Frankfurt)
d) eu-west-3 (Paris)

**Answer**: c) eu-central-1 (Frankfurt) - Central location for Germany/France with GDPR compliance

---

**3. Well-Architected Framework**
Q: A healthcare application needs to ensure patient data is never lost, even during disasters. Which pillar is MOST critical?
a) Cost Optimization
b) Performance Efficiency
c) Reliability
d) Security

**Answer**: c) Reliability (though Security is also critical, the question emphasizes data loss prevention)

---

**4. Edge Locations**
Q: How many CloudFront edge locations are there approximately worldwide?
a) 50+
b) 100+
c) 200+
d) 400+

**Answer**: d) 400+

---

**5. Service Categories**
Q: Which service category would Amazon RDS belong to?
a) Compute
b) Storage
c) Database
d) Networking

**Answer**: c) Database

---

### 🧠 Scenario-Based Questions

**6. Architecture Decision**
Your e-commerce company wants to expand globally. You currently serve 1M users from us-east-1. You're planning to add EU and APAC users. 

Q: What's the MOST cost-effective approach to handle 3x traffic growth globally?
a) Scale up existing infrastructure in us-east-1
b) Deploy to eu-west-1 and ap-southeast-1 with cross-region replication
c) Use CloudFront with us-east-1 as origin
d) Use multiple regions with Aurora Global Database

**Answer**: b) Deploy to multiple regions - provides better performance and scales more effectively than option c, and is more cost-effective than d for this scale.

---

**7. Compliance Challenge**
Q: A financial services company needs to ensure that European customer data never leaves the EU. How would you architect this?
a) Use eu-west-1 with cross-region replication to us-east-1
b) Use eu-west-1 only, with data classification and bucket policies
c) Use global services like CloudFront with EU-only origins
d) Use multiple EU regions with strict data governance

**Answer**: d) Use multiple EU regions with strict data governance

---

### Week 2: IAM Deep Dive

#### IAM Knowledge Check (20 Questions)

**8. Policy Evaluation**
Q: If a user has an explicit ALLOW for S3:GetObject and an explicit DENY for S3:*, what's the result?
a) Allow access
b) Deny access
c) Depends on policy order
d) Error in policy

**Answer**: b) Deny access (explicit deny always wins)

---

**9. Cross-Account Access**
Q: What's the MOST secure way to give a contractor temporary access to your AWS resources?
a) Create an IAM user with temporary password
b) Share your access keys with expiration
c) Create a cross-account role with external ID
d) Add them to an existing IAM group

**Answer**: c) Create a cross-account role with external ID

---

**10. Service-Linked Roles**
Q: When would AWS automatically create a service-linked role?
a) When you create an IAM user
b) When you enable a service that requires specific permissions
c) When you create a custom policy
d) When you use AWS CLI

**Answer**: b) When you enable a service that requires specific permissions

---

### 🔥 Challenge Scenarios

**11. The Misconfigured S3 Bucket**
A developer complains they can't access an S3 bucket despite having full S3 permissions in their IAM policy. The bucket policy is:
```json
{
  "Effect": "Deny",
  "Principal": "*",
  "Action": "s3:*",
  "Resource": "arn:aws:s3:::sensitive-bucket/*"
}
```

Q: What's wrong and how do you fix it?
a) The IAM policy is wrong
b) The bucket policy is too restrictive
c) The developer needs MFA
d) The bucket is in the wrong region

**Answer**: b) The bucket policy is too restrictive - it's denying everyone access

**Fix**: Modify bucket policy to allow specific IAM roles/users:
```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::ACCOUNT:user/developer"
  },
  "Action": "s3:*",
  "Resource": "arn:aws:s3:::sensitive-bucket/*"
}
```

---

**12. Federation Nightmare**
Your company uses Active Directory and wants seamless AWS access. Users complain about having to manage separate AWS credentials.

Q: What's the BEST solution?
a) Sync AD users to IAM users
b) Use AWS SSO with AD as identity source
c) Create shared IAM users
d) Use LDAP authentication

**Answer**: b) Use AWS SSO with AD as identity source

---

### Week 3: VPC and Networking

#### Networking Mastery Check (25 Questions)

**13. CIDR Planning**
Q: You have a VPC with CIDR 10.0.0.0/16. How many /24 subnets can you create?
a) 16
b) 64
c) 256
d) 65,536

**Answer**: c) 256 (16-bit network allows for 8 bits of subnet addressing: 2^8 = 256)

---

**14. NAT Gateway vs NAT Instance**
Q: When would you choose a NAT instance over a NAT gateway?
a) When you need higher bandwidth
b) When you need managed service benefits
c) When you need to customize the NAT functionality
d) When you need automatic failover

**Answer**: c) When you need to customize the NAT functionality

---

**15. Security Groups vs NACLs**
Q: A web server in a private subnet can't reach the internet through a NAT gateway. Security group allows all outbound traffic. What should you check?
a) Internet Gateway configuration
b) Route table for the private subnet
c) NACL rules for the private subnet
d) VPC DNS settings

**Answer**: c) NACL rules for the private subnet (since SG allows traffic, check NACLs)

---

### 💪 Advanced Scenarios

**16. The Mysterious Connection Timeout**
An application in private subnet A can't connect to a database in private subnet B, despite security groups allowing the traffic.

**Troubleshooting Steps** (Order them):
1. Check security group rules
2. Check NACL rules  
3. Check route tables
4. Check VPC DNS resolution
5. Test with telnet/nc

**Correct Order**: 1, 2, 3, 5, 4

Q: What's the MOST likely cause?
a) Security group misconfiguration
b) NACL blocking return traffic
c) Route table missing routes
d) DNS resolution issues

**Answer**: b) NACL blocking return traffic (NACLs are stateless)

---

**17. Multi-AZ Database Challenge**
You have an RDS instance in subnet A (AZ-1a). You want to enable Multi-AZ but get an error.

Q: What's the most likely cause?
a) Insufficient permissions
b) No subnet in a different AZ
c) Wrong instance class
d) Backup not enabled

**Answer**: b) No subnet in a different AZ (Multi-AZ requires subnets in different AZs)

---

## Phase 1 Comprehensive Assessment

### 🎯 Scenario-Based Comprehensive Test (30 Questions)

**Scenario 1: Startup Architecture**
A fintech startup needs to build their first AWS infrastructure. They have:
- Web application (React frontend)
- API backend (Node.js)
- PostgreSQL database
- 10,000 users initially, expecting 10x growth
- Compliance requirements (SOC 2)
- Budget constraint: $2,000/month

**Questions 18-22 relate to this scenario**

**18. Architecture Foundation**
Q: What's the MOST appropriate initial architecture?
a) Single EC2 instance with everything
b) Load balancer + Auto Scaling + RDS Multi-AZ
c) Serverless with Lambda + Aurora Serverless
d) Containers with ECS + RDS

**Answer**: c) Serverless with Lambda + Aurora Serverless (cost-effective for this scale and growth pattern)

---

**19. Security Implementation**
Q: For SOC 2 compliance, what's MOST critical initially?
a) WAF implementation
b) Comprehensive logging with CloudTrail
c) Advanced threat detection
d) Network segmentation

**Answer**: b) Comprehensive logging with CloudTrail (audit requirements)

---

**20. Scaling Strategy**
Q: How should they prepare for 10x growth?
a) Pre-provision for peak capacity
b) Design for horizontal scaling with monitoring
c) Upgrade to larger instances
d) Implement caching first

**Answer**: b) Design for horizontal scaling with monitoring

---

**21. Cost Optimization**
Q: Which strategy will give the MOST cost savings initially?
a) Reserved Instances
b) Spot Instances
c) Right-sizing based on monitoring
d) S3 lifecycle policies

**Answer**: c) Right-sizing based on monitoring (most immediate impact for a new deployment)

---

**22. Disaster Recovery**
Q: What's the MINIMUM DR strategy for this startup?
a) Full active-passive setup
b) Backup and restore with automation
c) Pilot light in another region
d) Multi-region active-active

**Answer**: b) Backup and restore with automation (cost-effective for startup)

---

### 🏆 Expert-Level Challenges

**23. The Network Detective**
A company's AWS bill shows unexpected data transfer charges of $5,000/month. All traffic should be internal.

**Investigation Steps**:
1. Check VPC Flow Logs
2. Analyze CloudWatch metrics
3. Review NAT Gateway usage
4. Check cross-AZ traffic patterns
5. Examine application logs

Q: What's the MOST likely culprit?
a) DDoS attack
b) Misconfigured load balancer spreading traffic across all AZs
c) Applications talking to internet instead of internal services
d) Compromised instances mining cryptocurrency

**Answer**: b) Misconfigured load balancer spreading traffic across all AZs (cross-AZ data transfer charges)

---

**24. The Security Audit**
During a security audit, you discover IAM users with programmatic access keys that haven't been rotated in 2 years.

Q: What's the BEST remediation strategy?
a) Force immediate rotation for all keys
b) Implement gradual rotation with service continuity
c) Replace with IAM roles where possible, rotate remaining keys
d) Set up automatic rotation

**Answer**: c) Replace with IAM roles where possible, rotate remaining keys

---

**25. The Performance Mystery**
A web application suddenly becomes slow. CloudWatch shows:
- EC2 CPU: 15%
- RDS CPU: 80%
- Memory: Normal
- Network: Normal

Q: What's the FIRST optimization to try?
a) Scale up RDS instance
b) Implement database read replicas
c) Add ElastiCache
d) Analyze slow query logs

**Answer**: d) Analyze slow query logs (identify the root cause before throwing resources at it)

---

## Assessment Answers & Explanations

### Scoring Your Performance

**Count your correct answers:**
- **23-25**: Outstanding! Ready for architect-level challenges
- **20-22**: Strong foundation, minor gaps to address
- **17-19**: Good progress, focus on weak areas
- **15-16**: Needs improvement, additional study required
- **Below 15**: Significant review needed before proceeding

### 📈 Improvement Strategies

**If you scored 15-19:**
1. Re-read the foundation materials
2. Complete additional hands-on labs
3. Focus on scenario-based thinking
4. Practice explaining concepts out loud

**If you scored 20-22:**
1. Deep dive into areas you missed
2. Practice more complex scenarios
3. Start exploring advanced topics
4. Begin interview preparation

**If you scored 23-25:**
1. Move to Phase 2 immediately
2. Challenge yourself with real-world projects
3. Start contributing to AWS communities
4. Consider early certification attempt

---

## Phase 2 Preview Questions

To see if you're ready for intermediate topics:

**26. Auto Scaling Challenge**
Q: Your application shows CPU spikes every morning at 9 AM but current auto-scaling reacts too slowly. What's the solution?
a) Decrease cooldown periods
b) Use predictive scaling
c) Pre-scale before 9 AM
d) Use faster instance types

**Answer**: b) Use predictive scaling

**27. Database Performance**
Q: Your RDS instance is hitting connection limits during peak hours. What's the BEST solution?
a) Increase max_connections parameter
b) Implement connection pooling
c) Scale up to larger instance
d) Add read replicas

**Answer**: b) Implement connection pooling (addresses root cause efficiently)

---

## 🎯 Study Tips Based on Assessment Results

### Visual Learners
- Draw architecture diagrams for each scenario
- Use AWS Architecture Icons
- Create flowcharts for troubleshooting

### Hands-On Learners
- Build every scenario in your AWS account
- Break things intentionally to learn troubleshooting
- Document your own step-by-step guides

### Theory-Focused Learners
- Read AWS whitepapers
- Study AWS documentation thoroughly
- Create detailed notes and mind maps

### Exam-Focused Learners
- Take practice exams weekly
- Focus on explaining reasoning for answers
- Time yourself on complex scenarios

Remember: **Understanding > Memorization**. The goal is to think like a solutions architect, not just pass exams!
