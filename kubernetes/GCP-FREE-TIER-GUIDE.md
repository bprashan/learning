# 🌟 GCP Free Tier Guide for Kubernetes Learning

## 💰 **GCP Free Tier Overview**

Google Cloud Platform offers an excellent free tier for learning Kubernetes with GKE:
- **$300 USD credit** valid for 90 days
- **12 months** of free tier services
- **No automatic billing** after free trial ends
- Perfect for hands-on Kubernetes learning!

---

## 🎯 **Cost-Optimized GKE Strategy**

### **Estimated Costs for Learning**
```yaml
Recommended Learning Setup:
  Cluster: e2-micro instances (3 nodes)
  Daily Cost: ~$2-3 USD
  Monthly Cost: ~$60-90 USD
  Total for 3 months: ~$180-270 USD

Budget Breakdown:
  GKE Cluster: $50-70/month
  Persistent Storage: $5-10/month
  Load Balancers: $18/month
  Network Egress: $5-10/month
  Buffer: $20/month for experiments
```

### **Cost Optimization Tips**
```yaml
✅ Use Preemptible Nodes: 80% cost savings
✅ Auto-scaling: Scale down when not learning
✅ Regional Persistent Disks: Only when needed
✅ Delete unused resources daily
✅ Use free tier eligible services
```

---

## 🚀 **Step-by-Step Setup Guide**

### **Step 1: GCP Account Setup**

#### **Create Free Trial Account**
1. Go to [cloud.google.com](https://cloud.google.com)
2. Click "Get started for free"
3. Sign in with Google account
4. Verify identity with credit card (no charges during trial)
5. Accept terms and activate $300 credit

#### **Verify Free Tier Status**
```bash
# Check billing account
gcloud billing accounts list

# Verify free trial status in GCP Console:
# Navigation Menu → Billing → Overview
# Should show: "$300 credit remaining"
```

### **Step 2: Install Required Tools**

#### **Install Google Cloud SDK**
```powershell
# Download and run installer from:
# https://cloud.google.com/sdk/docs/install-windows

# Or use Chocolatey (if installed):
choco install gcloudsdk

# Verify installation
gcloud version
```

#### **Install kubectl**
```powershell
# Install kubectl via gcloud
gcloud components install kubectl

# Or use Chocolatey:
choco install kubernetes-cli

# Verify installation
kubectl version --client
```

#### **Install Additional Tools**
```powershell
# Install Helm (for package management)
choco install kubernetes-helm

# Install k9s (optional - great terminal UI)
choco install k9s
```

### **Step 3: Project Setup**

#### **Create New Project**
```bash
# Set variables
export PROJECT_ID="k8s-learning-$(date +%Y%m%d)"
export BILLING_ACCOUNT_ID="your-billing-account-id"

# Create project
gcloud projects create $PROJECT_ID --name="Kubernetes Learning Lab"

# Set as default project
gcloud config set project $PROJECT_ID

# Link billing account
gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID
```

#### **Enable Required APIs**
```bash
# Enable necessary APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com

# Verify enabled services
gcloud services list --enabled
```

---

## 🎛️ **Cost-Optimized GKE Cluster Configurations**

### **Configuration 1: Learning Lab (Minimal Cost)**
```bash
# Perfect for: Sections 01-06 (basics to configuration)
gcloud container clusters create k8s-learning-basic \
  --zone=us-central1-a \
  --num-nodes=2 \
  --machine-type=e2-micro \
  --disk-size=10GB \
  --disk-type=pd-standard \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=3 \
  --preemptible \
  --enable-autorepair \
  --enable-autoupgrade \
  --no-enable-cloud-logging \
  --no-enable-cloud-monitoring

# Daily cost: ~$1-2 USD
```

### **Configuration 2: Application Lab (Medium Cost)**
```bash
# Perfect for: Sections 07-10 (security, advanced topics, monitoring)
gcloud container clusters create k8s-learning-apps \
  --zone=us-central1-a \
  --num-nodes=3 \
  --machine-type=e2-small \
  --disk-size=20GB \
  --disk-type=pd-standard \
  --enable-autoscaling \
  --min-nodes=2 \
  --max-nodes=5 \
  --preemptible \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-network-policy \
  --addons=NetworkPolicy

# Daily cost: ~$3-5 USD
```

### **Configuration 3: Production Lab (Higher Cost)**
```bash
# Perfect for: Section 11 (production e-commerce platform)
gcloud container clusters create k8s-learning-prod \
  --region=us-central1 \
  --num-nodes=2 \
  --machine-type=e2-standard-2 \
  --disk-size=50GB \
  --disk-type=pd-ssd \
  --enable-autoscaling \
  --min-nodes=2 \
  --max-nodes=6 \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-network-policy \
  --enable-ip-alias \
  --addons=HorizontalPodAutoscaling,NetworkPolicy

# Daily cost: ~$8-12 USD (use only for final project)
```

---

## 📅 **3-Month Learning Schedule**

### **Month 1: Foundations ($60-80 budget)**
```yaml
Weeks 1-2: Basic Learning Cluster
  Topics: 01-basics, 02-core-concepts, 03-workloads
  Cluster: k8s-learning-basic
  Daily usage: 4-6 hours
  
Weeks 3-4: Networking & Storage
  Topics: 04-services-networking, 05-storage
  Cluster: k8s-learning-basic (upgrade disk if needed)
  Practice: Deploy sample applications

Budget Management:
  - Use cluster only during learning sessions
  - Delete cluster overnight if not needed
  - Monitor billing daily
```

### **Month 2: Advanced Topics ($80-100 budget)**
```yaml
Weeks 5-6: Configuration & Security
  Topics: 06-configuration, 07-security
  Cluster: k8s-learning-apps
  Practice: RBAC, NetworkPolicies, Secrets
  
Weeks 7-8: Advanced Features
  Topics: 08-advanced-topics, 09-monitoring-logging
  Cluster: k8s-learning-apps
  Practice: HPA, monitoring stack deployment

Budget Management:
  - Use preemptible nodes extensively
  - Clean up resources after each session
  - Snapshot important configurations
```

### **Month 3: Production Project ($100-120 budget)**
```yaml
Weeks 9-10: Sample Applications
  Topics: 10-sample-applications
  Cluster: k8s-learning-apps
  Practice: Complete 3-tier application
  
Weeks 11-12: Production E-commerce
  Topics: 11-production-ecommerce
  Cluster: k8s-learning-prod
  Practice: Master-slave DB, auto-scaling, monitoring

Budget Management:
  - Reserve budget for final project
  - Use regional cluster for HA testing
  - Document everything for portfolio
```

---

## 💡 **Daily Cost Management Scripts**

### **Cluster Management Script**
```bash
#!/bin/bash
# save as: gke-manager.sh

case $1 in
  "start")
    echo "Starting learning session..."
    gcloud container clusters resize k8s-learning-basic --num-nodes=2 --zone=us-central1-a
    echo "Cluster ready for learning!"
    ;;
  "stop")
    echo "Stopping learning session..."
    gcloud container clusters resize k8s-learning-basic --num-nodes=0 --zone=us-central1-a
    echo "Cluster scaled down to save costs!"
    ;;
  "status")
    echo "Current cluster status:"
    gcloud container clusters list
    ;;
  "cost")
    echo "Current billing information:"
    gcloud billing budgets list --billing-account=$BILLING_ACCOUNT_ID
    ;;
  *)
    echo "Usage: $0 {start|stop|status|cost}"
    ;;
esac
```

### **Daily Cleanup Script**
```bash
#!/bin/bash
# save as: daily-cleanup.sh

echo "=== Daily GCP Cleanup ==="

# Delete unused disks
echo "Checking for unused persistent disks..."
gcloud compute disks list --filter="users:(*)" --format="value(name,zone)" | \
while read disk zone; do
  if [ -z "$zone" ]; then
    echo "Deleting unused disk: $disk"
    gcloud compute disks delete $disk --quiet
  fi
done

# Delete unused load balancers
echo "Checking for unused load balancers..."
gcloud compute forwarding-rules list --format="value(name,region)" | \
while read rule region; do
  echo "Found forwarding rule: $rule in $region"
done

# Show current costs
echo "=== Current Resource Usage ==="
gcloud compute instances list
gcloud container clusters list
gcloud compute disks list

echo "Cleanup completed!"
```

---

## 📊 **Budget Monitoring & Alerts**

### **Set Up Billing Alerts**
```bash
# Create budget with alerts
gcloud billing budgets create \
  --billing-account=$BILLING_ACCOUNT_ID \
  --display-name="Kubernetes Learning Budget" \
  --budget-amount=250USD \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=75 \
  --threshold-rule=percent=90 \
  --threshold-rule=percent=100
```

### **Daily Cost Monitoring**
```bash
# Check current spending
gcloud billing projects describe $PROJECT_ID

# Get detailed billing export (set up in console)
# Navigation Menu → Billing → Billing Export
# Export to BigQuery for detailed analysis
```

### **Weekly Budget Review Script**
```bash
#!/bin/bash
# save as: weekly-budget-review.sh

echo "=== Weekly Budget Review ==="
echo "Date: $(date)"

# Get current project info
echo "Project: $(gcloud config get-value project)"

# Check running resources
echo "=== Running Resources ==="
gcloud compute instances list
gcloud container clusters list
gcloud compute disks list
gcloud sql instances list

# Estimate costs
echo "=== Cost Estimates ==="
echo "Check detailed billing in GCP Console:"
echo "https://console.cloud.google.com/billing"

# Recommendations
echo "=== Recommendations ==="
echo "1. Stop clusters when not learning"
echo "2. Use preemptible nodes"
echo "3. Delete unused persistent disks"
echo "4. Monitor network egress costs"
```

---

## 🛠️ **Learning Session Workflow**

### **Starting a Learning Session**
```bash
# 1. Start your cluster
./gke-manager.sh start

# 2. Get cluster credentials
gcloud container clusters get-credentials k8s-learning-basic --zone=us-central1-a

# 3. Verify connection
kubectl cluster-info
kubectl get nodes

# 4. Begin learning session
cd /path/to/kubernetes/learning/materials
```

### **During Learning Session**
```bash
# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check for resource leaks
kubectl get all --all-namespaces
kubectl get pv
kubectl get pvc --all-namespaces

# Practice commands from learning materials
kubectl apply -f 01-basics/
kubectl apply -f 02-core-concepts/
# ... continue with sections
```

### **Ending a Learning Session**
```bash
# 1. Clean up resources
kubectl delete --all pods --all-namespaces
kubectl delete --all services --all-namespaces
kubectl delete --all deployments --all-namespaces
kubectl delete pvc --all --all-namespaces

# 2. Scale down cluster
./gke-manager.sh stop

# 3. Run daily cleanup
./daily-cleanup.sh

# 4. Check costs
./gke-manager.sh cost
```

---

## 🎯 **Specific Learning Paths**

### **Path 1: Basic Kubernetes (Weeks 1-4)**
```bash
# Cluster configuration
CLUSTER_NAME="k8s-basic"
MACHINE_TYPE="e2-micro"
NODES=2
DAILY_COST="$1-2"

# Learning focus
Topics: [
  "01-basics: K8s architecture, kubectl basics",
  "02-core-concepts: Pods, services, namespaces",
  "03-workloads: Deployments, ReplicaSets",
  "04-services-networking: Services, Ingress basics"
]

# Practice projects
Projects: [
  "Deploy NGINX with LoadBalancer",
  "Create multi-container pods",
  "Practice kubectl commands",
  "Understand K8s architecture"
]
```

### **Path 2: Advanced Kubernetes (Weeks 5-8)**
```bash
# Cluster configuration
CLUSTER_NAME="k8s-advanced"
MACHINE_TYPE="e2-small"
NODES=3
DAILY_COST="$3-5"

# Learning focus
Topics: [
  "05-storage: PV, PVC, StorageClasses",
  "06-configuration: ConfigMaps, Secrets",
  "07-security: RBAC, NetworkPolicies",
  "08-advanced-topics: HPA, CRDs"
]

# Practice projects
Projects: [
  "Deploy databases with persistent storage",
  "Implement RBAC for microservices",
  "Configure auto-scaling applications",
  "Setup monitoring stack"
]
```

### **Path 3: Production Ready (Weeks 9-12)**
```bash
# Cluster configuration
CLUSTER_NAME="k8s-production"
MACHINE_TYPE="e2-standard-2"
NODES=3
DAILY_COST="$8-12"

# Learning focus
Topics: [
  "09-monitoring-logging: Prometheus, Grafana, ELK",
  "10-sample-applications: 3-tier application",
  "11-production-ecommerce: Master-slave architecture",
  "Interview preparation and optimization"
]

# Practice projects
Projects: [
  "Deploy complete monitoring stack",
  "Build 3-tier web application",
  "Implement master-slave database",
  "Practice disaster recovery"
]
```

---

## 🚨 **Cost Alerts & Safety Measures**

### **Emergency Budget Protection**
```bash
# Set up automatic shutdown script
# save as: emergency-shutdown.sh

#!/bin/bash
BUDGET_THRESHOLD=280  # Alert at $280 out of $300

# Check current billing (requires billing API setup)
CURRENT_SPEND=$(gcloud billing projects describe $PROJECT_ID --format="value(billingEnabled)")

if [ $CURRENT_SPEND -gt $BUDGET_THRESHOLD ]; then
  echo "BUDGET ALERT: Approaching $300 limit!"
  echo "Shutting down all resources..."
  
  # Delete all clusters
  gcloud container clusters list --format="value(name,zone)" | \
  while read name zone; do
    echo "Deleting cluster: $name in $zone"
    gcloud container clusters delete $name --zone=$zone --quiet
  done
  
  # Delete compute instances
  gcloud compute instances delete --all --quiet
  
  echo "Emergency shutdown completed!"
fi
```

### **Weekly Budget Checkpoints**
```yaml
Week 1: $20-25 spent (8-10% of budget)
Week 2: $40-50 spent (16-20% of budget)
Week 4: $80-100 spent (33% of budget)
Week 8: $160-200 spent (66% of budget)
Week 12: $250-280 spent (90% of budget)

Red Flags:
  - Spending >10% per week in Month 1
  - Spending >15% per week in Month 2
  - Any sudden cost spikes >$20/day
```

---

## 🎓 **Learning Milestones & Checkpoints**

### **Month 1 Goals**
```yaml
Technical Milestones:
  ✅ Successfully create and manage GKE clusters
  ✅ Deploy basic applications (pods, services, deployments)
  ✅ Understand Kubernetes architecture
  ✅ Master kubectl commands
  ✅ Configure basic networking

Budget Milestone:
  ✅ Stay under $80 spent
  ✅ Learn cost optimization techniques
  ✅ Establish daily cleanup routines
```

### **Month 2 Goals**
```yaml
Technical Milestones:
  ✅ Implement persistent storage solutions
  ✅ Configure RBAC and security policies
  ✅ Deploy monitoring and logging
  ✅ Practice auto-scaling configurations
  ✅ Master advanced kubectl techniques

Budget Milestone:
  ✅ Stay under $180 total spent
  ✅ Optimize resource usage patterns
  ✅ Practice production-like deployments
```

### **Month 3 Goals**
```yaml
Technical Milestones:
  ✅ Deploy complete production applications
  ✅ Implement master-slave database architecture
  ✅ Configure comprehensive monitoring
  ✅ Practice disaster recovery scenarios
  ✅ Prepare for interviews with real examples

Budget Milestone:
  ✅ Stay under $270 total spent
  ✅ Document cost optimization strategies
  ✅ Create portfolio of deployed applications
```

---

## 📚 **Resource Links & Documentation**

### **GCP Free Tier Resources**
- [GCP Free Tier Overview](https://cloud.google.com/free)
- [GKE Pricing Calculator](https://cloud.google.com/products/calculator)
- [Preemptible Instances Guide](https://cloud.google.com/compute/docs/instances/preemptible)
- [Billing Budgets and Alerts](https://cloud.google.com/billing/docs/how-to/budgets)

### **Cost Optimization Guides**
- [GKE Cost Optimization](https://cloud.google.com/kubernetes-engine/docs/how-to/cost-optimization)
- [Cluster Autoscaler](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler)
- [Node Auto Provisioning](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-provisioning)

### **Learning Resources**
- [GKE Quickstart](https://cloud.google.com/kubernetes-engine/docs/quickstart)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GCP Architecture Center](https://cloud.google.com/architecture)

---

## 🎯 **Success Tips for Free Tier Learning**

### **Maximize Learning Value**
1. **Plan learning sessions** - Don't leave clusters running overnight
2. **Use preemptible nodes** - 80% cost savings for learning
3. **Practice daily cleanup** - Delete resources after each session
4. **Monitor spending weekly** - Stay ahead of budget limits
5. **Document everything** - Create portfolio for interviews

### **Common Pitfalls to Avoid**
```yaml
❌ Leaving clusters running 24/7
❌ Using standard (non-preemptible) nodes for learning
❌ Creating multiple large clusters simultaneously
❌ Forgetting to delete persistent disks
❌ Not monitoring network egress costs
❌ Using regional clusters for basic learning

✅ Scale clusters down when not learning
✅ Use preemptible nodes for cost savings
✅ Create one cluster at a time
✅ Set up automatic cleanup scripts
✅ Monitor billing dashboard daily
✅ Start with zonal clusters for basics
```

---

## 🎉 **You're Ready to Start!**

With this guide, you can efficiently use your $300 GCP credit to master Kubernetes over 3 months. The structured approach ensures you get maximum learning value while staying within budget.

### **Quick Start Commands**
```bash
# 1. Create your first learning cluster
gcloud container clusters create k8s-learning-basic \
  --zone=us-central1-a \
  --num-nodes=2 \
  --machine-type=e2-micro \
  --preemptible

# 2. Get credentials
gcloud container clusters get-credentials k8s-learning-basic --zone=us-central1-a

# 3. Start learning!
kubectl get nodes
cd kubernetes-learning-materials
kubectl apply -f 01-basics/
```

**Happy learning and welcome to the Kubernetes journey!** 🚀

Remember: The goal isn't just to finish within budget, but to gain real, practical Kubernetes skills that will serve you throughout your DevOps career. The $300 investment in learning will pay dividends in your professional growth! 🌟
