# 🎯 Quick Setup Script for GKE

# This script helps you set up your GKE cluster and deploy the learning examples

# Prerequisites Check
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check if gcloud is installed
if (!(Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Google Cloud SDK not found. Please install from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Red
    exit 1
}

# Check if kubectl is installed  
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl not found. Please install kubectl" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites check passed!" -ForegroundColor Green

# Configuration Variables
$PROJECT_ID = Read-Host "Enter your GCP Project ID"
$CLUSTER_NAME = "k8s-learning-cluster"
$ZONE = "us-central1-a"
$NODE_COUNT = 3
$MACHINE_TYPE = "e2-standard-2"

Write-Host "🚀 Setting up GKE cluster with the following configuration:" -ForegroundColor Cyan
Write-Host "  Project: $PROJECT_ID" -ForegroundColor White
Write-Host "  Cluster: $CLUSTER_NAME" -ForegroundColor White
Write-Host "  Zone: $ZONE" -ForegroundColor White
Write-Host "  Nodes: $NODE_COUNT" -ForegroundColor White
Write-Host "  Machine Type: $MACHINE_TYPE" -ForegroundColor White

$confirm = Read-Host "Proceed with cluster creation? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "❌ Setup cancelled" -ForegroundColor Red
    exit 0
}

# Set the project
Write-Host "📝 Setting GCP project..." -ForegroundColor Yellow
gcloud config set project $PROJECT_ID

# Enable required APIs
Write-Host "🔌 Enabling required APIs..." -ForegroundColor Yellow
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com

# Create GKE cluster
Write-Host "🏗️ Creating GKE cluster (this may take 5-10 minutes)..." -ForegroundColor Yellow
gcloud container clusters create $CLUSTER_NAME `
    --zone=$ZONE `
    --num-nodes=$NODE_COUNT `
    --machine-type=$MACHINE_TYPE `
    --enable-autorepair `
    --enable-autoupgrade `
    --enable-autoscaling `
    --min-nodes=1 `
    --max-nodes=5 `
    --disk-size=50GB `
    --enable-ip-alias `
    --enable-network-policy

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create cluster" -ForegroundColor Red
    exit 1
}

# Get cluster credentials
Write-Host "🔑 Getting cluster credentials..." -ForegroundColor Yellow
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# Verify cluster connection
Write-Host "✅ Verifying cluster connection..." -ForegroundColor Yellow
kubectl cluster-info
kubectl get nodes

Write-Host "🎉 GKE cluster setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📚 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Explore the learning materials in each folder" -ForegroundColor White
Write-Host "2. Start with 01-basics and work your way up" -ForegroundColor White
Write-Host "3. Deploy the 3-tier application in 10-sample-applications" -ForegroundColor White
Write-Host "4. Set up monitoring with the examples in 09-monitoring-logging" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Happy Kubernetes learning!" -ForegroundColor Green
