# Domain Registration for AWS Route 53 Learning & Resume Hosting

> **🎯 Goal**: Find the most cost-effective domain for learning Route 53 and hosting your professional resume.

## 💰 Cheapest Domain Options

### 1. **AWS Route 53 Domain Registration Pricing** (Annual)

#### Ultra-Cheap Options ($3-12/year)
- **.tk** (Tokelau) - $5/year - Good for learning
- **.ml** (Mali) - $7/year - Decent for experiments
- **.ga** (Gabon) - $7/year - Learning purposes
- **.cf** (Central African Republic) - $9/year
- **.xyz** - $12/year - Professional enough for resume

#### Budget-Friendly Professional Options ($12-15/year)
- **.com** - $12/year (first year, then $13/year)
- **.net** - $11/year (first year, then $13/year)  
- **.org** - $12/year (first year, then $13/year)
- **.info** - $11/year
- **.biz** - $14/year

#### Developer/Tech-Focused Domains ($15-25/year)
- **.dev** - $15/year - Perfect for developers
- **.tech** - $18/year - Tech professional image
- **.io** - $35/year - Popular with developers (expensive)
- **.cloud** - $20/year - Cloud architect theme

### 📊 **Cost Comparison for 1 Year**

| Domain Type | Registration | Route 53 Hosting | SSL Certificate | Total Year 1 |
|-------------|-------------|------------------|-----------------|---------------|
| .tk         | $5          | $6 (hosted zone) | Free (ACM)      | **$11**       |
| .xyz        | $12         | $6               | Free (ACM)      | **$18**       |
| .com        | $12         | $6               | Free (ACM)      | **$18**       |
| .dev        | $15         | $6               | Free (ACM)      | **$21**       |

## 🏆 **My Recommendations**

### **For Learning & Experiments**
**Option 1: .xyz domain** - `yourname.xyz`
- **Cost**: $18/year total
- **Pros**: Cheap, modern, professional enough
- **Cons**: Not as recognizable as .com
- **Perfect for**: Learning Route 53, hosting resume

### **For Professional Resume**
**Option 2: .com domain** - `yourname.com` or `yourname-resume.com`
- **Cost**: $18/year total  
- **Pros**: Most professional, universally recognized
- **Cons**: Slightly more expensive, popular names taken
- **Perfect for**: Professional online presence

### **For DevOps Professional**
**Option 3: .dev domain** - `yourname.dev`
- **Cost**: $21/year total
- **Pros**: Developer-focused, modern, Google-owned TLD
- **Cons**: Slightly more expensive
- **Perfect for**: DevOps/Cloud engineer branding

## 🚀 **Domain Name Suggestions for You**

Based on your profile (Senior DevOps Engineer):

### Personal Branding Options
```
bprashan.xyz          - $12/year
bprashan.dev          - $15/year  
bprashan.cloud        - $20/year
bprashan-devops.com   - $12/year
bprashan-aws.com      - $12/year
```

### Professional Resume Sites
```
prashanresume.xyz     - $12/year
bprashan-cv.com       - $12/year
prashandevops.dev     - $15/year
bprashan-portfolio.xyz - $12/year
```

## 🛒 **Where to Buy Domains**

### **Option 1: AWS Route 53 (Recommended)**
**Pros**:
- Seamless integration with AWS services
- Automatic DNS management
- No transfer needed
- Built-in health checks

**Steps**:
1. Go to Route 53 Console
2. Click "Register Domain"
3. Search for available names
4. Complete registration

### **Option 2: Third-Party + Transfer**
**Pros**: Often cheaper initial registration
**Cons**: Transfer complexity, additional steps

**Cheap Registrars**:
- **Namecheap**: Often has $0.99 first-year .com deals
- **Porkbun**: Competitive pricing, no hidden fees
- **Google Domains**: Simple interface, fair pricing

## 💡 **Complete Setup Cost Breakdown**

### **Total Learning Environment Cost**
```
Domain Registration (.xyz):        $12/year
Route 53 Hosted Zone:             $6/year
SSL Certificate (AWS ACM):         FREE
S3 Static Website Hosting:         $1-3/year
CloudFront CDN:                    $1-5/year
──────────────────────────────────────────
Total Annual Cost:                 $20-26/year
Monthly Cost:                      $1.67-2.17/month
```

### **What You Get**:
- Professional domain name
- Global DNS with Route 53
- SSL-secured website
- CDN for fast loading
- Learning environment for AWS services

## 🎯 **My Specific Recommendation for You**

**Go with `bprashan.xyz` for $12/year**

**Why This Choice**:
1. **Affordable**: Only $18 total first year
2. **Professional enough**: .xyz is gaining acceptance
3. **Memorable**: Your name + modern TLD
4. **Future-proof**: Can always buy .com later if needed
5. **Perfect for learning**: All Route 53 features available

## 🛠️ **Step-by-Step Setup Guide**

### Step 1: Register Domain via Route 53
```bash
# Check domain availability first
aws route53domains check-domain-availability --domain-name bprashan.xyz

# Or use the console at:
# https://console.aws.amazon.com/route53/home#DomainRegistration:
```

### Step 2: Verify Route 53 Hosted Zone Created
```bash
# List hosted zones
aws route53 list-hosted-zones

# Should show your new domain's hosted zone
```

### Step 3: Create S3 Bucket for Resume Website
```bash
# Create bucket with same name as domain
aws s3 mb s3://bprashan.xyz

# Enable static website hosting
aws s3 website s3://bprashan.xyz --index-document index.html
```

### Step 4: Point Domain to S3
```bash
# Create alias record in Route 53
aws route53 change-resource-record-sets --hosted-zone-id YOUR_ZONE_ID --change-batch file://alias-record.json
```

### Step 5: Set up SSL with CloudFront
```bash
# Request certificate
aws acm request-certificate --domain-name bprashan.xyz --validation-method DNS
```

## 📝 **Learning Lab: Route 53 Experiments**

### **Experiment 1: Basic DNS Records**
```bash
# Create A record
# Create CNAME record  
# Create MX record (for email)
# Test with dig/nslookup
```

### **Experiment 2: Health Checks**
```bash
# Set up health check for your website
# Configure failover routing
# Test failover scenarios
```

### **Experiment 3: Geolocation Routing**
```bash
# Set up different responses by geography
# Test from different locations
```

## 🎁 **Bonus: Free Domain Alternatives**

If you want to experiment for absolutely free:

### **Free Subdomains**
- **GitHub Pages**: `username.github.io` - FREE
- **Netlify**: `sitename.netlify.app` - FREE  
- **Vercel**: `project.vercel.app` - FREE

### **Free DNS Services** (for learning)
- **Cloudflare**: Free DNS + CDN
- **AWS Route 53**: $0.50/month for hosted zone only

## 🚨 **Important Notes**

### **Domain Registration Tips**:
1. **Privacy Protection**: Usually $10-15/year extra (worth it)
2. **Auto-renewal**: Enable to avoid losing domain
3. **Lock Domain**: Prevent unauthorized transfers
4. **Backup DNS**: Consider secondary DNS provider

### **AWS Free Tier Usage**:
- Route 53: First hosted zone is $0.50/month
- S3: 5GB free storage
- CloudFront: 50GB free data transfer
- ACM: SSL certificates are completely free

## 🎯 **Action Plan**

1. **Today**: Register `bprashan.xyz` via Route 53 ($12)
2. **This Week**: Set up basic website with resume
3. **Learning**: Experiment with Route 53 features
4. **Future**: Consider upgrading to .com if needed

**Total Investment**: Less than $20 for a full year of learning and professional online presence!

Would you like me to help you with the actual domain registration process or setting up the Route 53 configuration?
