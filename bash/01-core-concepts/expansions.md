# 🌟 Expansions & Quote Removal

## 📖 Core Concepts

Bash expansions transform patterns into values before command execution. Understanding expansions is crucial for writing efficient scripts and avoiding common pitfalls. This includes brace expansion, tilde expansion, parameter expansion, and proper quoting mechanisms.

---

## 🎯 Types of Expansions

### **1. Brace Expansion**
```bash
#!/bin/bash
# brace-expansion.sh - Efficient pattern generation

# Basic brace expansion
echo {1..10}              # Numbers: 1 2 3 4 5 6 7 8 9 10
echo {a..z}               # Letters: a b c d ... z
echo {A..Z}               # Uppercase: A B C D ... Z

# Step increments
echo {0..100..10}         # 0 10 20 30 ... 100
echo {10..1..2}           # 10 8 6 4 2

# String patterns
echo {red,green,blue}     # red green blue
echo file{1,2,3}.txt      # file1.txt file2.txt file3.txt

# Nested braces
echo {a,b}{1,2,3}         # a1 a2 a3 b1 b2 b3
echo {{A..C},{1..3}}      # A B C 1 2 3
```

### **DevOps Brace Expansion Examples**
```bash
#!/bin/bash
# devops-brace-examples.sh - Real-world brace expansion usage

# Create multiple environment directories
mkdir -p environments/{dev,staging,prod}/{config,logs,data}

# Backup multiple configuration files
cp /etc/{nginx,apache2,mysql}/*.conf backup/

# Process multiple log files
for log in /var/log/{nginx,apache2,mysql}/*.log; do
    if [ -f "$log" ]; then
        echo "Processing: $log"
        gzip "$log.$(date +%Y%m%d)"
    fi
done

# Generate server names
servers=(web{01..05} db{01..03} cache{01..02})
echo "All servers: ${servers[*]}"

# Create firewall rules for multiple ports
for port in {80,443,8080,8443}; do
    echo "Opening port $port"
    # iptables -A INPUT -p tcp --dport $port -j ACCEPT
done

# Generate configuration for multiple environments
for env in {dev,staging,prod}; do
    for service in {web,api,worker}; do
        config_file="${env}-${service}.conf"
        echo "Creating $config_file"
        cat > "$config_file" << EOF
[${env}_${service}]
environment=$env
service=$service
port=$(( 8000 + RANDOM % 1000 ))
EOF
    done
done
```

---

### **2. Tilde Expansion**
```bash
#!/bin/bash
# tilde-expansion.sh - Home directory shortcuts

# Basic tilde expansion
echo ~                    # Current user's home directory
echo ~root                # root user's home directory
echo ~postgres            # postgres user's home directory

# Common DevOps usage patterns
LOG_DIR=~/logs
CONFIG_DIR=~/.config/myapp
BACKUP_DIR=~/backups

# Create user-specific directories
setup_user_environment() {
    local user="$1"
    local user_home=$(eval echo "~$user")
    
    if [ -d "$user_home" ]; then
        echo "Setting up environment for $user"
        sudo -u "$user" mkdir -p "$user_home"/{bin,logs,config,data}
        echo "Created directories in: $user_home"
    else
        echo "User home directory not found: $user_home"
        return 1
    fi
}

# Example usage
setup_user_environment "nginx"
setup_user_environment "mysql"
```

---

### **3. Parameter Expansion**
```bash
#!/bin/bash
# parameter-expansion.sh - Advanced parameter manipulation

# Basic parameter expansion
name="DevOps Engineer"
echo "${name}"            # DevOps Engineer
echo "${name:-Unknown}"   # Use "Unknown" if name is unset
echo "${name:=Default}"   # Assign "Default" if name is unset
echo "${name:?Error}"     # Error if name is unset
echo "${name:+Set}"       # "Set" if name is set, empty otherwise

# String manipulation
filename="backup-2024-10-10.tar.gz"

# Length
echo "Length: ${#filename}"                    # 24

# Substring extraction
echo "First 6 chars: ${filename:0:6}"          # backup
echo "From position 7: ${filename:7}"          # 2024-10-10.tar.gz
echo "Last 6 chars: ${filename: -6}"           # tar.gz

# Pattern removal
echo "Remove .tar.gz: ${filename%.tar.gz}"     # backup-2024-10-10
echo "Remove backup-: ${filename#backup-}"     # 2024-10-10.tar.gz
echo "Remove all up to last dot: ${filename##*.}"  # gz
echo "Remove from first dot: ${filename%%.*}"  # backup-2024-10-10

# Case modification (Bash 4+)
text="DevOps Engineer"
echo "Uppercase: ${text^^}"                    # DEVOPS ENGINEER
echo "Lowercase: ${text,,}"                    # devops engineer
echo "First letter upper: ${text^}"            # DevOps engineer
echo "First letter lower: ${text,}"            # devOps Engineer
```

### **Advanced Parameter Expansion for DevOps**
```bash
#!/bin/bash
# devops-parameter-expansion.sh - Real-world parameter expansion

# Configuration management with defaults
setup_application_config() {
    # Database configuration with smart defaults
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-5432}"
    DB_NAME="${DB_NAME:-application}"
    DB_USER="${DB_USER:-app_user}"
    
    # Redis configuration
    REDIS_HOST="${REDIS_HOST:-localhost}"
    REDIS_PORT="${REDIS_PORT:-6379}"
    REDIS_DB="${REDIS_DB:-0}"
    
    # Application configuration
    APP_ENV="${APP_ENV:-development}"
    APP_PORT="${APP_PORT:-8080}"
    LOG_LEVEL="${LOG_LEVEL:-INFO}"
    
    # Validate required parameters
    : "${API_SECRET:?API_SECRET must be set}"
    : "${JWT_SECRET:?JWT_SECRET must be set}"
    
    echo "=== Application Configuration ==="
    echo "Database: ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
    echo "Redis: ${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}"
    echo "Application: ${APP_ENV} on port ${APP_PORT}"
    echo "Log Level: ${LOG_LEVEL}"
}

# File processing with parameter expansion
process_backup_files() {
    local backup_dir="${1:-/backup}"
    
    for backup_file in "$backup_dir"/*.tar.gz; do
        [ -f "$backup_file" ] || continue
        
        # Extract information from filename
        local basename="${backup_file##*/}"           # Remove directory path
        local name_without_ext="${basename%.tar.gz}"   # Remove .tar.gz
        local date_part="${name_without_ext##*-}"     # Extract date part
        local service_name="${name_without_ext%-*}"   # Extract service name
        
        echo "Processing backup:"
        echo "  File: $basename"
        echo "  Service: $service_name"
        echo "  Date: $date_part"
        
        # Process based on date (keep only last 7 days)
        local file_age=$(date -d "$date_part" +%s 2>/dev/null)
        local week_ago=$(date -d "7 days ago" +%s)
        
        if [ -n "$file_age" ] && [ "$file_age" -lt "$week_ago" ]; then
            echo "  Action: Archive (older than 7 days)"
            # mv "$backup_file" "${backup_dir}/archive/"
        else
            echo "  Action: Keep (recent backup)"
        fi
        echo
    done
}

# Environment-specific configuration
setup_environment_config() {
    local env="${ENVIRONMENT:-development}"
    
    case "${env,,}" in  # Convert to lowercase
        production|prod)
            export LOG_LEVEL="WARN"
            export DEBUG_MODE="false"
            export DB_POOL_SIZE="20"
            export CACHE_TTL="3600"
            ;;
        staging|stage)
            export LOG_LEVEL="INFO"
            export DEBUG_MODE="true"
            export DB_POOL_SIZE="10"
            export CACHE_TTL="1800"
            ;;
        development|dev)
            export LOG_LEVEL="DEBUG"
            export DEBUG_MODE="true"
            export DB_POOL_SIZE="5"
            export CACHE_TTL="300"
            ;;
        *)
            echo "Unknown environment: $env, using development defaults"
            setup_environment_config  # Recursively call with default
            ;;
    esac
    
    echo "Environment configured for: ${env}"
}

# Example usage
setup_application_config
process_backup_files "/backup"
setup_environment_config
```

---

### **4. Arithmetic Expansion**
```bash
#!/bin/bash
# arithmetic-expansion.sh - Mathematical operations in bash

# Basic arithmetic
echo $((5 + 3))           # 8
echo $((10 - 4))          # 6
echo $((6 * 7))           # 42
echo $((20 / 4))          # 5
echo $((23 % 5))          # 3 (remainder)
echo $((2 ** 3))          # 8 (exponentiation)

# Using variables
a=10
b=3
echo $((a + b))           # 13
echo $((a > b))           # 1 (true)
echo $((a < b))           # 0 (false)

# Increment and decrement
counter=0
echo $((counter++))       # 0 (post-increment)
echo $counter             # 1
echo $((++counter))       # 2 (pre-increment)
echo $counter             # 2
```

### **DevOps Arithmetic Examples**
```bash
#!/bin/bash
# devops-arithmetic.sh - Practical arithmetic in DevOps scripts

# Calculate disk usage percentage
calculate_disk_usage() {
    local partition="${1:-/}"
    
    # Get disk usage information
    local disk_info=$(df "$partition" | tail -1)
    read -r filesystem size used available use_percent mount <<< "$disk_info"
    
    # Extract numeric values (remove units like 'K', 'M', 'G')
    local size_kb=${size%[A-Za-z]}
    local used_kb=${used%[A-Za-z]}
    local available_kb=${available%[A-Za-z]}
    
    # Calculate precise percentage
    local usage_percent=$((used_kb * 100 / size_kb))
    
    echo "Disk Usage Analysis for $partition:"
    echo "  Size: $size"
    echo "  Used: $used"
    echo "  Available: $available"
    echo "  Usage: $usage_percent%"
    
    # Determine alert level
    if [ $usage_percent -gt 90 ]; then
        echo "  Status: 🔴 CRITICAL"
    elif [ $usage_percent -gt 80 ]; then
        echo "  Status: 🟡 WARNING"
    else
        echo "  Status: 🟢 OK"
    fi
}

# Calculate memory usage
calculate_memory_usage() {
    # Get memory information
    local mem_info=$(free -m)
    local total=$(echo "$mem_info" | awk '/^Mem:/ {print $2}')
    local used=$(echo "$mem_info" | awk '/^Mem:/ {print $3}')
    local available=$(echo "$mem_info" | awk '/^Mem:/ {print $7}')
    
    # Calculate percentages
    local used_percent=$((used * 100 / total))
    local available_percent=$((available * 100 / total))
    
    echo "Memory Usage Analysis:"
    echo "  Total: ${total}MB"
    echo "  Used: ${used}MB ($used_percent%)"
    echo "  Available: ${available}MB ($available_percent%)"
    
    # Memory pressure analysis
    if [ $used_percent -gt 90 ]; then
        echo "  Status: 🔴 HIGH MEMORY PRESSURE"
    elif [ $used_percent -gt 75 ]; then
        echo "  Status: 🟡 MODERATE MEMORY USAGE"
    else
        echo "  Status: 🟢 NORMAL MEMORY USAGE"
    fi
}

# Calculate service uptime
calculate_service_uptime() {
    local service="$1"
    
    # Get service start time
    local start_time=$(systemctl show "$service" --property=ActiveEnterTimestamp --value)
    
    if [ -n "$start_time" ] && [ "$start_time" != "0" ]; then
        # Convert to epoch time
        local start_epoch=$(date -d "$start_time" +%s)
        local current_epoch=$(date +%s)
        
        # Calculate uptime in seconds
        local uptime_seconds=$((current_epoch - start_epoch))
        
        # Convert to human-readable format
        local days=$((uptime_seconds / 86400))
        local hours=$(((uptime_seconds % 86400) / 3600))
        local minutes=$(((uptime_seconds % 3600) / 60))
        
        echo "Service Uptime for $service:"
        echo "  Started: $start_time"
        echo "  Uptime: ${days}d ${hours}h ${minutes}m"
        echo "  Total seconds: $uptime_seconds"
    else
        echo "Service $service is not running or start time unavailable"
    fi
}

# Performance calculations
calculate_performance_metrics() {
    local start_time=$(date +%s%N)  # Nanoseconds
    
    # Simulate some work
    sleep 0.1
    
    local end_time=$(date +%s%N)
    local duration_ns=$((end_time - start_time))
    local duration_ms=$((duration_ns / 1000000))
    
    echo "Performance Metrics:"
    echo "  Duration: ${duration_ms}ms"
    echo "  Nanoseconds: $duration_ns"
    
    # Calculate throughput (operations per second)
    local operations=1000
    local ops_per_second=$((operations * 1000 / duration_ms))
    echo "  Throughput: ${ops_per_second} ops/sec"
}

# Example usage
calculate_disk_usage "/"
echo
calculate_memory_usage
echo
calculate_service_uptime "nginx"
echo
calculate_performance_metrics
```

---

### **5. Command Expansion & Process Substitution**
```bash
#!/bin/bash
# command-process-expansion.sh - Advanced expansion techniques

# Process substitution for comparing outputs
compare_configurations() {
    local prod_config="/etc/nginx/sites-available/prod"
    local staging_config="/etc/nginx/sites-available/staging"
    
    # Compare configurations line by line
    diff <(grep -v '^#' "$prod_config" | sort) \
         <(grep -v '^#' "$staging_config" | sort)
}

# Process substitution for complex data processing
analyze_log_patterns() {
    local log_file="/var/log/nginx/access.log"
    
    # Process logs in parallel streams
    paste <(awk '{print $1}' "$log_file" | sort | uniq -c | sort -rn | head -10) \
          <(awk '{print $9}' "$log_file" | sort | uniq -c | sort -rn | head -10) \
    | while read ip_count ip status_count status; do
        echo "Top IP: $ip ($ip_count hits) | Top Status: $status ($status_count occurrences)"
    done
}

# Advanced process substitution for monitoring
monitor_system_changes() {
    local check_interval=5
    
    echo "Monitoring system changes every ${check_interval}s..."
    
    # Capture initial state
    local initial_processes=$(ps aux --sort=-%cpu | head -20)
    local initial_connections=$(ss -tuln | wc -l)
    
    while true; do
        sleep $check_interval
        
        # Compare current state with initial
        local current_processes=$(ps aux --sort=-%cpu | head -20)
        local current_connections=$(ss -tuln | wc -l)
        
        # Show process changes
        echo "=== Process Changes $(date) ==="
        diff <(echo "$initial_processes") <(echo "$current_processes") | head -10
        
        # Show connection changes
        local connection_diff=$((current_connections - initial_connections))
        echo "Connection change: $connection_diff"
        
        # Update baseline
        initial_processes="$current_processes"
        initial_connections="$current_connections"
    done
}

# Example usage (commented out to prevent infinite loop)
# compare_configurations
# analyze_log_patterns
# monitor_system_changes
```

---

## 🔤 Quote Removal & Quoting Mechanisms

### **Understanding Quote Types**
```bash
#!/bin/bash
# quoting-mechanisms.sh - Comprehensive quoting examples

# Single quotes - preserve everything literally
echo 'The variable $USER will not be expanded'
echo 'Command substitution $(date) will not work'
echo 'Even backslashes \ are literal'

# Double quotes - allow expansions but preserve spaces
user="$USER"
echo "Hello $user, today is $(date)"
echo "Your home directory is $HOME"

# No quotes - word splitting and glob expansion occur
files="file1.txt file2.txt file3.txt"
echo Without quotes: $files     # Three separate words
echo "With quotes: $files"      # Single string

# ANSI-C quoting $'...' - interpret escape sequences
echo $'Line 1\nLine 2\nLine 3'
echo $'Tab\tseparated\tvalues'
echo $'Unicode: \u2764'  # Heart symbol (if supported)
```

### **DevOps Quoting Best Practices**
```bash
#!/bin/bash
# devops-quoting-practices.sh - Production-ready quoting

# Safe file processing
process_files_safely() {
    local directory="$1"
    
    # WRONG: Word splitting will break on spaces
    # for file in $(find "$directory" -name "*.log"); do
    
    # CORRECT: Proper handling of filenames with spaces
    find "$directory" -name "*.log" -print0 | while IFS= read -r -d '' file; do
        echo "Processing: $file"
        
        # Safe file operations with proper quoting
        if [ -f "$file" ]; then
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
            echo "  Size: $size bytes"
            
            # Safe backup with quoted variables
            local backup_name="${file}.backup.$(date +%Y%m%d)"
            cp "$file" "$backup_name"
            echo "  Backed up to: $backup_name"
        fi
    done
}

# Command construction with proper quoting
execute_remote_command() {
    local host="$1"
    local command="$2"
    
    # Proper quoting for remote command execution
    ssh "$host" "$command"
    
    # For complex commands, use here-documents
    ssh "$host" << 'EOF'
        # This runs on the remote host
        cd /var/log
        find . -name "*.log" -mtime +7 -delete
        systemctl reload nginx
EOF
}

# Configuration file generation with proper escaping
generate_nginx_config() {
    local server_name="$1"
    local document_root="$2"
    local port="${3:-80}"
    
    cat > "/etc/nginx/sites-available/$server_name" << EOF
server {
    listen $port;
    server_name $server_name;
    root $document_root;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
    
    echo "Nginx configuration created for $server_name"
}

# Example usage
process_files_safely "/var/log"
generate_nginx_config "example.com" "/var/www/example.com" "80"
```

---

## 🛡️ Security Considerations

### **Preventing Injection Attacks**
```bash
#!/bin/bash
# security-quoting.sh - Secure parameter handling

# DANGEROUS: User input without validation
dangerous_function() {
    local user_input="$1"
    
    # NEVER DO THIS - allows command injection
    # eval "ls $user_input"
    # bash -c "echo $user_input"
}

# SAFE: Proper input validation and quoting
safe_function() {
    local user_input="$1"
    
    # Validate input first
    if [[ "$user_input" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
        # Safe execution with proper quoting
        ls "$user_input"
    else
        echo "Error: Invalid input characters" >&2
        return 1
    fi
}

# Safe command construction
build_safe_command() {
    local action="$1"
    local target="$2"
    
    # Whitelist allowed actions
    case "$action" in
        "backup"|"restore"|"check")
            # Build command safely
            local cmd=("$action" "$target")
            "${cmd[@]}"  # Execute array as command
            ;;
        *)
            echo "Error: Unknown action: $action" >&2
            return 1
            ;;
    esac
}

# Secure configuration parsing
parse_config_safely() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        echo "Configuration file not found: $config_file" >&2
        return 1
    fi
    
    # Safe parsing without eval
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # Validate key format
        if [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
            # Safe assignment using declare
            declare -g "$key"="$value"
            echo "Set $key=$value"
        else
            echo "Warning: Invalid key format: $key" >&2
        fi
    done < "$config_file"
}

# Example secure configuration file
cat > example.conf << 'EOF'
# Example configuration
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=myapp
# Invalid key (contains lowercase): invalid_key=value
API_TIMEOUT=30
EOF

parse_config_safely "example.conf"
```

---

## 🏆 Best Practices Summary

### **✅ Expansion Best Practices**
- Use brace expansion for generating sequences and patterns
- Always quote variables to prevent word splitting: `"$var"`
- Use parameter expansion for string manipulation instead of external tools
- Prefer `$()` over backticks for command substitution
- Use process substitution for comparing command outputs

### **❌ Common Pitfalls**
- Unquoted variables causing word splitting
- Not handling empty or unset variables
- Using `eval` with user input (security risk)
- Forgetting that brace expansion happens before variable expansion
- Not escaping special characters in here-documents

### **🔧 Performance Tips**
- Use parameter expansion instead of `sed`/`awk` for simple string operations
- Cache expensive command substitutions
- Use brace expansion for bulk operations
- Avoid unnecessary subshells

---

## 🎯 Interview Questions

### **Q1: Parameter Expansion**
```bash
# What do these expansions do?
file="/path/to/backup-2024-10-10.tar.gz"
echo "${file##*/}"        # ?
echo "${file%.*}"         # ?
echo "${file%.tar.gz}"    # ?
echo "${file#*/}"         # ?
```

### **Q2: Quoting Challenge**
*"How would you safely process a list of filenames that might contain spaces?"*

### **Q3: Security Question**
*"What's wrong with this code and how would you fix it?"*
```bash
user_input="$1"
eval "echo Hello $user_input"
```

---

**🎯 Next Section: [Redirection & I/O Management](../01-core-concepts/redirection.md)**
