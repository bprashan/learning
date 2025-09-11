# PowerShell script to validate advanced deployment
param(
    [Parameter(Mandatory=$false)]
    [string]$DeploymentName = "web-app-deployment",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "default"
)

Write-Host "🚀 Advanced Deployment Validation Script" -ForegroundColor Green
Write-Host "Deployment: $DeploymentName" -ForegroundColor Cyan
Write-Host "Namespace: $Namespace" -ForegroundColor Cyan
Write-Host "=" * 60

# Function to check command availability
function Test-Command {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Check prerequisites
if (!(Test-Command "kubectl")) {
    Write-Host "❌ kubectl not found. Please install kubectl first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ kubectl found" -ForegroundColor Green

# Step 1: Deploy the advanced deployment
Write-Host "`n📦 Step 1: Deploying Advanced Application..." -ForegroundColor Yellow
kubectl apply -f deployment-advanced.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment applied successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}

# Step 2: Wait for rollout
Write-Host "`n⏳ Step 2: Waiting for deployment to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/$DeploymentName --timeout=300s

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment rolled out successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Deployment rollout failed or timed out" -ForegroundColor Red
}

# Step 3: Check pod status
Write-Host "`n🎯 Step 3: Checking Pod Status..." -ForegroundColor Yellow
$pods = kubectl get pods -l app=web-app -o json | ConvertFrom-Json

Write-Host "Pods found: $($pods.items.Count)" -ForegroundColor Cyan

foreach ($pod in $pods.items) {
    $podName = $pod.metadata.name
    $podStatus = $pod.status.phase
    $initContainers = $pod.status.initContainerStatuses
    $containers = $pod.status.containerStatuses
    
    Write-Host "`nPod: $podName" -ForegroundColor White
    Write-Host "  Status: $podStatus" -ForegroundColor $(if ($podStatus -eq "Running") { "Green" } else { "Red" })
    
    # Check init containers
    if ($initContainers) {
        Write-Host "  Init Containers:" -ForegroundColor Cyan
        foreach ($initContainer in $initContainers) {
            $name = $initContainer.name
            $ready = $initContainer.ready
            $restarts = $initContainer.restartCount
            Write-Host "    $name - Ready: $ready, Restarts: $restarts" -ForegroundColor White
        }
    }
    
    # Check main containers
    if ($containers) {
        Write-Host "  Main Containers:" -ForegroundColor Cyan
        foreach ($container in $containers) {
            $name = $container.name
            $ready = $container.ready
            $restarts = $container.restartCount
            $state = if ($container.state.running) { "Running" } elseif ($container.state.waiting) { "Waiting" } else { "Terminated" }
            Write-Host "    $name - Ready: $ready, State: $state, Restarts: $restarts" -ForegroundColor White
        }
    }
}

# Step 4: Validate init container execution
Write-Host "`n🔧 Step 4: Validating Init Container Execution..." -ForegroundColor Yellow

$firstPod = kubectl get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}'
if ($firstPod) {
    Write-Host "Checking init container logs for pod: $firstPod" -ForegroundColor Cyan
    
    try {
        $initLogs = kubectl logs $firstPod -c init-config
        Write-Host "Init Container Logs:" -ForegroundColor Green
        $initLogs | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        
        if ($initLogs -match "Configuration complete!") {
            Write-Host "✅ Init container completed successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Init container may not have completed properly" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Could not retrieve init container logs" -ForegroundColor Red
    }
}

# Step 5: Validate shared volume configuration
Write-Host "`n📁 Step 5: Validating Shared Volume Configuration..." -ForegroundColor Yellow

if ($firstPod) {
    try {
        Write-Host "Checking shared configuration file..." -ForegroundColor Cyan
        $configFiles = kubectl exec $firstPod -c web-app -- ls -la /etc/nginx/conf.d/
        Write-Host "Configuration directory contents:" -ForegroundColor Green
        $configFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        
        $configContent = kubectl exec $firstPod -c web-app -- cat /etc/nginx/conf.d/nginx.conf
        Write-Host "`nConfiguration file content:" -ForegroundColor Green
        $configContent | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        
        if ($configContent -match "server_name web-app") {
            Write-Host "✅ Shared configuration created successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Configuration content unexpected" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Could not validate shared configuration" -ForegroundColor Red
    }
}

# Step 6: Test multi-container communication
Write-Host "`n🔗 Step 6: Testing Multi-Container Setup..." -ForegroundColor Yellow

if ($firstPod) {
    try {
        Write-Host "Testing web application endpoint..." -ForegroundColor Cyan
        $webResponse = kubectl exec $firstPod -c web-app -- curl -s -o /dev/null -w "%{http_code}" localhost/
        Write-Host "Web app HTTP response code: $webResponse" -ForegroundColor $(if ($webResponse -eq "200") { "Green" } else { "Red" })
        
        Write-Host "Testing monitoring endpoint..." -ForegroundColor Cyan
        $metricsResponse = kubectl exec $firstPod -c monitoring-agent -- curl -s -o /dev/null -w "%{http_code}" localhost:9100/metrics
        Write-Host "Metrics HTTP response code: $metricsResponse" -ForegroundColor $(if ($metricsResponse -eq "200") { "Green" } else { "Red" })
        
        if ($webResponse -eq "200" -and $metricsResponse -eq "200") {
            Write-Host "✅ Both containers responding correctly" -ForegroundColor Green
        } else {
            Write-Host "⚠️ One or more containers not responding properly" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Could not test container endpoints" -ForegroundColor Red
    }
}

# Step 7: Check resource usage
Write-Host "`n💾 Step 7: Checking Resource Usage..." -ForegroundColor Yellow

try {
    $resourceUsage = kubectl top pods -l app=web-app --no-headers
    if ($resourceUsage) {
        Write-Host "Current resource usage:" -ForegroundColor Green
        Write-Host "NAME`t`t`tCPU`tMEMORY" -ForegroundColor Cyan
        $resourceUsage | ForEach-Object { Write-Host "$_" -ForegroundColor White }
    } else {
        Write-Host "⚠️ Resource metrics not available (metrics-server may not be installed)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Could not retrieve resource usage" -ForegroundColor Yellow
}

# Step 8: Validate health probes
Write-Host "`n🏥 Step 8: Validating Health Probes..." -ForegroundColor Yellow

if ($firstPod) {
    try {
        $podDetails = kubectl describe pod $firstPod
        $livenessStatus = $podDetails | Select-String "Liveness:" -A 5
        $readinessStatus = $podDetails | Select-String "Readiness:" -A 5
        
        Write-Host "Health probe status:" -ForegroundColor Green
        if ($livenessStatus) {
            Write-Host "Liveness Probe: Configured" -ForegroundColor Green
        }
        if ($readinessStatus) {
            Write-Host "Readiness Probe: Configured" -ForegroundColor Green
        }
        
        # Check conditions
        $conditions = kubectl get pod $firstPod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
        if ($conditions -eq "True") {
            Write-Host "✅ Pod is ready and healthy" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Pod may not be ready" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Could not validate health probes" -ForegroundColor Red
    }
}

# Step 9: Service connectivity test
Write-Host "`n🌐 Step 9: Testing Service Connectivity..." -ForegroundColor Yellow

try {
    $service = kubectl get service -l app=web-app -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($service) {
        Write-Host "Service found: $service" -ForegroundColor Green
        $endpoints = kubectl get endpoints $service -o jsonpath='{.subsets[*].addresses[*].ip}'
        Write-Host "Service endpoints: $endpoints" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ No service found for this deployment" -ForegroundColor Yellow
        Write-Host "💡 You may want to create a service to expose the deployment" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠️ Could not check service connectivity" -ForegroundColor Yellow
}

# Summary
Write-Host "`n📊 Validation Summary" -ForegroundColor Green
Write-Host "=" * 60

$summary = @()
$summary += "Deployment Status: $(if ((kubectl get deployment $DeploymentName -o jsonpath='{.status.readyReplicas}') -eq (kubectl get deployment $DeploymentName -o jsonpath='{.spec.replicas}')) { '✅ Ready' } else { '❌ Not Ready' })"
$summary += "Init Containers: $(if ($initLogs -match 'Configuration complete!') { '✅ Completed' } else { '⚠️ Check logs' })"
$summary += "Multi-Container: $(if ($webResponse -eq '200' -and $metricsResponse -eq '200') { '✅ Working' } else { '⚠️ Issues detected' })"
$summary += "Health Probes: $(if ($conditions -eq 'True') { '✅ Healthy' } else { '⚠️ Check status' })"

$summary | ForEach-Object { Write-Host $_ }

Write-Host "`n🛠️ Next Steps:" -ForegroundColor Cyan
Write-Host "1. Create a service to expose the deployment" -ForegroundColor White
Write-Host "2. Set up ingress for external access" -ForegroundColor White
Write-Host "3. Monitor application logs and metrics" -ForegroundColor White
Write-Host "4. Test rolling updates" -ForegroundColor White

Write-Host "`n🎯 Useful Commands:" -ForegroundColor Cyan
Write-Host "kubectl logs -l app=web-app -c web-app --follow" -ForegroundColor White
Write-Host "kubectl logs -l app=web-app -c monitoring-agent --follow" -ForegroundColor White
Write-Host "kubectl port-forward deployment/$DeploymentName 8080:80" -ForegroundColor White
Write-Host "kubectl port-forward deployment/$DeploymentName 9100:9100" -ForegroundColor White

Write-Host "`n✅ Validation Complete!" -ForegroundColor Green
