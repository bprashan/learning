# PowerShell script for managing deployment revision history
param(
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "default",
    
    [Parameter(Mandatory=$false)]
    [string]$Action = "show"  # show, cleanup, configure
)

function Show-RevisionHistory {
    param($deployment, $ns)
    
    Write-Host "📚 Revision History for $deployment" -ForegroundColor Green
    Write-Host "=" * 50
    
    # Show current revision limit
    $revisionLimit = kubectl get deployment $deployment -n $ns -o jsonpath='{.spec.revisionHistoryLimit}'
    Write-Host "Current Revision Limit: $revisionLimit" -ForegroundColor Cyan
    
    # Show rollout history
    Write-Host "`n🔄 Rollout History:" -ForegroundColor Yellow
    kubectl rollout history deployment/$deployment -n $ns
    
    # Show ReplicaSets (these represent the actual revisions)
    Write-Host "`n📦 ReplicaSets (Physical Revisions):" -ForegroundColor Yellow
    kubectl get replicasets -l app=$deployment -n $ns -o custom-columns="NAME:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas,AGE:.metadata.creationTimestamp,IMAGES:.spec.template.spec.containers[*].image"
    
    # Show current deployment status
    Write-Host "`n📊 Current Deployment Status:" -ForegroundColor Yellow
    kubectl get deployment $deployment -n $ns -o wide
}

function Set-RevisionLimit {
    param($deployment, $ns, $limit)
    
    Write-Host "⚙️ Setting revision limit to $limit for $deployment" -ForegroundColor Green
    
    kubectl patch deployment $deployment -n $ns -p "{`"spec`":{`"revisionHistoryLimit`":$limit}}"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Revision limit updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to update revision limit!" -ForegroundColor Red
    }
}

function Cleanup-OldRevisions {
    param($deployment, $ns, $keepCount)
    
    Write-Host "🧹 Cleaning up old revisions, keeping latest $keepCount" -ForegroundColor Yellow
    
    # First, set the revision limit
    Set-RevisionLimit -deployment $deployment -ns $ns -limit $keepCount
    
    # Trigger a dummy update to force cleanup
    Write-Host "Triggering cleanup by adding annotation..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    kubectl annotate deployment $deployment -n $ns "cleanup.timestamp=$timestamp" --overwrite
    
    Write-Host "✅ Cleanup initiated. Old ReplicaSets will be removed." -ForegroundColor Green
}

function Show-DetailedRevision {
    param($deployment, $ns, $revision)
    
    Write-Host "🔍 Detailed view of revision $revision" -ForegroundColor Green
    Write-Host "=" * 50
    
    kubectl rollout history deployment/$deployment -n $ns --revision=$revision
}

# Main script logic
switch ($Action.ToLower()) {
    "show" {
        Show-RevisionHistory -deployment $DeploymentName -ns $Namespace
        
        Write-Host "`n🛠️ Available Actions:" -ForegroundColor Cyan
        Write-Host ".\revision-manager.ps1 -DeploymentName $DeploymentName -Action configure" -ForegroundColor White
        Write-Host ".\revision-manager.ps1 -DeploymentName $DeploymentName -Action cleanup" -ForegroundColor White
    }
    
    "configure" {
        $limit = Read-Host "Enter new revision history limit (current default: 2, recommended: 10-20)"
        Set-RevisionLimit -deployment $DeploymentName -ns $Namespace -limit $limit
        Show-RevisionHistory -deployment $DeploymentName -ns $Namespace
    }
    
    "cleanup" {
        $keepCount = Read-Host "How many revisions to keep? (recommended: 5-10)"
        Cleanup-OldRevisions -deployment $DeploymentName -ns $Namespace -keepCount $keepCount
    }
    
    "detail" {
        $revision = Read-Host "Enter revision number to view details"
        Show-DetailedRevision -deployment $DeploymentName -ns $Namespace -revision $revision
    }
    
    default {
        Write-Host "❌ Invalid action. Use: show, configure, cleanup, detail" -ForegroundColor Red
    }
}

# Show tips
Write-Host "`n💡 Pro Tips:" -ForegroundColor Cyan
Write-Host "• Use --record flag when updating deployments for better history" -ForegroundColor White
Write-Host "• kubectl set image deployment/$DeploymentName nginx=nginx:1.22 --record" -ForegroundColor White
Write-Host "• Higher revision limits use more storage but provide better rollback options" -ForegroundColor White
Write-Host "• In production, consider 10-20 revisions for critical applications" -ForegroundColor White
