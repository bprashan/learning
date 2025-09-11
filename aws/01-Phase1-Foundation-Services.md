# Phase 1: Foundation Services (Weeks 1-3)

> **Learning Objectives**: By the end of Phase 1, you will understand AWS fundamentals, design secure VPC architectures, and implement enterprise-grade IAM strategies. This forms the bedrock for all advanced AWS solutions.

## Week 1: AWS Global Infrastructure & Core Concepts

### 🎯 Learning Goals
After completing this week, you should be able to:
- Select optimal AWS regions for any global application
- Design fault-tolerant architectures using multiple AZs
- Explain the Well-Architected Framework to stakeholders
- Make informed decisions about data placement and sovereignty

### Key Topics
1. **AWS Global Infrastructure**
   - Regions, Availability Zones, Edge Locations
   - AWS Points of Presence
   - Local Zones and Wavelength
   - Region selection criteria

2. **AWS Well-Architected Framework Pillars**
   - Operational Excellence
   - Security
   - Reliability
   - Performance Efficiency
   - Cost Optimization
   - Sustainability

3. **AWS Service Categories**
   - Compute, Storage, Database
   - Networking & Content Delivery
   - Security, Identity & Compliance
   - Management & Governance

### 🤔 Quick Knowledge Check
**Before diving deeper, test your understanding:**
1. How many AZs does AWS guarantee per region?
2. What's the difference between an Edge Location and a Regional Edge Cache?
3. Which Well-Architected pillar would you prioritize for a healthcare application?

*Answers at the end of this section*

### Important Notes

#### AWS Regions Selection Criteria
- **Latency**: Choose regions close to users
- **Cost**: Pricing varies by region (up to 30% difference)
- **Services**: Not all services available in all regions
- **Compliance**: Data sovereignty requirements
- **Disaster Recovery**: Multi-region strategies

> 💡 **Pro Tip**: Use AWS Simple Monthly Calculator to compare costs across regions before making decisions.

#### Availability Zones (AZs)
- Isolated data centers within a region
- Connected via low-latency links (<2ms latency)
- Design for fault tolerance across AZs
- Minimum 3 AZs per region (typically 3-6)

**Real-World Example**: Netflix uses multiple AZs to ensure that if one data center fails, users continue streaming without interruption.

#### Edge Locations
- CloudFront content delivery network
- 400+ edge locations globally
- Reduced latency for content delivery
- Used by CloudFront, Route 53, WAF

### 🔍 Deep Dive: Regional Edge Caches
Did you know AWS has a hierarchy of caching?
1. **Edge Locations** (smallest, most distributed)
2. **Regional Edge Caches** (intermediate layer)
3. **Origin Servers** (your actual resources)

This three-tier approach reduces origin load by up to 90%!

### Best Practices
- Always design for multiple AZs
- Consider data residency requirements
- Plan for disaster recovery across regions
- Understand service availability by region

### 🎯 Self-Assessment Questions
1. **Scenario**: You're designing for a financial services company that needs to serve customers in US and Europe. Compliance requires data to stay in respective regions. How would you architect this?

2. **Challenge**: Your application shows 200ms latency for users in Australia, but your servers are in us-east-1. What's your solution?

3. **Cost Optimization**: You need to choose between us-east-1 and eu-west-1 for a global application. What factors influence your decision?

*Think through these before moving to the assignment*

### Assignment 1.1: Infrastructure Planning
**Scenario**: Design AWS infrastructure for a global e-commerce application

**Requirements**:
1. Primary region: US East (N. Virginia)
2. Secondary region: EU West (Ireland)
3. Users in: North America, Europe, Asia Pacific
4. 99.99% availability requirement
5. Data residency compliance for EU users

**Deliverables**:
- Region selection justification
- AZ distribution strategy
- Edge location utilization plan
- Disaster recovery approach

**💭 Think Like an Architect**: 
- What happens if us-east-1 goes down completely?
- How will you handle GDPR compliance for EU users?
- What's your strategy for Asian Pacific users who are far from both regions?

### 📚 Knowledge Check Answers
1. **Minimum 3 AZs per region** (AWS guarantees at least 3, most have more)
2. **Edge Locations** cache content closer to users, **Regional Edge Caches** are intermediate caches between Edge Locations and origins
3. **Security** - Healthcare applications must prioritize patient data protection and compliance

---

## Week 2: Identity & Access Management (IAM)

### 🎯 Learning Goals
After this week, you should master:
- Designing enterprise IAM strategies
- Implementing zero-trust security models
- Troubleshooting complex permission issues
- Setting up federation for large organizations

### 🚨 Critical Security Alert
Before we start: IAM is the foundation of AWS security. A single misconfiguration can expose your entire infrastructure. Always follow the principle of least privilege!

### Key Topics
1. **IAM Fundamentals**
   - Users, Groups, Roles, Policies
   - Authentication vs Authorization
   - Principle of Least Privilege
   - Root user security

2. **IAM Policies**
   - Managed vs Inline policies
   - Policy structure (JSON)
   - Policy evaluation logic
   - Conditional access

3. **Advanced IAM Features**
   - Multi-Factor Authentication (MFA)
   - Cross-account access
   - Federation (SAML, OpenID Connect)
   - Service-linked roles

### Important Notes

#### IAM Policy Structure
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::example-bucket/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "203.0.113.0/24"
        }
      }
    }
  ]
}
```

**🔍 Policy Breakdown Challenge**: 
Can you explain what this policy does? What happens if someone tries to access this S3 bucket from a different IP address?

#### Policy Evaluation Logic
1. **Explicit Deny**: Always wins (like a bouncer saying "NO!")
2. **Explicit Allow**: Required for access (like having a valid ticket)
3. **Default Deny**: Implicit if no explicit allow (locked door by default)

**💡 Memory Trick**: Think "Deny, Allow, Default Deny" - DAD always protects his resources!

#### IAM Best Practices
- Enable MFA for all users (especially root!)
- Use roles for applications (never embed access keys)
- Rotate credentials regularly (quarterly at minimum)
- Monitor with CloudTrail (your security camera)
- Use AWS SSO for enterprise (single pane of glass)

### 🎯 Real-World Scenario
**The Great S3 Bucket Breach of 2019**: A company accidentally made their S3 bucket public, exposing 100 million customer records. How could proper IAM have prevented this?

*Think about: Bucket policies, IAM roles, least privilege, and monitoring*

### Security Considerations
- Never embed credentials in code
- Use temporary credentials when possible
- Implement defense in depth
- Regular access reviews and audits

### Assignment 1.2: IAM Security Implementation
**Scenario**: Design IAM structure for a multi-environment DevOps team

**Requirements**:
1. Development, Staging, Production environments
2. 3 DevOps engineers, 5 developers, 2 operations staff
3. Contractors need temporary access
4. Integration with existing Active Directory
5. Compliance logging requirements

**Deliverables**:
- IAM user/group structure
- Role-based access control design
- Cross-account strategy
- Federation implementation plan
- Monitoring and auditing approach

---

## Week 3: Networking - Virtual Private Cloud (VPC)

### Key Topics
1. **VPC Fundamentals**
   - CIDR blocks and IP addressing
   - Subnets (Public vs Private)
   - Route tables
   - Internet Gateway & NAT Gateway

2. **VPC Security**
   - Security Groups vs NACLs
   - VPC Flow Logs
   - AWS Shield & WAF integration

3. **Advanced Networking**
   - VPC Peering
   - Transit Gateway
   - Direct Connect
   - VPN connections

### Important Notes

#### CIDR Planning
- **10.0.0.0/16**: 65,536 IP addresses
- **10.0.0.0/24**: 256 IP addresses (251 usable)
- AWS reserves 5 IPs per subnet
- Plan for growth and multiple environments

#### Subnet Types
- **Public Subnet**: Has route to Internet Gateway
- **Private Subnet**: No direct internet access
- **Database Subnet**: Typically isolated in private subnets

#### Security Groups vs NACLs
| Feature | Security Groups | NACLs |
|---------|----------------|--------|
| Level | Instance | Subnet |
| Rules | Allow only | Allow/Deny |
| State | Stateful | Stateless |
| Evaluation | All rules | Order matters |

### Network Design Patterns
- **3-Tier Architecture**: Web, App, Database tiers
- **Multi-AZ**: Distribute across availability zones
- **Hybrid Connectivity**: On-premises integration
- **Micro-segmentation**: Granular security controls

### Assignment 1.3: VPC Network Design
**Scenario**: Design VPC architecture for a 3-tier web application

**Requirements**:
1. Web tier: Public subnets in 2 AZs
2. Application tier: Private subnets in 2 AZs
3. Database tier: Private subnets in 2 AZs
4. Bastion host for administrative access
5. NAT Gateway for outbound internet access
6. On-premises connectivity via VPN

**Deliverables**:
- VPC CIDR design (/16 network)
- Subnet allocation plan
- Route table configuration
- Security group rules
- Network ACL configuration
- NAT Gateway placement strategy

### Phase 1 Summary Assessment
**Comprehensive Assignment**: Design a complete foundational architecture

**Scenario**: Multi-tier application with the following requirements:
- Global user base (Americas, Europe, Asia)
- 3-tier architecture (Web, App, DB)
- High availability (99.99% uptime)
- Security compliance (SOC 2)
- On-premises integration
- Cost optimization focus

**Deliverables**:
1. Global infrastructure strategy
2. IAM security framework
3. Network architecture design
4. Security implementation plan
5. Cost estimation and optimization recommendations
