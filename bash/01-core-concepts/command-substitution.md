# 🔄 Command Substitution & Tokens

## 📖 Core Concepts

Command substitution allows you to capture the output of commands and use them as values in your scripts. Understanding tokens (words and operators) is crucial for parsing and manipulating command outputs effectively.

---

## 🎯 Command Substitution Fundamentals

### **1. Basic Command Substitution**
```bash
#!/bin/bash
# basic-substitution.sh - Command substitution examples

# Modern syntax (preferred)
current_date=$(date +"%Y-%m-%d")
server_uptime=$(uptime -p)
disk_usage=$(df -h / | tail -1 | awk '{print $5}')

echo "Server Report:"
echo "Date: $current_date"
echo "Uptime: $server_uptime"
echo "Root disk usage: $disk_usage"

# Legacy syntax (avoid in new scripts)
old_style=`date`
echo "Old style: $old_style"
```

### **2. Nested Command Substitution**
```bash
#!/bin/bash
# nested-substitution.sh - Complex command substitution

# Find the process using the most memory
memory_hog_pid=$(ps aux --sort=-%mem | head -2 | tail -1 | awk '{print $2}')
memory_hog_name=$(ps -p "$memory_hog_pid" -o comm= 2>/dev/null)

if [ -n "$memory_hog_name" ]; then
    echo "Memory hog: $memory_hog_name (PID: $memory_hog_pid)"
else
    echo "Could not determine memory usage leader"
fi

# Get the latest log file
latest_log=$(ls -t /var/log/*.log 2>/dev/null | head -1)
if [ -n "$latest_log" ]; then
    latest_log_size=$(stat -c%s "$latest_log" 2>/dev/null)
    echo "Latest log: $latest_log (Size: $latest_log_size bytes)"
fi
```

---

## 🛠️ DevOps Command Substitution Patterns

### **System Information Gathering**
```bash
#!/bin/bash
# system-info.sh - Comprehensive system information gathering

# Hardware information
cpu_cores=$(nproc)
total_memory=$(free -h | awk '/^Mem:/ {print $2}')
available_memory=$(free -h | awk '/^Mem:/ {print $7}')

# System information
os_version=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
kernel_version=$(uname -r)
system_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

# Network information
primary_ip=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
hostname=$(hostname -f)

# Disk information
root_usage=$(df -h / | tail -1 | awk '{print $5}')
largest_dir=$(du -sh /var/* 2>/dev/null | sort -rh | head -1)

# Generate system report
generate_system_report() {
    cat << EOF
=== SYSTEM INFORMATION REPORT ===
Generated: $(date)
Hostname: $hostname
Primary IP: $primary_ip

=== HARDWARE ===
CPU Cores: $cpu_cores
Total Memory: $total_memory
Available Memory: $available_memory
Current Load: $system_load

=== SOFTWARE ===
OS Version: $os_version
Kernel: $kernel_version

=== STORAGE ===
Root Disk Usage: $root_usage
Largest /var directory: $largest_dir

=== END REPORT ===
EOF
}

generate_system_report
```

### **Service Health Monitoring**
```bash
#!/bin/bash
# service-monitor.sh - Service health checking with command substitution

# Configuration
SERVICES=("nginx" "mysql" "redis" "docker")
ALERT_EMAIL="admin@company.com"

# Check service status
check_service_status() {
    local service="$1"
    local status=$(systemctl is-active "$service" 2>/dev/null)
    local enabled=$(systemctl is-enabled "$service" 2>/dev/null)
    
    case "$status" in
        "active")
            echo "✅ $service: Running (enabled: $enabled)"
            return 0
            ;;
        "inactive"|"failed")
            echo "❌ $service: Not running (enabled: $enabled)"
            return 1
            ;;
        *)
            echo "❓ $service: Unknown status (enabled: $enabled)"
            return 2
            ;;
    esac
}

# Get service metrics
get_service_metrics() {
    local service="$1"
    
    case "$service" in
        "nginx")
            local connections=$(ss -tuln | grep ':80\|:443' | wc -l)
            echo "  Active connections: $connections"
            ;;
        "mysql")
            local processes=$(mysqladmin processlist 2>/dev/null | wc -l)
            echo "  Active processes: $processes"
            ;;
        "docker")
            local containers=$(docker ps -q | wc -l)
            local images=$(docker images -q | wc -l)
            echo "  Running containers: $containers"
            echo "  Total images: $images"
            ;;
    esac
}

# Monitor all services
monitor_services() {
    local failed_services=()
    
    echo "=== Service Health Check $(date) ==="
    
    for service in "${SERVICES[@]}"; do
        if check_service_status "$service"; then
            get_service_metrics "$service"
        else
            failed_services+=("$service")
        fi
        echo
    done
    
    # Handle failures
    if [ ${#failed_services[@]} -gt 0 ]; then
        echo "⚠️  Failed services: ${failed_services[*]}"
        
        # Send alert (if mail is configured)
        if command -v mail >/dev/null; then
            echo "Service failures detected on $(hostname): ${failed_services[*]}" | \
                mail -s "Service Alert - $(hostname)" "$ALERT_EMAIL"
        fi
        
        return 1
    else
        echo "✅ All services are healthy"
        return 0
    fi
}

monitor_services
```

### **Log Analysis and Processing**
```bash
#!/bin/bash
# log-analyzer.sh - Advanced log analysis using command substitution

# Configuration
LOG_FILES=("/var/log/nginx/access.log" "/var/log/apache2/access.log" "/var/log/auth.log")
REPORT_HOURS=24

# Analyze web server logs
analyze_web_logs() {
    local log_file="$1"
    
    if [ ! -f "$log_file" ]; then
        echo "Log file not found: $log_file"
        return 1
    fi
    
    echo "=== Analysis: $log_file ==="
    
    # Get recent entries (last 24 hours)
    recent_entries=$(awk -v hours="$REPORT_HOURS" '
        BEGIN { 
            cmd = "date -d \"" hours " hours ago\" +%s"
            cmd | getline cutoff_time
            close(cmd)
        }
        {
            # Parse log timestamp and convert to epoch
            # This is a simplified version - adjust based on your log format
            log_time = $4
            gsub(/\[/, "", log_time)
            
            # Simple comparison for demonstration
            if (NR > 100) { # Process recent entries
                print $0
            }
        }
    ' "$log_file")
    
    # Top IP addresses
    top_ips=$(echo "$recent_entries" | awk '{print $1}' | sort | uniq -c | sort -rn | head -10)
    echo "Top 10 IP addresses:"
    echo "$top_ips"
    echo
    
    # HTTP status codes
    status_codes=$(echo "$recent_entries" | awk '{print $9}' | sort | uniq -c | sort -rn)
    echo "HTTP Status Codes:"
    echo "$status_codes"
    echo
    
    # Top requested URLs
    top_urls=$(echo "$recent_entries" | awk '{print $7}' | sort | uniq -c | sort -rn | head -10)
    echo "Top 10 Requested URLs:"
    echo "$top_urls"
    echo
}

# Analyze authentication logs
analyze_auth_logs() {
    local log_file="/var/log/auth.log"
    
    if [ ! -f "$log_file" ]; then
        echo "Auth log not found: $log_file"
        return 1
    fi
    
    echo "=== Authentication Analysis ==="
    
    # Failed SSH attempts
    failed_ssh=$(grep "Failed password" "$log_file" | grep "$(date +%b\ %d)" | wc -l)
    echo "Failed SSH attempts today: $failed_ssh"
    
    # Successful logins
    successful_logins=$(grep "Accepted password" "$log_file" | grep "$(date +%b\ %d)" | wc -l)
    echo "Successful logins today: $successful_logins"
    
    # Top failed login IPs
    failed_ips=$(grep "Failed password" "$log_file" | grep "$(date +%b\ %d)" | \
                awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | \
                sort | uniq -c | sort -rn | head -5)
    
    if [ -n "$failed_ips" ]; then
        echo "Top failed login IPs:"
        echo "$failed_ips"
    fi
    echo
}

# Generate comprehensive log report
generate_log_report() {
    local report_file="log_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== LOG ANALYSIS REPORT ==="
        echo "Generated: $(date)"
        echo "Analysis Period: Last $REPORT_HOURS hours"
        echo
        
        # Analyze each log file
        for log_file in "${LOG_FILES[@]}"; do
            if [[ "$log_file" == *"access.log"* ]]; then
                analyze_web_logs "$log_file"
            fi
        done
        
        analyze_auth_logs
        
        # System summary
        echo "=== SYSTEM SUMMARY ==="
        echo "Disk usage: $(df -h / | tail -1 | awk '{print $5}')"
        echo "Memory usage: $(free | awk 'NR==2{printf "%.0f%%", $3*100/$2}')"
        echo "Load average: $(uptime | awk -F'load average:' '{print $2}')"
        echo "Active connections: $(ss -tuln | wc -l)"
        
    } > "$report_file"
    
    echo "Report generated: $report_file"
    
    # Email report if configured
    if command -v mail >/dev/null && [ -n "$ALERT_EMAIL" ]; then
        mail -s "Log Analysis Report - $(hostname)" "$ALERT_EMAIL" < "$report_file"
    fi
}

generate_log_report
```

---

## 🔧 Token Processing & Word Splitting

### **Understanding Word Splitting**
```bash
#!/bin/bash
# word-splitting.sh - Demonstrate word splitting behavior

# Problematic: word splitting occurs
files="file1.txt file2.txt file3.txt"
for file in $files; do  # WRONG: unquoted variable
    echo "Processing: $file"
done

# Correct: prevent word splitting
files="file1.txt file2.txt file3.txt"
for file in "$files"; do  # CORRECT: quoted variable (treats as single word)
    echo "Processing: $file"
done

# Better: use arrays for multiple items
files=("file1.txt" "file2.txt" "file3.txt")
for file in "${files[@]}"; do  # BEST: proper array handling
    echo "Processing: $file"
done
```

### **Advanced Token Manipulation**
```bash
#!/bin/bash
# token-processing.sh - Advanced token processing techniques

# Process command output tokens
process_disk_info() {
    # Get disk usage information
    disk_info=$(df -h / | tail -1)
    
    # Split into tokens (be careful with spaces in paths)
    read -r filesystem size used avail use_percent mount <<< "$disk_info"
    
    echo "Filesystem: $filesystem"
    echo "Size: $size"
    echo "Used: $used"
    echo "Available: $avail"
    echo "Usage: $use_percent"
    echo "Mount point: $mount"
    
    # Extract numeric percentage
    numeric_usage=${use_percent%?}  # Remove % sign
    
    if [ "$numeric_usage" -gt 80 ]; then
        echo "⚠️  High disk usage warning!"
    fi
}

# Process CSV-like data
process_service_config() {
    local config_line="nginx,80,running,web-server,high"
    
    # Split by comma using IFS
    IFS=',' read -r service port status type priority <<< "$config_line"
    
    echo "Service Configuration:"
    echo "  Name: $service"
    echo "  Port: $port"
    echo "  Status: $status"
    echo "  Type: $type"
    echo "  Priority: $priority"
}

# Process multi-line command output
process_process_list() {
    # Get process information
    ps aux | while read -r user pid cpu mem vsz rss tty stat start time command; do
        # Skip header line
        [ "$user" = "USER" ] && continue
        
        # Filter for high CPU usage
        cpu_int=${cpu%.*}  # Get integer part of CPU usage
        if [ -n "$cpu_int" ] && [ "$cpu_int" -gt 50 ]; then
            echo "High CPU process: $command (CPU: $cpu%, PID: $pid)"
        fi
    done
}

process_disk_info
echo
process_service_config
echo
process_process_list
```

---

## 🚀 Advanced Command Substitution Patterns

### **Error Handling in Command Substitution**
```bash
#!/bin/bash
# error-handling-substitution.sh - Robust command substitution

# Safe command substitution with error handling
safe_command_substitution() {
    local command="$1"
    local output
    local exit_code
    
    # Capture both output and exit code
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "$output"
        return 0
    else
        echo "Command failed: $command" >&2
        echo "Error output: $output" >&2
        return $exit_code
    fi
}

# Example usage
if database_status=$(safe_command_substitution "systemctl is-active mysql"); then
    echo "Database status: $database_status"
else
    echo "Failed to get database status"
fi
```

### **Performance-Optimized Command Substitution**
```bash
#!/bin/bash
# performance-optimized.sh - Efficient command substitution

# Avoid multiple calls to the same command
get_system_info() {
    # Get all info in one call
    local meminfo
    meminfo=$(free -m)
    
    # Extract different values from the same output
    total_memory=$(echo "$meminfo" | awk '/^Mem:/ {print $2}')
    used_memory=$(echo "$meminfo" | awk '/^Mem:/ {print $3}')
    available_memory=$(echo "$meminfo" | awk '/^Mem:/ {print $7}')
    
    echo "Total: ${total_memory}MB, Used: ${used_memory}MB, Available: ${available_memory}MB"
}

# Use process substitution for complex pipelines
analyze_large_log() {
    local log_file="$1"
    
    # Process substitution allows complex processing without temporary files
    while read -r ip timestamp status; do
        case "$status" in
            "404") echo "Not found: $ip at $timestamp" ;;
            "500") echo "Server error: $ip at $timestamp" ;;
        esac
    done < <(awk '{print $1, $4, $9}' "$log_file" | grep -E "404|500")
}

get_system_info
```

### **Conditional Command Substitution**
```bash
#!/bin/bash
# conditional-substitution.sh - Smart command substitution

# Only run expensive commands when needed
get_detailed_info() {
    local service="$1"
    local basic_status
    
    # Quick check first
    basic_status=$(systemctl is-active "$service" 2>/dev/null)
    
    case "$basic_status" in
        "active")
            echo "✅ $service is running"
            
            # Only get detailed info if service is running
            case "$service" in
                "nginx")
                    local connections=$(ss -tuln | grep ':80\|:443' | wc -l)
                    echo "   Active connections: $connections"
                    ;;
                "mysql")
                    # Only check if mysql client is available
                    if command -v mysql >/dev/null; then
                        local processes=$(mysqladmin processlist 2>/dev/null | wc -l)
                        echo "   Database processes: $processes"
                    fi
                    ;;
            esac
            ;;
        *)
            echo "❌ $service is not running"
            ;;
    esac
}

# Example usage
for service in nginx mysql redis; do
    get_detailed_info "$service"
done
```

---

## 🔍 Debugging Command Substitution

### **Debugging Techniques**
```bash
#!/bin/bash
# debug-substitution.sh - Debug command substitution issues

# Enable debugging
set -x  # Show commands as they execute

# Debug function
debug_command() {
    local cmd="$1"
    
    echo "DEBUG: About to execute: $cmd"
    
    # Show what the command produces
    local output
    output=$(eval "$cmd" 2>&1)
    local exit_code=$?
    
    echo "DEBUG: Exit code: $exit_code"
    echo "DEBUG: Output length: ${#output}"
    echo "DEBUG: Output preview: ${output:0:100}..."
    
    if [ $exit_code -eq 0 ]; then
        echo "$output"
    else
        echo "DEBUG: Command failed!" >&2
        return $exit_code
    fi
}

# Turn off debugging
set +x

# Example usage
debug_command "df -h /"
```

---

## 🎯 Common Pitfalls & Solutions

### **❌ Common Mistakes**
```bash
# WRONG: Unquoted variable with spaces
files=$(find /tmp -name "*.log")
for file in $files; do  # Will break on files with spaces
    echo "$file"
done

# WRONG: Not handling command failures
count=$(grep "error" /nonexistent/file)  # Will fail silently
echo "Error count: $count"

# WRONG: Inefficient multiple calls
total=$(ps aux | wc -l)
running=$(ps aux | grep -v grep | wc -l)
```

### **✅ Correct Approaches**
```bash
# CORRECT: Proper handling of filenames with spaces
while IFS= read -r -d '' file; do
    echo "Processing: $file"
done < <(find /tmp -name "*.log" -print0)

# CORRECT: Handle command failures
if count=$(grep -c "error" /var/log/app.log 2>/dev/null); then
    echo "Error count: $count"
else
    echo "Could not read log file or no errors found"
fi

# CORRECT: Single call with multiple extractions
ps_output=$(ps aux)
total=$(echo "$ps_output" | wc -l)
running=$(echo "$ps_output" | grep -v grep | wc -l)
```

---

## 🏆 Best Practices Summary

### **✅ Do's**
- Always quote command substitutions: `"$(command)"`
- Handle command failures gracefully
- Use modern `$()` syntax instead of backticks
- Consider performance implications of command substitution
- Use arrays when processing multiple items

### **❌ Don'ts**
- Don't ignore command exit codes
- Don't use command substitution in loops unnecessarily
- Don't nest too deeply (hard to debug)
- Avoid command substitution for large outputs
- Don't forget about word splitting

### **🔧 Performance Tips**
- Cache expensive command results
- Use process substitution for large data
- Avoid repeated calls to the same command
- Consider using temporary files for complex processing

---

## 🎯 Interview Questions

### **Q1: Command Substitution vs Process Substitution**
```bash
# What's the difference?
var=$(command)           # Command substitution
command < <(other_cmd)   # Process substitution
```

### **Q2: Error Handling**
*"How would you handle a command substitution that might fail?"*

### **Q3: Performance**
*"What's wrong with this code and how would you fix it?"*
```bash
for file in $(find /large/directory -name "*.log"); do
    lines=$(wc -l < "$file")
    echo "$file: $lines lines"
done
```

---

**🎯 Next Section: [Expansions & Quote Removal](../01-core-concepts/expansions.md)**
