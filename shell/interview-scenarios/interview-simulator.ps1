# interview-simulator.ps1 - Interactive DevOps Interview Practice (Windows PowerShell)

$Script:Score = 0
$Script:TotalQuestions = 0

function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Red", "Green", "Yellow", "Blue", "Cyan", "White")]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Show-Header {
    Clear-Host
    Write-ColorOutput "================================" -ForegroundColor Blue
    Write-ColorOutput "  DevOps Interview Simulator    " -ForegroundColor Blue
    Write-ColorOutput "================================" -ForegroundColor Blue
    Write-Host ""
}

function Ask-Question {
    param(
        [string]$Question,
        [string]$ExpectedCmd,
        [string]$Explanation
    )
    
    $Script:TotalQuestions++
    
    Write-ColorOutput "Scenario $($Script:TotalQuestions):" -ForegroundColor Yellow
    Write-Host $Question
    Write-Host ""
    Write-ColorOutput "Your command:" -ForegroundColor Blue
    $UserAnswer = Read-Host
    
    if ($UserAnswer -like "*$ExpectedCmd*") {
        Write-ColorOutput "✅ Correct!" -ForegroundColor Green
        $Script:Score++
    } else {
        Write-ColorOutput "❌ Incorrect" -ForegroundColor Red
        Write-ColorOutput "Expected command: $ExpectedCmd" -ForegroundColor Green
    }
    
    Write-ColorOutput "Explanation: $Explanation" -ForegroundColor Blue
    Write-Host ""
    Read-Host "Press Enter to continue..."
    Write-Host ""
}

function Test-DiskSpaceScenario {
    Show-Header
    Write-ColorOutput "🚨 EMERGENCY: Production server at 98% disk usage!" -ForegroundColor Red
    Write-Host ""
    
    Ask-Question `
        "Q1: How do you quickly check disk space usage on all mounted filesystems?" `
        "Get-WmiObject -Class Win32_LogicalDisk" `
        "In PowerShell: Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID,Size,FreeSpace. In Linux: df -h"
    
    Ask-Question `
        "Q2: How do you find the largest files in a directory?" `
        "Get-ChildItem -Recurse" `
        "PowerShell: Get-ChildItem -Recurse | Sort-Object Length -Descending | Select-Object -First 10. Linux: find . -type f -exec ls -lh {} \; | sort -k5 -rh"
    
    Ask-Question `
        "Q3: How do you check running processes that might be using disk space?" `
        "Get-Process" `
        "PowerShell: Get-Process | Sort-Object WorkingSet -Descending. Linux: ps aux --sort=-%mem"
}

function Test-HighLoadScenario {
    Show-Header
    Write-ColorOutput "🚨 EMERGENCY: High CPU usage detected!" -ForegroundColor Red
    Write-Host ""
    
    Ask-Question `
        "Q1: How do you check current CPU usage by processes?" `
        "Get-Process" `
        "PowerShell: Get-Process | Sort-Object CPU -Descending. Linux: ps aux --sort=-%cpu"
    
    Ask-Question `
        "Q2: How do you monitor real-time performance?" `
        "Get-Counter" `
        "PowerShell: Get-Counter '\Processor(_Total)\% Processor Time'. Linux: top or htop"
    
    Ask-Question `
        "Q3: How do you check memory usage?" `
        "Get-WmiObject Win32_OperatingSystem" `
        "PowerShell: Get-WmiObject Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory. Linux: free -h"
}

function Test-NetworkScenario {
    Show-Header
    Write-ColorOutput "🚨 NETWORK ISSUE: Users can't access the website!" -ForegroundColor Red
    Write-Host ""
    
    Ask-Question `
        "Q1: How do you test network connectivity to a server?" `
        "Test-NetConnection" `
        "PowerShell: Test-NetConnection hostname -Port 80. Linux: telnet hostname 80 or nc -zv hostname 80"
    
    Ask-Question `
        "Q2: How do you check which processes are listening on ports?" `
        "Get-NetTCPConnection" `
        "PowerShell: Get-NetTCPConnection -State Listen. Linux: netstat -tulpn or ss -tulpn"
    
    Ask-Question `
        "Q3: How do you trace network route to a destination?" `
        "Test-NetConnection -TraceRoute" `
        "PowerShell: Test-NetConnection hostname -TraceRoute. Linux: traceroute hostname"
}

function Test-DockerScenario {
    Show-Header
    Write-ColorOutput "🚨 CONTAINER ISSUE: Application container won't start!" -ForegroundColor Red
    Write-Host ""
    
    Ask-Question `
        "Q1: How do you check running and stopped containers?" `
        "docker ps -a" `
        "docker ps -a shows all containers including stopped ones. docker ps shows only running containers."
    
    Ask-Question `
        "Q2: How do you check container logs?" `
        "docker logs" `
        "docker logs container_name shows container output. Use -f to follow logs in real-time."
    
    Ask-Question `
        "Q3: How do you inspect container configuration?" `
        "docker inspect" `
        "docker inspect container_name shows detailed configuration including environment variables, volumes, and network settings."
}

function Test-KubernetesScenario {
    Show-Header
    Write-ColorOutput "🚨 K8S ISSUE: Pod stuck in CrashLoopBackOff!" -ForegroundColor Red
    Write-Host ""
    
    Ask-Question `
        "Q1: How do you check pod status and events?" `
        "kubectl describe pod" `
        "kubectl describe pod pod_name shows detailed status, events, and troubleshooting information."
    
    Ask-Question `
        "Q2: How do you check logs from a crashed container?" `
        "kubectl logs --previous" `
        "kubectl logs pod_name --previous shows logs from the previous container instance before it crashed."
    
    Ask-Question `
        "Q3: How do you check cluster events?" `
        "kubectl get events" `
        "kubectl get events shows cluster-wide events that might explain pod issues."
}

function Show-Results {
    Show-Header
    Write-ColorOutput "🎯 Interview Simulation Complete!" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Score: " -NoNewline
    Write-ColorOutput "$($Script:Score)" -ForegroundColor Green -NoNewline
    Write-Host " out of " -NoNewline
    Write-ColorOutput "$($Script:TotalQuestions)" -ForegroundColor Blue
    
    $Percentage = [math]::Round(($Script:Score * 100 / $Script:TotalQuestions), 0)
    
    if ($Percentage -ge 80) {
        Write-ColorOutput "🎉 Excellent! You're ready for senior DevOps interviews!" -ForegroundColor Green
    } elseif ($Percentage -ge 60) {
        Write-ColorOutput "👍 Good job! Review the areas you missed and practice more." -ForegroundColor Yellow
    } else {
        Write-ColorOutput "📚 Keep studying! Focus on hands-on practice with these commands." -ForegroundColor Red
    }
    
    Write-Host ""
    Write-ColorOutput "📖 Study Recommendations:" -ForegroundColor Blue
    Write-Host "1. Practice these commands on real systems"
    Write-Host "2. Set up lab environments to simulate these scenarios"
    Write-Host "3. Review the explanation guides in each section"
    Write-Host "4. Time yourself - interviews have time pressure!"
    Write-Host ""
}

function Show-MainMenu {
    while ($true) {
        Show-Header
        Write-ColorOutput "Choose a scenario to practice:" -ForegroundColor Blue
        Write-Host ""
        Write-Host "1. 💾 Disk Space Emergency"
        Write-Host "2. 🔥 High Load Average Crisis"
        Write-Host "3. 🌐 Network Connectivity Issues"
        Write-Host "4. 🐳 Docker Container Problems"
        Write-Host "5. ☸️  Kubernetes Pod Issues"
        Write-Host "6. 🎯 Full Interview Simulation"
        Write-Host "7. 📊 Exit"
        Write-Host ""
        Write-ColorOutput "Enter your choice (1-7):" -ForegroundColor Yellow
        $Choice = Read-Host
        
        switch ($Choice) {
            "1" { Test-DiskSpaceScenario }
            "2" { Test-HighLoadScenario }
            "3" { Test-NetworkScenario }
            "4" { Test-DockerScenario }
            "5" { Test-KubernetesScenario }
            "6" { 
                Test-DiskSpaceScenario
                Test-HighLoadScenario
                Test-NetworkScenario
                Test-DockerScenario
                Test-KubernetesScenario
                Show-Results
            }
            "7" { 
                Write-ColorOutput "Good luck with your interviews!" -ForegroundColor Green
                return
            }
            default { 
                Write-ColorOutput "Invalid choice. Please try again." -ForegroundColor Red
                Read-Host "Press Enter to continue..."
            }
        }
    }
}

# Initialize and start the simulator
$Script:Score = 0
$Script:TotalQuestions = 0
Show-MainMenu
