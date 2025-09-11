# PowerShell script to monitor Kubernetes rolling updates
param(
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "default"
)

Write-Host "🔄 Monitoring Rolling Update for deployment: $DeploymentName" -ForegroundColor Green
Write-Host "📍 Namespace: $Namespace" -ForegroundColor Blue
Write-Host "⏰ Started at: $(Get-Date)" -ForegroundColor Yellow
Write-Host "=" * 80

# Function to get deployment status
function Get-DeploymentStatus {
    $status = kubectl get deployment $DeploymentName -n $Namespace -o jsonpath='{.status.conditions[?(@.type=="Progressing")].status}'
    $reason = kubectl get deployment $DeploymentName -n $Namespace -o jsonpath='{.status.conditions[?(@.type=="Progressing")].reason}'
    $replicas = kubectl get deployment $DeploymentName -n $Namespace -o jsonpath='{.status.replicas}'
    $ready = kubectl get deployment $DeploymentName -n $Namespace -o jsonpath='{.status.readyReplicas}'
    $updated = kubectl get deployment $DeploymentName -n $Namespace -o jsonpath='{.status.updatedReplicas}'
    
    return @{
        Status = $status
        Reason = $reason
        Replicas = $replicas
        Ready = $ready
        Updated = $updated
    }
}

# Function to get pod information
function Get-PodInfo {
    kubectl get pods -l app=$DeploymentName -n $Namespace -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[0].ready,IMAGE:.spec.containers[0].image,NODE:.spec.nodeName,AGE:.metadata.creationTimestamp" --no-headers
}

# Monitor loop
$iteration = 0
do {
    $iteration++
    Clear-Host
    
    Write-Host "🔄 Rolling Update Monitor - Iteration $iteration" -ForegroundColor Green
    Write-Host "⏰ Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Yellow
    Write-Host "=" * 80
    
    # Get deployment status
    $status = Get-DeploymentStatus
    Write-Host "📊 Deployment Status:" -ForegroundColor Cyan
    Write-Host "   Status: $($status.Status)" -ForegroundColor White
    Write-Host "   Reason: $($status.Reason)" -ForegroundColor White
    Write-Host "   Replicas: $($status.Replicas) | Ready: $($status.Ready) | Updated: $($status.Updated)" -ForegroundColor White
    Write-Host ""
    
    # Show pods
    Write-Host "🎯 Pod Status:" -ForegroundColor Cyan
    $pods = Get-PodInfo
    if ($pods) {
        $pods | ForEach-Object {
            $parts = $_ -split '\s+'
            $name = $parts[0]
            $podStatus = $parts[1]
            $ready = $parts[2]
            $image = $parts[3]
            $node = $parts[4]
            
            # Color coding based on status
            $color = switch ($podStatus) {
                "Running" { "Green" }
                "Pending" { "Yellow" }
                "ContainerCreating" { "Yellow" }
                "Terminating" { "Red" }
                default { "White" }
            }
            
            Write-Host "   $name | $podStatus | Ready: $ready | $image | Node: $node" -ForegroundColor $color
        }
    }
    
    Write-Host ""
    Write-Host "=" * 80
    
    # Check if rollout is complete
    $rolloutStatus = kubectl rollout status deployment/$DeploymentName -n $Namespace --timeout=1s 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Rolling update completed successfully!" -ForegroundColor Green
        break
    }
    
    Start-Sleep -Seconds 2
    
} while ($true)

Write-Host "🎉 Monitoring completed at: $(Get-Date)" -ForegroundColor Green
