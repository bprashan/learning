#!/bin/bash
# daily-ops-checklist.sh - Comprehensive daily operations checklist for DevOps engineers

# Configuration
LOGFILE="/var/log/daily-ops-checklist.log"
REPORT_EMAIL="devops-team@company.com"
BACKUP_THRESHOLD_HOURS=25
CERT_EXPIRY_WARNING_DAYS=30

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Initialize counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

print_header() {
    clear
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}               DevOps Daily Operations Checklist               ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${CYAN}Date: $(date '+%A, %B %d, %Y')${NC}"
    echo -e "${CYAN}Time: $(date '+%H:%M:%S %Z')${NC}"
    echo -e "${CYAN}Operator: $(whoami)@$(hostname)${NC}"
    echo ""
    log_message "Starting daily operations checklist"
}

check_status() {
    local check_name="$1"
    local status="$2"
    local details="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case $status in
        "PASS")
            echo -e "${GREEN}✅ [PASS]${NC} $check_name"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            log_message "PASS: $check_name - $details"
            ;;
        "FAIL")
            echo -e "${RED}❌ [FAIL]${NC} $check_name"
            echo -e "   ${RED}Issue: $details${NC}"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            log_message "FAIL: $check_name - $details"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  [WARN]${NC} $check_name"
            echo -e "   ${YELLOW}Warning: $details${NC}"
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            log_message "WARN: $check_name - $details"
            ;;
    esac
}

# 1. System Health Checks
system_health_checks() {
    echo -e "${PURPLE}🏥 SYSTEM HEALTH CHECKS${NC}"
    echo "----------------------------------------"
    
    # Check system uptime
    UPTIME_DAYS=$(uptime | awk '{print $3}' | sed 's/,//')
    if [[ "$UPTIME_DAYS" =~ ^[0-9]+$ ]] && [ "$UPTIME_DAYS" -gt 100 ]; then
        check_status "System Uptime" "WARN" "System has been up for $UPTIME_DAYS days - consider planned reboot"
    else
        check_status "System Uptime" "PASS" "System uptime is healthy"
    fi
    
    # Check load average
    LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    CORES=$(nproc)
    LOAD_RATIO=$(echo "$LOAD_1MIN / $CORES" | bc -l)
    if (( $(echo "$LOAD_RATIO > 2.0" | bc -l) )); then
        check_status "Load Average" "FAIL" "Load average $LOAD_1MIN is high for $CORES cores"
    elif (( $(echo "$LOAD_RATIO > 1.0" | bc -l) )); then
        check_status "Load Average" "WARN" "Load average $LOAD_1MIN is elevated for $CORES cores"
    else
        check_status "Load Average" "PASS" "Load average is normal ($LOAD_1MIN)"
    fi
    
    # Check memory usage
    MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
    if [ "$MEMORY_USAGE" -gt 90 ]; then
        check_status "Memory Usage" "FAIL" "Memory usage is critical at $MEMORY_USAGE%"
    elif [ "$MEMORY_USAGE" -gt 80 ]; then
        check_status "Memory Usage" "WARN" "Memory usage is high at $MEMORY_USAGE%"
    else
        check_status "Memory Usage" "PASS" "Memory usage is normal ($MEMORY_USAGE%)"
    fi
    
    # Check disk space
    CRITICAL_DISKS=$(df -h | awk 'NR>1 {gsub(/%/,"",$5); if($5>90) print $1":"$5"%"}')
    if [ ! -z "$CRITICAL_DISKS" ]; then
        check_status "Disk Space" "FAIL" "Critical disk usage: $CRITICAL_DISKS"
    else
        WARNING_DISKS=$(df -h | awk 'NR>1 {gsub(/%/,"",$5); if($5>80) print $1":"$5"%"}')
        if [ ! -z "$WARNING_DISKS" ]; then
            check_status "Disk Space" "WARN" "High disk usage: $WARNING_DISKS"
        else
            check_status "Disk Space" "PASS" "All disks have adequate free space"
        fi
    fi
    
    echo ""
}

# 2. Service Status Checks
service_status_checks() {
    echo -e "${PURPLE}⚙️  SERVICE STATUS CHECKS${NC}"
    echo "----------------------------------------"
    
    # Critical services to check
    CRITICAL_SERVICES=("ssh" "nginx" "apache2" "httpd" "mysql" "postgresql" "docker" "kubelet")
    
    for service in "${CRITICAL_SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$service.service"; then
            if systemctl is-active --quiet "$service"; then
                check_status "$service Service" "PASS" "Service is running"
            else
                check_status "$service Service" "FAIL" "Service is not running"
            fi
        fi
    done
    
    # Check for failed services
    FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
    if [ "$FAILED_SERVICES" -gt 0 ]; then
        FAILED_LIST=$(systemctl --failed --no-legend | awk '{print $1}' | tr '\n' ' ')
        check_status "Failed Services" "FAIL" "$FAILED_SERVICES failed services: $FAILED_LIST"
    else
        check_status "Failed Services" "PASS" "No failed services detected"
    fi
    
    echo ""
}

# 3. Network Connectivity Checks
network_checks() {
    echo -e "${PURPLE}🌐 NETWORK CONNECTIVITY CHECKS${NC}"
    echo "----------------------------------------"
    
    # Internet connectivity
    if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
        check_status "Internet Connectivity" "PASS" "External connectivity verified"
    else
        check_status "Internet Connectivity" "FAIL" "Cannot reach external servers"
    fi
    
    # DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        check_status "DNS Resolution" "PASS" "DNS resolution working"
    else
        check_status "DNS Resolution" "FAIL" "DNS resolution failed"
    fi
    
    # Critical ports
    CRITICAL_PORTS=("22:SSH" "80:HTTP" "443:HTTPS")
    for port_info in "${CRITICAL_PORTS[@]}"; do
        PORT=$(echo $port_info | cut -d: -f1)
        SERVICE=$(echo $port_info | cut -d: -f2)
        
        if netstat -tulpn | grep ":$PORT " >/dev/null; then
            check_status "$SERVICE Port ($PORT)" "PASS" "Port is listening"
        else
            check_status "$SERVICE Port ($PORT)" "WARN" "Port is not listening"
        fi
    done
    
    echo ""
}

# 4. Security Checks
security_checks() {
    echo -e "${PURPLE}🔒 SECURITY CHECKS${NC}"
    echo "----------------------------------------"
    
    # Check for recent failed SSH attempts
    FAILED_SSH=$(grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date +%b\ %d)" | wc -l)
    if [ "$FAILED_SSH" -gt 50 ]; then
        check_status "SSH Security" "FAIL" "$FAILED_SSH failed SSH attempts today"
    elif [ "$FAILED_SSH" -gt 20 ]; then
        check_status "SSH Security" "WARN" "$FAILED_SSH failed SSH attempts today"
    else
        check_status "SSH Security" "PASS" "SSH security normal ($FAILED_SSH failed attempts)"
    fi
    
    # Check for root login attempts
    ROOT_ATTEMPTS=$(grep "Failed password for root" /var/log/auth.log 2>/dev/null | grep "$(date +%b\ %d)" | wc -l)
    if [ "$ROOT_ATTEMPTS" -gt 0 ]; then
        check_status "Root Login Attempts" "WARN" "$ROOT_ATTEMPTS attempted root logins today"
    else
        check_status "Root Login Attempts" "PASS" "No root login attempts detected"
    fi
    
    # Check for users with empty passwords
    EMPTY_PASSWORDS=$(awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null | wc -l)
    if [ "$EMPTY_PASSWORDS" -gt 0 ]; then
        check_status "Password Security" "FAIL" "$EMPTY_PASSWORDS users with empty passwords"
    else
        check_status "Password Security" "PASS" "All users have passwords set"
    fi
    
    # Check for world-writable files
    WORLD_WRITABLE=$(find /etc /usr /var -type f -perm -002 2>/dev/null | wc -l)
    if [ "$WORLD_WRITABLE" -gt 0 ]; then
        check_status "File Permissions" "WARN" "$WORLD_WRITABLE world-writable files found"
    else
        check_status "File Permissions" "PASS" "No world-writable files in critical directories"
    fi
    
    echo ""
}

# 5. Backup Status Checks
backup_checks() {
    echo -e "${PURPLE}💾 BACKUP STATUS CHECKS${NC}"
    echo "----------------------------------------"
    
    # Check common backup directories
    BACKUP_DIRS=("/backup" "/var/backups" "/opt/backups")
    BACKUP_FOUND=false
    
    for backup_dir in "${BACKUP_DIRS[@]}"; do
        if [ -d "$backup_dir" ]; then
            BACKUP_FOUND=true
            LATEST_BACKUP=$(find "$backup_dir" -type f -name "*.tar.gz" -o -name "*.sql" -o -name "*.dump" 2>/dev/null | head -1)
            
            if [ ! -z "$LATEST_BACKUP" ]; then
                BACKUP_AGE=$(find "$backup_dir" -type f -mtime -1 2>/dev/null | wc -l)
                if [ "$BACKUP_AGE" -gt 0 ]; then
                    check_status "Recent Backups" "PASS" "Recent backups found in $backup_dir"
                else
                    check_status "Recent Backups" "WARN" "No recent backups in $backup_dir (>24hrs)"
                fi
            else
                check_status "Backup Directory" "WARN" "$backup_dir exists but no backup files found"
            fi
        fi
    done
    
    if [ "$BACKUP_FOUND" = false ]; then
        check_status "Backup System" "WARN" "No standard backup directories found"
    fi
    
    echo ""
}

# 6. SSL Certificate Checks
ssl_certificate_checks() {
    echo -e "${PURPLE}🔐 SSL CERTIFICATE CHECKS${NC}"
    echo "----------------------------------------"
    
    # Check common certificate locations
    CERT_LOCATIONS=("/etc/ssl/certs" "/etc/nginx/ssl" "/etc/apache2/ssl" "/etc/letsencrypt/live")
    
    for cert_dir in "${CERT_LOCATIONS[@]}"; do
        if [ -d "$cert_dir" ]; then
            # Find certificate files
            CERT_FILES=$(find "$cert_dir" -name "*.crt" -o -name "*.pem" 2>/dev/null)
            
            for cert_file in $CERT_FILES; do
                if [ -f "$cert_file" ]; then
                    EXPIRY_DATE=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
                    if [ ! -z "$EXPIRY_DATE" ]; then
                        EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
                        CURRENT_EPOCH=$(date +%s)
                        DAYS_UNTIL_EXPIRY=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))
                        
                        CERT_NAME=$(basename "$cert_file")
                        if [ "$DAYS_UNTIL_EXPIRY" -lt 7 ]; then
                            check_status "SSL Certificate $CERT_NAME" "FAIL" "Expires in $DAYS_UNTIL_EXPIRY days"
                        elif [ "$DAYS_UNTIL_EXPIRY" -lt "$CERT_EXPIRY_WARNING_DAYS" ]; then
                            check_status "SSL Certificate $CERT_NAME" "WARN" "Expires in $DAYS_UNTIL_EXPIRY days"
                        else
                            check_status "SSL Certificate $CERT_NAME" "PASS" "Valid for $DAYS_UNTIL_EXPIRY days"
                        fi
                    fi
                fi
            done
        fi
    done
    
    echo ""
}

# 7. Log File Checks
log_checks() {
    echo -e "${PURPLE}📋 LOG FILE CHECKS${NC}"
    echo "----------------------------------------"
    
    # Check log file sizes
    LARGE_LOGS=$(find /var/log -name "*.log" -size +100M 2>/dev/null)
    if [ ! -z "$LARGE_LOGS" ]; then
        LOG_COUNT=$(echo "$LARGE_LOGS" | wc -l)
        check_status "Log File Sizes" "WARN" "$LOG_COUNT log files are larger than 100MB"
    else
        check_status "Log File Sizes" "PASS" "All log files are reasonable size"
    fi
    
    # Check for critical errors in recent logs
    CRITICAL_ERRORS=$(grep -i "error\|critical\|fatal" /var/log/syslog 2>/dev/null | grep "$(date +%b\ %d)" | wc -l)
    if [ "$CRITICAL_ERRORS" -gt 20 ]; then
        check_status "System Errors" "FAIL" "$CRITICAL_ERRORS critical errors in today's logs"
    elif [ "$CRITICAL_ERRORS" -gt 5 ]; then
        check_status "System Errors" "WARN" "$CRITICAL_ERRORS errors in today's logs"
    else
        check_status "System Errors" "PASS" "Minimal errors in system logs"
    fi
    
    # Check log rotation
    if [ -f "/etc/logrotate.conf" ]; then
        check_status "Log Rotation" "PASS" "Logrotate is configured"
    else
        check_status "Log Rotation" "WARN" "Logrotate configuration not found"
    fi
    
    echo ""
}

# 8. Container and Orchestration Checks
container_checks() {
    echo -e "${PURPLE}🐳 CONTAINER & ORCHESTRATION CHECKS${NC}"
    echo "----------------------------------------"
    
    # Docker checks
    if command -v docker >/dev/null 2>&1; then
        if systemctl is-active --quiet docker; then
            check_status "Docker Service" "PASS" "Docker daemon is running"
            
            # Check container status
            RUNNING_CONTAINERS=$(docker ps -q | wc -l)
            FAILED_CONTAINERS=$(docker ps -a --filter "status=exited" --filter "status=dead" -q | wc -l)
            
            if [ "$FAILED_CONTAINERS" -gt 0 ]; then
                check_status "Container Health" "WARN" "$FAILED_CONTAINERS containers have failed"
            else
                check_status "Container Health" "PASS" "All $RUNNING_CONTAINERS containers are healthy"
            fi
            
            # Check Docker disk usage
            DOCKER_DISK=$(docker system df --format "table {{.Type}}\t{{.Size}}" | grep -v "TYPE" | awk '{total+=$2} END {print total}')
            if [ ! -z "$DOCKER_DISK" ] && [ "$DOCKER_DISK" -gt 50 ]; then
                check_status "Docker Disk Usage" "WARN" "Docker is using significant disk space"
            else
                check_status "Docker Disk Usage" "PASS" "Docker disk usage is reasonable"
            fi
        else
            check_status "Docker Service" "FAIL" "Docker daemon is not running"
        fi
    fi
    
    # Kubernetes checks
    if command -v kubectl >/dev/null 2>&1; then
        if kubectl cluster-info >/dev/null 2>&1; then
            check_status "Kubernetes Cluster" "PASS" "Cluster is accessible"
            
            # Check node status
            NOT_READY_NODES=$(kubectl get nodes --no-headers | grep -v "Ready" | wc -l)
            if [ "$NOT_READY_NODES" -gt 0 ]; then
                check_status "Kubernetes Nodes" "FAIL" "$NOT_READY_NODES nodes are not ready"
            else
                check_status "Kubernetes Nodes" "PASS" "All nodes are ready"
            fi
            
            # Check pod status
            PROBLEM_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers | wc -l)
            if [ "$PROBLEM_PODS" -gt 0 ]; then
                check_status "Kubernetes Pods" "WARN" "$PROBLEM_PODS pods have issues"
            else
                check_status "Kubernetes Pods" "PASS" "All pods are healthy"
            fi
        else
            check_status "Kubernetes Cluster" "FAIL" "Cannot connect to cluster"
        fi
    fi
    
    echo ""
}

# 9. Performance Monitoring
performance_checks() {
    echo -e "${PURPLE}📊 PERFORMANCE MONITORING${NC}"
    echo "----------------------------------------"
    
    # Check I/O wait
    IOWAIT=$(iostat 1 2 | tail -1 | awk '{print $4}' | cut -d. -f1)
    if [ "$IOWAIT" -gt 20 ]; then
        check_status "I/O Wait" "FAIL" "High I/O wait time: $IOWAIT%"
    elif [ "$IOWAIT" -gt 10 ]; then
        check_status "I/O Wait" "WARN" "Elevated I/O wait time: $IOWAIT%"
    else
        check_status "I/O Wait" "PASS" "I/O wait time is normal: $IOWAIT%"
    fi
    
    # Check swap usage
    SWAP_USAGE=$(free | grep Swap | awk '{if($2>0) printf("%.0f", $3/$2 * 100.0); else print "0"}')
    if [ "$SWAP_USAGE" -gt 50 ]; then
        check_status "Swap Usage" "WARN" "High swap usage: $SWAP_USAGE%"
    else
        check_status "Swap Usage" "PASS" "Swap usage is normal: $SWAP_USAGE%"
    fi
    
    # Check open file descriptors
    if [ -f "/proc/sys/fs/file-nr" ]; then
        OPEN_FILES=$(cat /proc/sys/fs/file-nr | awk '{print $1}')
        MAX_FILES=$(cat /proc/sys/fs/file-nr | awk '{print $3}')
        FILE_USAGE=$(echo "$OPEN_FILES * 100 / $MAX_FILES" | bc)
        
        if [ "$FILE_USAGE" -gt 80 ]; then
            check_status "File Descriptors" "WARN" "High file descriptor usage: $FILE_USAGE%"
        else
            check_status "File Descriptors" "PASS" "File descriptor usage normal: $FILE_USAGE%"
        fi
    fi
    
    echo ""
}

# Generate summary report
generate_summary() {
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${PURPLE}                     DAILY CHECKLIST SUMMARY                   ${NC}"
    echo -e "${PURPLE}================================================================${NC}"
    
    # Calculate percentages
    SUCCESS_RATE=$(echo "scale=1; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc)
    
    echo -e "${CYAN}Total Checks: $TOTAL_CHECKS${NC}"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_CHECKS${NC}"
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
    echo -e "${BLUE}Success Rate: $SUCCESS_RATE%${NC}"
    echo ""
    
    # Overall status
    if [ "$FAILED_CHECKS" -eq 0 ] && [ "$WARNING_CHECKS" -eq 0 ]; then
        echo -e "${GREEN}🎉 OVERALL STATUS: EXCELLENT${NC}"
        echo "All systems are operating normally."
    elif [ "$FAILED_CHECKS" -eq 0 ] && [ "$WARNING_CHECKS" -le 3 ]; then
        echo -e "${YELLOW}👍 OVERALL STATUS: GOOD${NC}"
        echo "Systems are stable with minor warnings."
    elif [ "$FAILED_CHECKS" -le 2 ]; then
        echo -e "${YELLOW}⚠️  OVERALL STATUS: NEEDS ATTENTION${NC}"
        echo "Some issues require attention but systems are functional."
    else
        echo -e "${RED}🚨 OVERALL STATUS: CRITICAL${NC}"
        echo "Multiple critical issues detected. Immediate action required."
    fi
    
    echo ""
    echo -e "${BLUE}Report generated: $(date)${NC}"
    echo -e "${BLUE}Log file: $LOGFILE${NC}"
    
    log_message "Daily checklist completed - Passed: $PASSED_CHECKS, Warnings: $WARNING_CHECKS, Failed: $FAILED_CHECKS"
}

# Action recommendations
action_recommendations() {
    echo ""
    echo -e "${BLUE}📋 RECOMMENDED ACTIONS${NC}"
    echo "----------------------------------------"
    
    if [ "$FAILED_CHECKS" -gt 0 ]; then
        echo "🔴 HIGH PRIORITY:"
        echo "   • Review failed checks immediately"
        echo "   • Address critical system issues"
        echo "   • Escalate if unable to resolve"
    fi
    
    if [ "$WARNING_CHECKS" -gt 0 ]; then
        echo "🟡 MEDIUM PRIORITY:"
        echo "   • Schedule maintenance for warnings"
        echo "   • Monitor trending issues"
        echo "   • Plan capacity upgrades if needed"
    fi
    
    echo "🟢 ROUTINE MAINTENANCE:"
    echo "   • Review logs for patterns"
    echo "   • Update security patches"
    echo "   • Verify backup integrity"
    echo "   • Check monitoring alerts"
    echo ""
}

# Main execution
main() {
    print_header
    
    system_health_checks
    service_status_checks
    network_checks
    security_checks
    backup_checks
    ssl_certificate_checks
    log_checks
    container_checks
    performance_checks
    
    generate_summary
    action_recommendations
    
    # Email report if configured
    if command -v mail >/dev/null 2>&1 && [ ! -z "$REPORT_EMAIL" ]; then
        echo "Sending report to $REPORT_EMAIL..."
        tail -100 "$LOGFILE" | mail -s "Daily Operations Report - $(hostname)" "$REPORT_EMAIL"
    fi
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOGFILE")"

# Run the checklist
main "$@"
