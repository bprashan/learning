# quick-health-check.ps1 - Rapid system health assessment for DevOps engineers (Windows)

# Color functions
function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White")]
        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Thresholds
$CPU_THRESHOLD = 80
$MEMORY_THRESHOLD = 85
$DISK_THRESHOLD = 85

function Show-Header {
    Write-ColorOutput "================================================" -ForegroundColor Blue
    Write-ColorOutput "          DevOps System Health Check           " -ForegroundColor Blue
    Write-ColorOutput "================================================" -ForegroundColor Blue
    Write-ColorOutput "Timestamp: $(Get-Date)" -ForegroundColor Cyan
    Write-ColorOutput "Hostname: $env:COMPUTERNAME" -ForegroundColor Cyan
    $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    Write-ColorOutput "Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes" -ForegroundColor Cyan
    Write-Host ""
}

function Test-SystemLoad {
    Write-ColorOutput "🔥 CPU USAGE" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    $cpu = Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average
    $cpuUsage = $cpu.Average
    
    Write-Host "CPU Usage: $cpuUsage%"
    
    if ($cpuUsage -gt $CPU_THRESHOLD) {
        Write-ColorOutput "⚠️  HIGH CPU WARNING!" -ForegroundColor Red
        Write-Host "Top CPU consumers:"
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | Format-Table Name, CPU, WorkingSet -AutoSize
    } else {
        Write-ColorOutput "✅ CPU usage is normal" -ForegroundColor Green
    }
    Write-Host ""
}

function Test-Memory {
    Write-ColorOutput "💾 MEMORY USAGE" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    $memory = Get-WmiObject Win32_OperatingSystem
    $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    $usedMemory = $totalMemory - $freeMemory
    $memoryPercent = [math]::Round(($usedMemory / $totalMemory) * 100, 0)
    
    Write-Host "Memory Usage: $memoryPercent% ($usedMemory GB / $totalMemory GB)"
    
    if ($memoryPercent -gt $MEMORY_THRESHOLD) {
        Write-ColorOutput "⚠️  HIGH MEMORY WARNING!" -ForegroundColor Red
        Write-Host "Top memory consumers:"
        Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 | Format-Table Name, WorkingSet, PagedMemorySize -AutoSize
    } else {
        Write-ColorOutput "✅ Memory usage is normal" -ForegroundColor Green
    }
    Write-Host ""
}

function Test-DiskSpace {
    Write-ColorOutput "💿 DISK SPACE" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
        $drive = $_.DeviceID
        $size = [math]::Round($_.Size / 1GB, 2)
        $freeSpace = [math]::Round($_.FreeSpace / 1GB, 2)
        $usedSpace = $size - $freeSpace
        $usagePercent = [math]::Round(($usedSpace / $size) * 100, 0)
        
        if ($usagePercent -gt $DISK_THRESHOLD) {
            Write-ColorOutput "⚠️  Drive $drive is $usagePercent% full ($usedSpace GB / $size GB)" -ForegroundColor Red
            
            # Show largest directories
            Write-Host "Largest directories on $drive"
            Get-ChildItem "$drive\" -Directory -ErrorAction SilentlyContinue | 
                ForEach-Object { 
                    $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    [PSCustomObject]@{
                        Directory = $_.Name
                        SizeGB = [math]::Round($size / 1GB, 2)
                    }
                } | Sort-Object SizeGB -Descending | Select-Object -First 5 | Format-Table -AutoSize
        } else {
            Write-ColorOutput "✅ Drive $drive usage: $usagePercent%" -ForegroundColor Green
        }
    }
    Write-Host ""
}

function Test-Network {
    Write-ColorOutput "🌐 NETWORK STATUS" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    # Check network adapters
    Write-Host "Active network adapters:"
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        Write-ColorOutput "✅ $($_.Name): $($_.LinkSpeed)" -ForegroundColor Green
    }
    
    # Test connectivity
    Write-Host "Connectivity tests:"
    if (Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet) {
        Write-ColorOutput "✅ Internet connectivity: OK" -ForegroundColor Green
    } else {
        Write-ColorOutput "❌ Internet connectivity: FAILED" -ForegroundColor Red
    }
    
    # Check listening ports
    Write-Host "Services listening on critical ports:"
    $criticalPorts = @(22, 80, 443, 3389, 1433, 5432)
    foreach ($port in $criticalPorts) {
        $listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($listener) {
            $serviceName = switch ($port) {
                22 { "SSH" }
                80 { "HTTP" }
                443 { "HTTPS" }
                3389 { "RDP" }
                1433 { "SQL Server" }
                5432 { "PostgreSQL" }
            }
            Write-ColorOutput "✅ $serviceName ($port): Running" -ForegroundColor Green
        }
    }
    Write-Host ""
}

function Test-Services {
    Write-ColorOutput "⚙️  CRITICAL SERVICES" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    # Common critical Windows services
    $services = @(
        "Spooler",
        "MSSQLSERVER", 
        "SQLSERVERAGENT",
        "W3SVC",
        "WinRM",
        "TermService",
        "Docker",
        "kubelet"
    )
    
    foreach ($service in $services) {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            if ($svc.Status -eq "Running") {
                Write-ColorOutput "✅ $service: Running" -ForegroundColor Green
            } else {
                Write-ColorOutput "❌ $service: $($svc.Status)" -ForegroundColor Red
            }
        }
    }
    Write-Host ""
}

function Test-EventLogs {
    Write-ColorOutput "📋 RECENT LOG ISSUES" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    # Check for recent errors in System log
    $errorEvents = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddHours(-1)} -ErrorAction SilentlyContinue
    if ($errorEvents) {
        Write-ColorOutput "⚠️  $($errorEvents.Count) errors in System log (last hour)" -ForegroundColor Red
        Write-Host "Recent critical errors:"
        $errorEvents | Select-Object -First 5 | Format-Table TimeCreated, Id, LevelDisplayName, Message -Wrap
    } else {
        Write-ColorOutput "✅ No critical errors in System log (last hour)" -ForegroundColor Green
    }
    
    # Check Application log
    $appErrors = Get-WinEvent -FilterHashtable @{LogName='Application'; Level=2; StartTime=(Get-Date).AddHours(-1)} -ErrorAction SilentlyContinue
    if ($appErrors) {
        Write-ColorOutput "⚠️  $($appErrors.Count) errors in Application log (last hour)" -ForegroundColor Red
    } else {
        Write-ColorOutput "✅ No critical errors in Application log (last hour)" -ForegroundColor Green
    }
    
    # Check for authentication failures
    $authFailures = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625; StartTime=(Get-Date).AddHours(-1)} -ErrorAction SilentlyContinue
    if ($authFailures -and $authFailures.Count -gt 10) {
        Write-ColorOutput "⚠️  $($authFailures.Count) authentication failures in the last hour" -ForegroundColor Red
    } else {
        Write-ColorOutput "✅ Authentication: Normal activity" -ForegroundColor Green
    }
    Write-Host ""
}

function Test-Security {
    Write-ColorOutput "🔒 SECURITY STATUS" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    # Check for administrators
    $admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
    Write-Host "Local Administrators: $($admins.Count)"
    $admins | ForEach-Object { Write-Host "  - $($_.Name)" }
    
    # Check Windows Defender status
    $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($defender) {
        if ($defender.AntivirusEnabled) {
            Write-ColorOutput "✅ Windows Defender: Enabled" -ForegroundColor Green
        } else {
            Write-ColorOutput "❌ Windows Defender: Disabled" -ForegroundColor Red
        }
        
        $lastScan = $defender.FullScanAge
        if ($lastScan -gt 7) {
            Write-ColorOutput "⚠️  Last full scan: $lastScan days ago" -ForegroundColor Yellow
        } else {
            Write-ColorOutput "✅ Last full scan: $lastScan days ago" -ForegroundColor Green
        }
    }
    
    # Check for recent failed logons
    $failedLogons = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625; StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue
    if ($failedLogons -and $failedLogons.Count -gt 20) {
        Write-ColorOutput "⚠️  $($failedLogons.Count) failed logon attempts in the last 24 hours" -ForegroundColor Red
    } else {
        Write-ColorOutput "✅ Login security: Normal" -ForegroundColor Green
    }
    Write-Host ""
}

function Test-Docker {
    Write-ColorOutput "🐳 DOCKER STATUS" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $dockerService = Get-Service -Name "*docker*" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
        if ($dockerService) {
            Write-ColorOutput "✅ Docker service: Running" -ForegroundColor Green
            
            try {
                # Container status
                $containers = docker ps -a --format "table {{.Names}}\t{{.Status}}" 2>$null
                if ($containers) {
                    $runningContainers = (docker ps --format "{{.Names}}" 2>$null | Measure-Object).Count
                    $totalContainers = (docker ps -a --format "{{.Names}}" 2>$null | Measure-Object).Count
                    Write-Host "Containers: $runningContainers running / $totalContainers total"
                    
                    # Show failed containers
                    $failedContainers = docker ps -a --filter "status=exited" --format "{{.Names}}" 2>$null
                    if ($failedContainers) {
                        Write-ColorOutput "⚠️  Failed containers:" -ForegroundColor Red
                        $failedContainers | ForEach-Object { Write-Host "  - $_" }
                    }
                }
                
                # Disk usage
                Write-Host "Docker disk usage:"
                docker system df 2>$null
            } catch {
                Write-ColorOutput "❌ Docker: Command failed" -ForegroundColor Red
            }
        } else {
            Write-ColorOutput "❌ Docker service: Stopped" -ForegroundColor Red
        }
    } else {
        Write-Host "Docker: Not installed"
    }
    Write-Host ""
}

function Show-Summary {
    Write-ColorOutput "===============================================" -ForegroundColor Magenta
    Write-ColorOutput "                 SUMMARY                      " -ForegroundColor Magenta
    Write-ColorOutput "===============================================" -ForegroundColor Magenta
    
    # Calculate basic health score
    $issues = 0
    
    # Check CPU
    $cpu = Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average
    if ($cpu.Average -gt $CPU_THRESHOLD) { $issues++ }
    
    # Check Memory
    $memory = Get-WmiObject Win32_OperatingSystem
    $memoryPercent = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 0)
    if ($memoryPercent -gt $MEMORY_THRESHOLD) { $issues++ }
    
    # Check Disk
    $highDiskUsage = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { 
        $_.DriveType -eq 3 -and (($_.Size - $_.FreeSpace) / $_.Size * 100) -gt $DISK_THRESHOLD 
    }
    if ($highDiskUsage) { $issues++ }
    
    if ($issues -eq 0) {
        Write-ColorOutput "🎉 SYSTEM STATUS: HEALTHY" -ForegroundColor Green
        Write-Host "All critical metrics are within normal ranges."
    } elseif ($issues -le 2) {
        Write-ColorOutput "⚠️  SYSTEM STATUS: WARNING" -ForegroundColor Yellow
        Write-Host "Some metrics need attention but system is stable."
    } else {
        Write-ColorOutput "🚨 SYSTEM STATUS: CRITICAL" -ForegroundColor Red
        Write-Host "Multiple issues detected. Immediate attention required."
    }
    
    Write-Host ""
    Write-Host "Quick actions available:"
    Write-Host "• View Event Logs: eventvwr"
    Write-Host "• Monitor resources: taskmgr or Get-Process"
    Write-Host "• Check disk usage: Get-WmiObject Win32_LogicalDisk"
    Write-Host "• Network monitoring: Get-NetTCPConnection"
    Write-Host ""
}

function Start-HealthCheck {
    Show-Header
    Test-SystemLoad
    Test-Memory
    Test-DiskSpace
    Test-Network
    Test-Services
    Test-EventLogs
    Test-Security
    
    # Optional components
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Test-Docker
    }
    
    Show-Summary
}

# Run the health check
Start-HealthCheck
