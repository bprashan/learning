# 🔄 Redirection & I/O Management

## 📖 Core Concepts

Input/Output redirection is fundamental to shell scripting and essential for DevOps automation. Understanding how to manipulate stdin, stdout, stderr, and file descriptors enables powerful data processing and logging capabilities.

---

## 🎯 Basic Redirection Operations

### **1. Standard File Descriptors**
```bash
#!/bin/bash
# file-descriptors.sh - Understanding standard file descriptors

# Standard file descriptors:
# 0 = stdin (standard input)
# 1 = stdout (standard output)  
# 2 = stderr (standard error)

# Basic output redirection
echo "This goes to stdout" > output.txt
echo "This also goes to stdout" >> output.txt  # Append

# Error redirection
ls /nonexistent/directory 2> error.txt
ls /nonexistent/directory 2>> error.txt  # Append errors

# Redirect both stdout and stderr
command > output.txt 2>&1              # Redirect stderr to stdout, then to file
command &> combined.txt                # Bash shorthand for above
command > output.txt 2> error.txt     # Separate files

# Redirect to null (discard output)
command > /dev/null                    # Discard stdout
command 2> /dev/null                   # Discard stderr
command &> /dev/null                   # Discard both

# Input redirection
mysql -u user -p database < script.sql
sort < unsorted.txt > sorted.txt
```

### **2. Here Documents and Here Strings**
```bash
#!/bin/bash
# here-documents.sh - Advanced input techniques

# Here document (heredoc)
cat << EOF > config.txt
This is a multi-line
configuration file
with variable expansion: $USER
EOF

# Here document without expansion (quoted delimiter)
cat << 'EOF' > literal-config.txt
This text is literal
Variables like $USER are not expanded
Backslashes \ are preserved
EOF

# Here document with indentation removal
cat <<- EOF
	This text is indented with tabs
	But the leading tabs will be removed
	Useful for indented scripts
EOF

# Here string
grep "pattern" <<< "string to search"
base64 -d <<< "SGVsbG8gV29ybGQ="

# Here document with command
mysql -u root -p << EOF
CREATE DATABASE IF NOT EXISTS myapp;
USE myapp;
CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(100));
INSERT INTO users VALUES (1, 'Admin');
EOF
```

---

## 🛠️ DevOps Redirection Patterns

### **Logging and Monitoring**
```bash
#!/bin/bash
# logging-redirection.sh - Production logging patterns

# Configuration
LOG_DIR="/var/log/myapp"
LOG_FILE="$LOG_DIR/application.log"
ERROR_LOG="$LOG_DIR/error.log"
DEBUG_LOG="$LOG_DIR/debug.log"

# Create log directory
mkdir -p "$LOG_DIR"

# Logging functions
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $*" | tee -a "$ERROR_LOG" >&2
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $*" >> "$DEBUG_LOG"
    fi
}

# Application deployment with comprehensive logging
deploy_application() {
    local app_name="$1"
    local version="$2"
    
    log_info "Starting deployment of $app_name version $version"
    
    # Create deployment log
    local deploy_log="$LOG_DIR/deploy-$(date +%Y%m%d-%H%M%S).log"
    exec 3> "$deploy_log"  # Open file descriptor 3
    
    {
        echo "=== Deployment Log ==="
        echo "Application: $app_name"
        echo "Version: $version"
        echo "Timestamp: $(date)"
        echo "User: $(whoami)"
        echo "========================"
    } >&3
    
    # Backup current version
    if backup_current_version "$app_name" 2>&3; then
        log_info "Backup completed successfully"
        echo "Backup: SUCCESS" >&3
    else
        log_error "Backup failed"
        echo "Backup: FAILED" >&3
        exec 3>&-  # Close file descriptor
        return 1
    fi
    
    # Deploy new version
    if deploy_new_version "$app_name" "$version" 2>&3; then
        log_info "Deployment completed successfully"
        echo "Deploy: SUCCESS" >&3
    else
        log_error "Deployment failed"
        echo "Deploy: FAILED" >&3
        exec 3>&-
        return 1
    fi
    
    # Health check
    if health_check "$app_name" 2>&3; then
        log_info "Health check passed"
        echo "Health Check: PASSED" >&3
    else
        log_error "Health check failed"
        echo "Health Check: FAILED" >&3
        exec 3>&-
        return 1
    fi
    
    exec 3>&-  # Close deployment log
    log_info "Deployment completed. Full log: $deploy_log"
}

# Stub functions for example
backup_current_version() { sleep 1; return 0; }
deploy_new_version() { sleep 2; return 0; }
health_check() { sleep 1; return 0; }

# Example usage
DEBUG=true
deploy_application "mywebapp" "v2.1.0"
```

### **Database Operations with Redirection**
```bash
#!/bin/bash
# database-redirection.sh - Database backup and restore with proper I/O

# Configuration
DB_HOST="localhost"
DB_USER="backup_user"
DB_NAME="production_db"
BACKUP_DIR="/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Database backup with comprehensive logging
backup_database() {
    local backup_file="$BACKUP_DIR/${DB_NAME}_${DATE}.sql"
    local backup_log="$BACKUP_DIR/${DB_NAME}_${DATE}.log"
    
    log_info "Starting database backup to $backup_file"
    
    # Backup with progress and error handling
    {
        echo "=== MySQL Backup Log ==="
        echo "Database: $DB_NAME"
        echo "Host: $DB_HOST"
        echo "Started: $(date)"
        echo "========================"
    } > "$backup_log"
    
    # Perform backup with all streams redirected
    if mysqldump \
        --host="$DB_HOST" \
        --user="$DB_USER" \
        --password \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --hex-blob \
        "$DB_NAME" \
        > "$backup_file" \
        2>> "$backup_log"; then
        
        # Backup successful
        local backup_size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file")
        
        {
            echo "Backup completed: $(date)"
            echo "Backup size: $backup_size bytes"
            echo "Status: SUCCESS"
        } >> "$backup_log"
        
        # Compress backup
        if gzip "$backup_file"; then
            log_info "Backup compressed: ${backup_file}.gz"
        fi
        
        log_info "Database backup completed successfully"
        return 0
    else
        {
            echo "Backup failed: $(date)"
            echo "Status: FAILED"
        } >> "$backup_log"
        
        log_error "Database backup failed. Check $backup_log for details"
        return 1
    fi
}

# Database restore with validation
restore_database() {
    local backup_file="$1"
    local target_db="${2:-$DB_NAME}"
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log_info "Starting database restore from $backup_file"
    
    # Decompress if needed
    if [[ "$backup_file" == *.gz ]]; then
        local temp_file="/tmp/restore_${DATE}.sql"
        if ! gunzip -c "$backup_file" > "$temp_file"; then
            log_error "Failed to decompress backup file"
            return 1
        fi
        backup_file="$temp_file"
    fi
    
    # Validate SQL file before restore
    if ! head -10 "$backup_file" | grep -q "MySQL dump"; then
        log_error "Invalid MySQL dump file"
        [ -n "$temp_file" ] && rm -f "$temp_file"
        return 1
    fi
    
    # Perform restore
    if mysql \
        --host="$DB_HOST" \
        --user="$DB_USER" \
        --password \
        "$target_db" \
        < "$backup_file" \
        2> "/tmp/restore_error_${DATE}.log"; then
        
        log_info "Database restore completed successfully"
        [ -n "$temp_file" ] && rm -f "$temp_file"
        return 0
    else
        log_error "Database restore failed. Check /tmp/restore_error_${DATE}.log"
        [ -n "$temp_file" ] && rm -f "$temp_file"
        return 1
    fi
}

# Example usage
backup_database
```

### **System Monitoring with Redirection**
```bash
#!/bin/bash
# monitoring-redirection.sh - System monitoring with advanced I/O

# Configuration
MONITOR_DIR="/var/log/monitoring"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90

mkdir -p "$MONITOR_DIR"

# Real-time system monitoring
monitor_system() {
    local duration="${1:-60}"  # Monitor for 60 seconds by default
    local interval="${2:-5}"   # Check every 5 seconds
    
    local monitor_log="$MONITOR_DIR/monitor-$(date +%Y%m%d-%H%M%S).log"
    local alert_log="$MONITOR_DIR/alerts-$(date +%Y%m%d).log"
    
    log_info "Starting system monitoring for ${duration}s (interval: ${interval}s)"
    
    # Open file descriptors for different log streams
    exec 3> "$monitor_log"     # System metrics
    exec 4>> "$alert_log"      # Alerts
    
    # Write monitor log header
    {
        echo "=== System Monitoring Log ==="
        echo "Started: $(date)"
        echo "Duration: ${duration}s"
        echo "Interval: ${interval}s"
        echo "Thresholds: CPU=${ALERT_THRESHOLD_CPU}% MEM=${ALERT_THRESHOLD_MEMORY}% DISK=${ALERT_THRESHOLD_DISK}%"
        echo "============================="
    } >&3
    
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Collect system metrics
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
        local memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
        local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        
        # Write metrics to monitor log
        echo "$timestamp CPU:${cpu_usage}% MEM:${memory_usage}% DISK:${disk_usage}% LOAD:${load_avg}" >&3
        
        # Check thresholds and generate alerts
        local alerts_generated=false
        
        # CPU threshold check
        cpu_int=${cpu_usage%.*}  # Get integer part
        if [ -n "$cpu_int" ] && [ "$cpu_int" -gt "$ALERT_THRESHOLD_CPU" ]; then
            echo "$timestamp ALERT: High CPU usage: ${cpu_usage}%" >&4
            alerts_generated=true
        fi
        
        # Memory threshold check
        if [ "$memory_usage" -gt "$ALERT_THRESHOLD_MEMORY" ]; then
            echo "$timestamp ALERT: High memory usage: ${memory_usage}%" >&4
            alerts_generated=true
        fi
        
        # Disk threshold check
        if [ "$disk_usage" -gt "$ALERT_THRESHOLD_DISK" ]; then
            echo "$timestamp ALERT: High disk usage: ${disk_usage}%" >&4
            alerts_generated=true
        fi
        
        # If alerts were generated, also log to console
        if [ "$alerts_generated" = true ]; then
            log_error "System alerts generated at $timestamp"
        fi
        
        sleep "$interval"
    done
    
    # Close file descriptors
    exec 3>&-
    exec 4>&-
    
    log_info "System monitoring completed. Logs: $monitor_log, Alerts: $alert_log"
}

# Generate system report
generate_system_report() {
    local report_file="$MONITOR_DIR/system-report-$(date +%Y%m%d).txt"
    
    # Generate comprehensive system report using multiple redirections
    {
        echo "=== SYSTEM REPORT ==="
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "Uptime: $(uptime)"
        echo ""
        
        echo "=== CPU INFORMATION ==="
        cat /proc/cpuinfo | grep -E "processor|model name|cpu cores" | head -20
        echo ""
        
        echo "=== MEMORY INFORMATION ==="
        free -h
        echo ""
        
        echo "=== DISK USAGE ==="
        df -h
        echo ""
        
        echo "=== NETWORK INTERFACES ==="
        ip addr show
        echo ""
        
        echo "=== RUNNING SERVICES ==="
        systemctl list-units --type=service --state=running | head -20
        echo ""
        
        echo "=== TOP PROCESSES ==="
        ps aux --sort=-%cpu | head -20
        echo ""
        
    } > "$report_file"
    
    # Generate summary statistics
    {
        echo "=== REPORT SUMMARY ==="
        echo "Total lines: $(wc -l < "$report_file")"
        echo "File size: $(stat -f%z "$report_file" 2>/dev/null || stat -c%s "$report_file") bytes"
        echo "Generated: $(date)"
    } >> "$report_file"
    
    log_info "System report generated: $report_file"
    
    # Optionally email the report
    if command -v mail >/dev/null && [ -n "${ADMIN_EMAIL:-}" ]; then
        mail -s "System Report - $(hostname)" "$ADMIN_EMAIL" < "$report_file"
    fi
}

# Example usage
monitor_system 30 5  # Monitor for 30 seconds, check every 5 seconds
generate_system_report
```

---

## 🔧 Advanced Redirection Techniques

### **Named Pipes (FIFOs)**
```bash
#!/bin/bash
# named-pipes.sh - Inter-process communication with named pipes

# Create named pipes for communication
PIPE_DIR="/tmp/monitoring"
mkdir -p "$PIPE_DIR"

CPU_PIPE="$PIPE_DIR/cpu_data"
MEMORY_PIPE="$PIPE_DIR/memory_data"
DISK_PIPE="$PIPE_DIR/disk_data"

# Create named pipes
mkfifo "$CPU_PIPE" "$MEMORY_PIPE" "$DISK_PIPE"

# CPU monitoring process
monitor_cpu() {
    while true; do
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
        echo "$(date '+%H:%M:%S') CPU: $cpu_usage" > "$CPU_PIPE"
        sleep 5
    done
}

# Memory monitoring process  
monitor_memory() {
    while true; do
        local memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        echo "$(date '+%H:%M:%S') MEM: $memory_usage%" > "$MEMORY_PIPE"
        sleep 5
    done
}

# Disk monitoring process
monitor_disk() {
    while true; do
        local disk_usage=$(df / | tail -1 | awk '{print $5}')
        echo "$(date '+%H:%M:%S') DISK: $disk_usage" > "$DISK_PIPE"
        sleep 10
    done
}

# Aggregator process
aggregate_monitoring_data() {
    local output_file="/var/log/aggregated_monitoring.log"
    
    # Read from multiple pipes simultaneously
    while true; do
        if read -t 1 cpu_data < "$CPU_PIPE"; then
            echo "$cpu_data" | tee -a "$output_file"
        fi
        
        if read -t 1 memory_data < "$MEMORY_PIPE"; then
            echo "$memory_data" | tee -a "$output_file"
        fi
        
        if read -t 1 disk_data < "$DISK_PIPE"; then
            echo "$disk_data" | tee -a "$output_file"
        fi
    done
}

# Start monitoring (in production, use proper process management)
start_monitoring() {
    log_info "Starting distributed monitoring system"
    
    monitor_cpu &
    local cpu_pid=$!
    
    monitor_memory &
    local memory_pid=$!
    
    monitor_disk &
    local disk_pid=$!
    
    aggregate_monitoring_data &
    local aggregator_pid=$!
    
    # Store PIDs for cleanup
    echo "$cpu_pid $memory_pid $disk_pid $aggregator_pid" > "$PIPE_DIR/monitor.pids"
    
    log_info "Monitoring started. PIDs saved to $PIPE_DIR/monitor.pids"
}

# Cleanup function
cleanup_monitoring() {
    if [ -f "$PIPE_DIR/monitor.pids" ]; then
        local pids=$(cat "$PIPE_DIR/monitor.pids")
        log_info "Stopping monitoring processes: $pids"
        kill $pids 2>/dev/null
        rm -f "$PIPE_DIR/monitor.pids"
    fi
    
    # Remove named pipes
    rm -f "$CPU_PIPE" "$MEMORY_PIPE" "$DISK_PIPE"
    rmdir "$PIPE_DIR" 2>/dev/null
    
    log_info "Monitoring cleanup completed"
}

# Set up cleanup on script exit
trap cleanup_monitoring EXIT

# Example usage (commented to prevent automatic execution)
# start_monitoring
# sleep 60
# cleanup_monitoring
```

### **Advanced File Descriptor Management**
```bash
#!/bin/bash
# advanced-file-descriptors.sh - Complex file descriptor operations

# Configuration
BACKUP_DIR="/backup"
LOG_DIR="/var/log/backup"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# Multi-stream backup operation
perform_advanced_backup() {
    local source_dir="$1"
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    
    # Open multiple file descriptors for different purposes
    exec 3> "$LOG_DIR/${backup_name}.log"           # Main log
    exec 4> "$LOG_DIR/${backup_name}-error.log"     # Error log  
    exec 5> "$LOG_DIR/${backup_name}-progress.log"  # Progress log
    exec 6> "$LOG_DIR/${backup_name}-files.log"     # File list
    
    # Write headers to all log files
    {
        echo "=== Backup Operation Log ==="
        echo "Started: $(date)"
        echo "Source: $source_dir"
        echo "Backup: $backup_name"
        echo "========================="
    } >&3
    
    echo "=== Error Log ===" >&4
    echo "=== Progress Log ===" >&5
    echo "=== File List ===" >&6
    
    log_info "Starting advanced backup of $source_dir"
    
    # Create tar backup with multiple output streams
    {
        tar -czf "$BACKUP_DIR/${backup_name}.tar.gz" \
            -C "$(dirname "$source_dir")" \
            "$(basename "$source_dir")" \
            --verbose \
            2>&4 \
        | while read -r file; do
            echo "Backed up: $file" >&6
            echo "Progress: $file" >&5
        done
    } 2>&1 | tee >&3
    
    local backup_exit_code=${PIPESTATUS[0]}
    
    if [ $backup_exit_code -eq 0 ]; then
        local backup_size=$(stat -f%z "$BACKUP_DIR/${backup_name}.tar.gz" 2>/dev/null || stat -c%s "$BACKUP_DIR/${backup_name}.tar.gz")
        
        {
            echo "Backup completed successfully"
            echo "Final size: $backup_size bytes"
            echo "Completed: $(date)"
        } >&3
        
        log_info "Backup completed successfully: ${backup_name}.tar.gz"
    else
        {
            echo "Backup failed with exit code: $backup_exit_code"
            echo "Failed: $(date)"
        } >&3 >&4
        
        log_error "Backup failed. Check error log: $LOG_DIR/${backup_name}-error.log"
    fi
    
    # Close all file descriptors
    exec 3>&- 4>&- 5>&- 6>&-
    
    return $backup_exit_code
}

# Database backup with transaction log
backup_database_with_logs() {
    local db_name="$1"
    local backup_file="$BACKUP_DIR/db-${db_name}-$(date +%Y%m%d-%H%M%S).sql"
    local log_file="$LOG_DIR/db-backup-$(date +%Y%m%d-%H%M%S).log"
    
    # Open file descriptor for database operation log
    exec 7> "$log_file"
    
    {
        echo "=== Database Backup Log ==="
        echo "Database: $db_name"
        echo "Started: $(date)"
        echo "========================="
    } >&7
    
    # Backup with detailed logging
    {
        mysqldump \
            --single-transaction \
            --routines \
            --triggers \
            --events \
            --hex-blob \
            --verbose \
            "$db_name" \
        2> >(while read line; do echo "ERROR: $line" >&7; done) \
        | tee "$backup_file" \
        | while read -r line; do
            case "$line" in
                "--"*) echo "COMMENT: $line" >&7 ;;
                "/*"*) echo "META: $line" >&7 ;;
                *) : ;;  # Skip data lines to avoid log spam
            esac
        done
    }
    
    local dump_exit_code=${PIPESTATUS[0]}
    
    if [ $dump_exit_code -eq 0 ]; then
        local backup_size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file")
        
        {
            echo "Database backup completed successfully"
            echo "File: $backup_file"
            echo "Size: $backup_size bytes"
            echo "Completed: $(date)"
        } >&7
        
        # Compress the backup
        if gzip "$backup_file"; then
            echo "Backup compressed: ${backup_file}.gz" >&7
        fi
        
        log_info "Database backup completed: ${backup_file}.gz"
    else
        {
            echo "Database backup failed with exit code: $dump_exit_code"
            echo "Failed: $(date)"
        } >&7
        
        log_error "Database backup failed. Check log: $log_file"
    fi
    
    exec 7>&-
    return $dump_exit_code
}

# Example usage
perform_advanced_backup "/etc"
backup_database_with_logs "myapp"
```

---

## 🛡️ Error Handling with Redirection

### **Robust Error Handling Patterns**
```bash
#!/bin/bash
# error-handling-redirection.sh - Production error handling

# Global error handling setup
ERROR_LOG="/var/log/script-errors.log"
DEBUG_LOG="/var/log/script-debug.log"

# Redirect all errors to log file
exec 2> >(tee -a "$ERROR_LOG" >&2)

# Enable debugging if requested
if [ "${DEBUG:-false}" = "true" ]; then
    exec 19> "$DEBUG_LOG"
    BASH_XTRACEFD=19
    set -x
fi

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    {
        echo "=== ERROR OCCURRED ==="
        echo "Time: $(date)"
        echo "Script: $0"
        echo "Line: $line_number"
        echo "Exit code: $exit_code"
        echo "Command: ${BASH_COMMAND}"
        echo "======================"
    } >&2
    
    # Cleanup on error
    cleanup_on_error
    exit $exit_code
}

# Set error trap
trap 'handle_error ${LINENO}' ERR
set -eE  # Exit on error, inherit traps

# Cleanup function
cleanup_on_error() {
    log_error "Performing emergency cleanup"
    
    # Close any open file descriptors
    for fd in {3..9}; do
        exec {fd}>&- 2>/dev/null || true
    done
    
    # Remove temporary files
    rm -f /tmp/script_temp_* 2>/dev/null || true
}

# Safe command execution with output capture
safe_execute() {
    local command="$1"
    local success_log="$2"
    local error_log="$3"
    
    local temp_output="/tmp/safe_execute_$$"
    local temp_error="/tmp/safe_execute_error_$$"
    
    # Execute command with output capture
    if eval "$command" > "$temp_output" 2> "$temp_error"; then
        # Success - log output
        if [ -n "$success_log" ] && [ -s "$temp_output" ]; then
            cat "$temp_output" >> "$success_log"
        fi
        
        # Display output if not redirected
        if [ -t 1 ]; then
            cat "$temp_output"
        fi
        
        rm -f "$temp_output" "$temp_error"
        return 0
    else
        local exit_code=$?
        
        # Error - log to error file
        if [ -n "$error_log" ] && [ -s "$temp_error" ]; then
            {
                echo "Command failed: $command"
                echo "Exit code: $exit_code"
                echo "Error output:"
                cat "$temp_error"
                echo "---"
            } >> "$error_log"
        fi
        
        # Display error
        cat "$temp_error" >&2
        
        rm -f "$temp_output" "$temp_error"
        return $exit_code
    fi
}

# Example usage
safe_execute "ls /nonexistent" "/tmp/success.log" "/tmp/error.log" || echo "Command failed as expected"
```

---

## 🏆 Best Practices Summary

### **✅ Redirection Best Practices**
- Always handle both stdout and stderr appropriately
- Use meaningful log file names with timestamps
- Close file descriptors when done to prevent resource leaks
- Use `tee` to write to files while preserving console output
- Validate file operations and handle errors gracefully

### **❌ Common Pitfalls**
- Forgetting to close file descriptors (resource leaks)
- Not handling permission errors when writing to log files
- Mixing up redirection order (`2>&1` must come after `>file`)
- Not using proper error handling with redirected commands
- Ignoring stderr in automated scripts

### **🔧 Performance Considerations**
- Use appropriate buffer sizes for large data streams
- Avoid excessive logging in high-frequency operations
- Consider log rotation for long-running processes
- Use named pipes for inter-process communication
- Monitor disk space when redirecting large outputs

---

## 🎯 Interview Questions

### **Q1: Redirection Order**
```bash
# What's the difference between these commands?
command > file 2>&1
command 2>&1 > file
```

### **Q2: File Descriptor Management**
*"How would you capture both stdout and stderr to separate files while still displaying errors on the console?"*

### **Q3: Here Document Security**
*"What are the security implications of using here documents with variable expansion?"*

---

**🎯 Next Section: [Conditional Statements](../02-control-structures/conditionals.md)**
