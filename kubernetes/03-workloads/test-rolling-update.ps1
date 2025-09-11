# PowerShell script to test rolling updates
Write-Host "🚀 Kubernetes Rolling Update Test Scenario" -ForegroundColor Green
Write-Host "=" * 50

$deploymentName = "nginx-deployment"
$namespace = "default"

Write-Host "📋 Test Plan:" -ForegroundColor Cyan
Write-Host "1. Deploy initial nginx:1.21" -ForegroundColor White
Write-Host "2. Verify initial deployment" -ForegroundColor White  
Write-Host "3. Update to nginx:1.22" -ForegroundColor White
Write-Host "4. Monitor rolling update" -ForegroundColor White
Write-Host "5. Verify update completion" -ForegroundColor White
Write-Host "6. Test rollback scenario" -ForegroundColor White
Write-Host ""

# Step 1: Deploy initial version
Write-Host "Step 1: Deploying initial version..." -ForegroundColor Yellow
kubectl apply -f deployment-simple.yaml

# Wait for initial deployment
Write-Host "Waiting for initial deployment to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/$deploymentName --timeout=300s

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Initial deployment successful!" -ForegroundColor Green
} else {
    Write-Host "❌ Initial deployment failed!" -ForegroundColor Red
    exit 1
}

# Step 2: Show initial state
Write-Host "`nStep 2: Initial deployment state:" -ForegroundColor Yellow
kubectl get pods -l app=nginx -o wide
kubectl describe deployment $deploymentName | Select-String -Pattern "Image:|Replicas:"

# Step 3: Trigger rolling update
Write-Host "`nStep 3: Triggering rolling update to nginx:1.22..." -ForegroundColor Yellow
kubectl set image deployment/$deploymentName nginx=nginx:1.22

Write-Host "Rolling update triggered! Use the following commands to monitor:" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Monitor rollout status:" -ForegroundColor Green
Write-Host "kubectl rollout status deployment/$deploymentName --watch" -ForegroundColor White
Write-Host ""
Write-Host "# Watch pods in real-time:" -ForegroundColor Green  
Write-Host "kubectl get pods -l app=nginx -w" -ForegroundColor White
Write-Host ""
Write-Host "# Monitor with custom script:" -ForegroundColor Green
Write-Host ".\monitor-rollout.ps1 -DeploymentName $deploymentName" -ForegroundColor White
Write-Host ""

# Verification commands
Write-Host "🔍 Verification Commands:" -ForegroundColor Cyan
Write-Host "kubectl rollout history deployment/$deploymentName" -ForegroundColor White
Write-Host "kubectl get replicasets -l app=nginx" -ForegroundColor White
Write-Host "kubectl describe deployment $deploymentName" -ForegroundColor White
Write-Host ""

# Rollback commands
Write-Host "🔄 Rollback Commands (if needed):" -ForegroundColor Cyan
Write-Host "kubectl rollout undo deployment/$deploymentName" -ForegroundColor White
Write-Host "kubectl rollout undo deployment/$deploymentName --to-revision=1" -ForegroundColor White
Write-Host ""

Write-Host "🎯 Advanced Monitoring:" -ForegroundColor Cyan
Write-Host "kubectl get events --field-selector involvedObject.name=$deploymentName --watch" -ForegroundColor White
