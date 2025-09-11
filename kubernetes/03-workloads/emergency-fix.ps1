# Emergency Real-Time Kubernetes Deployment Fix Script
param(
    [Parameter(Mandatory=$false)]
    [string]$DeploymentName = "web-app-deployment",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "default"
)

Write-Host "🚨 EMERGENCY KUBERNETES DEPLOYMENT FIX" -ForegroundColor Red
Write-Host "Time: $(Get-Date)" -ForegroundColor Yellow
Write-Host "=" * 80

# Function to get pod status with colors
function Get-ColoredPodStatus {
    param($status)
    switch ($status) {
        "Running" { return @{ Color = "Green"; Status = $status } }
        "Pending" { return @{ Color = "Yellow"; Status = $status } }
        "CrashLoopBackOff" { return @{ Color = "Red"; Status = $status } }
        "Error" { return @{ Color = "Red"; Status = $status } }
        "Failed" { return @{ Color = "Red"; Status = $status } }
        default { return @{ Color = "White"; Status = $status } }
    }
}

Write-Host "🔍 STEP 1: RAPID DIAGNOSIS" -ForegroundColor Cyan
Write-Host "=" * 40

# Get current pod status
Write-Host "Current Pod Status:" -ForegroundColor Yellow
$pods = kubectl get pods -l app=web-app -o json | ConvertFrom-Json

if ($pods.items.Count -eq 0) {
    Write-Host "❌ No pods found with label app=web-app" -ForegroundColor Red
    exit 1
}

$crashingPods = @()
$pendingPods = @()
$runningPods = @()

foreach ($pod in $pods.items) {
    $podName = $pod.metadata.name
    $podStatus = $pod.status.phase
    $statusInfo = Get-ColoredPodStatus $podStatus
    
    Write-Host "  $podName - $($statusInfo.Status)" -ForegroundColor $statusInfo.Color
    
    switch ($podStatus) {
        "Failed" { $crashingPods += $podName }
        "Pending" { $pendingPods += $podName }
        "Running" { 
            # Check if containers are actually ready
            $ready = $true
            if ($pod.status.containerStatuses) {
                foreach ($container in $pod.status.containerStatuses) {
                    if (-not $container.ready) { $ready = $false }
                }
            }
            if ($ready) { $runningPods += $podName }
            else { $crashingPods += $podName }
        }
        default { $crashingPods += $podName }
    }
}

Write-Host "`nSummary:" -ForegroundColor White
Write-Host "  Running: $($runningPods.Count)" -ForegroundColor Green
Write-Host "  Crashing: $($crashingPods.Count)" -ForegroundColor Red  
Write-Host "  Pending: $($pendingPods.Count)" -ForegroundColor Yellow

Write-Host "`n🚨 STEP 2: EMERGENCY ANALYSIS" -ForegroundColor Red
Write-Host "=" * 40

# Analyze crashing pods first
if ($crashingPods.Count -gt 0) {
    Write-Host "Analyzing CRASHING pods..." -ForegroundColor Red
    
    $sampleCrashPod = $crashingPods[0]
    Write-Host "`nAnalyzing: $sampleCrashPod" -ForegroundColor Cyan
    
    # Check init container logs
    Write-Host "Init Container Logs:" -ForegroundColor Magenta
    try {
        $initLogs = kubectl logs $sampleCrashPod -c init-config 2>$null
        if ($initLogs) {
            $initLogs[-5..-1] | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        } else {
            Write-Host "  No init container logs" -ForegroundColor Red
        }
    } catch {
        Write-Host "  Cannot access init container logs" -ForegroundColor Red
    }
    
    # Check main container logs
    Write-Host "Main Container Logs:" -ForegroundColor Magenta
    try {
        $mainLogs = kubectl logs $sampleCrashPod -c web-app --tail=5 2>$null
        if ($mainLogs) {
            $mainLogs | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            
            # Look for specific nginx error
            if ($mainLogs -match "server_name.*directive.*not allowed") {
                Write-Host "`n🎯 PROBLEM IDENTIFIED: Invalid nginx configuration!" -ForegroundColor Red
                $global:problemType = "nginx-config"
            }
        } else {
            Write-Host "  No main container logs available" -ForegroundColor Red
        }
    } catch {
        Write-Host "  Cannot access main container logs" -ForegroundColor Red
    }
    
    # Check events
    Write-Host "Recent Events:" -ForegroundColor Magenta
    $events = kubectl get events --field-selector involvedObject.name=$sampleCrashPod --sort-by=.lastTimestamp --tail=3 -o custom-columns=REASON:.reason,MESSAGE:.message --no-headers 2>$null
    if ($events) {
        $events | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }
}

# Analyze pending pods
if ($pendingPods.Count -gt 0) {
    Write-Host "`nAnalyzing PENDING pods..." -ForegroundColor Yellow
    
    $samplePendingPod = $pendingPods[0]
    Write-Host "Analyzing: $samplePendingPod" -ForegroundColor Cyan
    
    # Check why pod is pending
    $podDetails = kubectl describe pod $samplePendingPod 2>$null
    $events = $podDetails | Select-String "Events:" -A 10
    
    if ($events -match "Insufficient") {
        Write-Host "🎯 PROBLEM: Resource constraints!" -ForegroundColor Red
        $global:problemType = "resources"
    } elseif ($events -match "No nodes available") {
        Write-Host "🎯 PROBLEM: No available nodes!" -ForegroundColor Red
        $global:problemType = "nodes"
    } else {
        Write-Host "Pending reason unclear, checking events..." -ForegroundColor Yellow
        $events | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }
}

Write-Host "`n⚡ STEP 3: IMMEDIATE FIX APPLICATION" -ForegroundColor Green
Write-Host "=" * 40

# Apply fix based on problem type
switch ($global:problemType) {
    "nginx-config" {
        Write-Host "🔧 Applying nginx configuration fix..." -ForegroundColor Green
        
        # Apply the corrected deployment
        kubectl apply -f deployment-advanced.yaml
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Fixed deployment applied" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to apply fix" -ForegroundColor Red
        }
        
        # Force recreation of crashing pods
        Write-Host "🗑️ Deleting crashing pods to force recreation..." -ForegroundColor Yellow
        foreach ($pod in $crashingPods) {
            Write-Host "Deleting: $pod" -ForegroundColor Cyan
            kubectl delete pod $pod --grace-period=0 --force 2>$null
        }
    }
    
    "resources" {
        Write-Host "🔧 Attempting resource constraint fix..." -ForegroundColor Green
        
        # Try to reduce resource requests
        Write-Host "Reducing resource requests..." -ForegroundColor Yellow
        kubectl patch deployment $DeploymentName -p '{
            "spec": {
                "template": {
                    "spec": {
                        "containers": [
                            {
                                "name": "web-app",
                                "resources": {
                                    "requests": {
                                        "memory": "64Mi",
                                        "cpu": "50m"
                                    }
                                }
                            }
                        ]
                    }
                }
            }
        }'
    }
    
    "nodes" {
        Write-Host "🔧 Node availability issue detected..." -ForegroundColor Yellow
        Write-Host "Checking cluster capacity..." -ForegroundColor Cyan
        
        kubectl get nodes -o wide
        kubectl describe nodes | Select-String "Allocatable:" -A 3
    }
    
    default {
        Write-Host "🔧 Applying general fix..." -ForegroundColor Green
        kubectl apply -f deployment-advanced.yaml
        
        # Delete all problematic pods
        if ($crashingPods.Count -gt 0 -or $pendingPods.Count -gt 0) {
            Write-Host "Recreating all problematic pods..." -ForegroundColor Yellow
            $allProblematicPods = $crashingPods + $pendingPods
            foreach ($pod in $allProblematicPods) {
                kubectl delete pod $pod --grace-period=0 --force 2>$null
            }
        }
    }
}

Write-Host "`n⏱️ STEP 4: REAL-TIME MONITORING" -ForegroundColor Blue
Write-Host "=" * 40

Write-Host "Monitoring recovery for 60 seconds..." -ForegroundColor Yellow
$startTime = Get-Date
$timeout = 60

do {
    $currentTime = Get-Date
    $elapsed = ($currentTime - $startTime).TotalSeconds
    
    Clear-Host
    Write-Host "🔄 REAL-TIME RECOVERY MONITOR" -ForegroundColor Green
    Write-Host "Elapsed: $([math]::Round($elapsed, 1))s / ${timeout}s" -ForegroundColor Yellow
    Write-Host "=" * 50
    
    # Get current status
    $currentPods = kubectl get pods -l app=web-app -o json | ConvertFrom-Json
    $currentRunning = 0
    $currentPending = 0
    $currentCrashing = 0
    
    foreach ($pod in $currentPods.items) {
        $podName = $pod.metadata.name
        $podStatus = $pod.status.phase
        $statusInfo = Get-ColoredPodStatus $podStatus
        
        Write-Host "Pod: $podName" -ForegroundColor White
        Write-Host "  Status: $($statusInfo.Status)" -ForegroundColor $statusInfo.Color
        
        # Check container readiness
        if ($pod.status.containerStatuses) {
            $readyContainers = ($pod.status.containerStatuses | Where-Object { $_.ready }).Count
            $totalContainers = $pod.status.containerStatuses.Count
            Write-Host "  Ready: $readyContainers/$totalContainers" -ForegroundColor $(if ($readyContainers -eq $totalContainers) { "Green" } else { "Yellow" })
            
            if ($readyContainers -eq $totalContainers -and $podStatus -eq "Running") {
                $currentRunning++
            } elseif ($podStatus -eq "Pending") {
                $currentPending++
            } else {
                $currentCrashing++
            }
        } else {
            if ($podStatus -eq "Pending") { $currentPending++ }
            else { $currentCrashing++ }
        }
        
        # Show recent events for problematic pods
        if ($podStatus -ne "Running" -or ($pod.status.containerStatuses -and ($pod.status.containerStatuses | Where-Object { -not $_.ready }).Count -gt 0)) {
            $recentEvents = kubectl get events --field-selector involvedObject.name=$podName --sort-by=.lastTimestamp --tail=1 -o custom-columns=TIME:.lastTimestamp,REASON:.reason,MESSAGE:.message --no-headers 2>$null
            if ($recentEvents) {
                Write-Host "  Event: $recentEvents" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }
    
    Write-Host "SUMMARY:" -ForegroundColor Cyan
    Write-Host "  ✅ Running & Ready: $currentRunning" -ForegroundColor Green
    Write-Host "  ⏳ Pending: $currentPending" -ForegroundColor Yellow
    Write-Host "  ❌ Crashing: $currentCrashing" -ForegroundColor Red
    
    # Check if all pods are healthy
    if ($currentRunning -eq 5 -and $currentPending -eq 0 -and $currentCrashing -eq 0) {
        Write-Host "`n🎉 SUCCESS! All pods are running and ready!" -ForegroundColor Green
        break
    }
    
    # Check deployment status
    $deploymentStatus = kubectl get deployment $DeploymentName -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' 2>$null
    Write-Host "`nDeployment Status: $deploymentStatus ready" -ForegroundColor Cyan
    
    Start-Sleep -Seconds 3
    
} while ($elapsed -lt $timeout)

Write-Host "`n📊 STEP 5: FINAL VALIDATION" -ForegroundColor Green
Write-Host "=" * 40

# Final status check
kubectl get deployment $DeploymentName -o wide
Write-Host ""
kubectl get pods -l app=web-app -o wide

# Test if we can access the application
$healthyPods = kubectl get pods -l app=web-app -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>$null
if ($healthyPods) {
    $testPod = ($healthyPods -split ' ')[0]
    Write-Host "`n🧪 Testing application on pod: $testPod" -ForegroundColor Cyan
    
    try {
        $nginxTest = kubectl exec $testPod -c web-app -- nginx -t 2>&1
        Write-Host "Nginx config test: $nginxTest" -ForegroundColor $(if ($nginxTest -match "successful") { "Green" } else { "Red" })
        
        $healthTest = kubectl exec $testPod -c web-app -- curl -s -w "%{http_code}" -o /dev/null localhost/health 2>$null
        Write-Host "Health endpoint test: $healthTest" -ForegroundColor $(if ($healthTest -eq "200") { "Green" } else { "Red" })
        
    } catch {
        Write-Host "Could not test application - pod may still be starting" -ForegroundColor Yellow
    }
}

Write-Host "`n🎯 IMMEDIATE NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Monitor pods: kubectl get pods -l app=web-app -w" -ForegroundColor White
Write-Host "2. Check logs: kubectl logs -l app=web-app -c web-app -f" -ForegroundColor White
Write-Host "3. Test locally: kubectl port-forward deployment/$DeploymentName 8080:80" -ForegroundColor White

if ($currentRunning -eq 5) {
    Write-Host "`n✅ EMERGENCY FIX SUCCESSFUL!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ PARTIAL SUCCESS - Some pods may need more time" -ForegroundColor Yellow
    Write-Host "Continue monitoring with: kubectl get pods -l app=web-app -w" -ForegroundColor White
}

Write-Host "`nScript completed at: $(Get-Date)" -ForegroundColor Cyan
