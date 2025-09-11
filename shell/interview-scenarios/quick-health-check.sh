#!/bin/bash
# quick-health-check.sh - Rapid system health assessment for DevOps engineers

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=85
LOAD_THRESHOLD=5

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}          DevOps System Health Check           ${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo -e "${CYAN}Timestamp: $(date)${NC}"
    echo -e "${CYAN}Hostname: $(hostname)${NC}"
    echo -e "${CYAN}Uptime: $(uptime -p 2>/dev/null || uptime)${NC}"
    echo ""
}

check_system_load() {
    echo -e "${YELLOW}🔥 SYSTEM LOAD${NC}"
    echo "----------------------------------------"
    
    LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    CORES=$(nproc)
    
    echo "Load Average: $LOAD_1MIN (1min) / $CORES cores"
    
    # Calculate load percentage
    LOAD_PERCENT=$(echo "$LOAD_1MIN * 100 / $CORES" | bc -l | cut -d. -f1 2>/dev/null || echo "0")
    
    if [ "$LOAD_PERCENT" -gt "$LOAD_THRESHOLD" ]; then
        echo -e "${RED}⚠️  HIGH LOAD WARNING!${NC} Load is ${LOAD_PERCENT}% of available cores"
        echo "Top CPU consumers:"
        ps aux --sort=-%cpu | head -6 | tail -5
    else
        echo -e "${GREEN}✅ Load is normal${NC}"
    fi
    echo ""
}

check_memory() {
    echo -e "${YELLOW}💾 MEMORY USAGE${NC}"
    echo "----------------------------------------"
    
    # Get memory info
    MEMORY_INFO=$(free | grep Mem)
    TOTAL_MEM=$(echo $MEMORY_INFO | awk '{print $2}')
    USED_MEM=$(echo $MEMORY_INFO | awk '{print $3}')
    AVAILABLE_MEM=$(echo $MEMORY_INFO | awk '{print $7}')
    
    MEMORY_PERCENT=$(echo "$USED_MEM * 100 / $TOTAL_MEM" | bc)
    
    echo "Memory Usage: ${MEMORY_PERCENT}%"
    free -h
    
    if [ "$MEMORY_PERCENT" -gt "$MEMORY_THRESHOLD" ]; then
        echo -e "${RED}⚠️  HIGH MEMORY WARNING!${NC}"
        echo "Top memory consumers:"
        ps aux --sort=-%mem | head -6 | tail -5
        
        # Check for OOM kills
        OOM_KILLS=$(dmesg | grep -i "killed process" | tail -3)
        if [ ! -z "$OOM_KILLS" ]; then
            echo -e "${RED}Recent OOM kills detected:${NC}"
            echo "$OOM_KILLS"
        fi
    else
        echo -e "${GREEN}✅ Memory usage is normal${NC}"
    fi
    echo ""
}

check_disk_space() {
    echo -e "${YELLOW}💿 DISK SPACE${NC}"
    echo "----------------------------------------"
    
    df -h | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{print $1 " " $5 " " $6}' | while read filesystem usage mountpoint; do
        usage_percent=$(echo $usage | sed 's/%//g')
        
        if [ "$usage_percent" -gt "$DISK_THRESHOLD" ]; then
            echo -e "${RED}⚠️  $filesystem mounted on $mountpoint is ${usage}% full${NC}"
            
            # Show largest directories
            echo "Largest directories in $mountpoint:"
            du -sh $mountpoint/* 2>/dev/null | sort -rh | head -5
        else
            echo -e "${GREEN}✅ $filesystem mounted on $mountpoint: ${usage}${NC}"
        fi
    done
    echo ""
}

check_network() {
    echo -e "${YELLOW}🌐 NETWORK STATUS${NC}"
    echo "----------------------------------------"
    
    # Check network interfaces
    echo "Active network interfaces:"
    ip addr show | grep "state UP" | awk '{print $2}' | sed 's/://'
    
    # Test connectivity
    echo "Connectivity tests:"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Internet connectivity: OK${NC}"
    else
        echo -e "${RED}❌ Internet connectivity: FAILED${NC}"
    fi
    
    # Check listening ports
    echo "Critical services listening:"
    netstat -tulpn 2>/dev/null | grep -E ':22|:80|:443|:3306|:5432' | while read line; do
        port=$(echo $line | awk '{print $4}' | awk -F: '{print $NF}')
        case $port in
            22) echo -e "${GREEN}✅ SSH (22): Running${NC}" ;;
            80) echo -e "${GREEN}✅ HTTP (80): Running${NC}" ;;
            443) echo -e "${GREEN}✅ HTTPS (443): Running${NC}" ;;
            3306) echo -e "${GREEN}✅ MySQL (3306): Running${NC}" ;;
            5432) echo -e "${GREEN}✅ PostgreSQL (5432): Running${NC}" ;;
        esac
    done
    echo ""
}

check_services() {
    echo -e "${YELLOW}⚙️  CRITICAL SERVICES${NC}"
    echo "----------------------------------------"
    
    # Common critical services
    SERVICES=("ssh" "nginx" "apache2" "httpd" "mysql" "postgresql" "docker" "kubelet")
    
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet $service 2>/dev/null; then
            echo -e "${GREEN}✅ $service: Running${NC}"
        elif systemctl list-unit-files | grep -q "^$service.service"; then
            echo -e "${RED}❌ $service: Stopped${NC}"
        fi
    done
    echo ""
}

check_logs() {
    echo -e "${YELLOW}📋 RECENT LOG ISSUES${NC}"
    echo "----------------------------------------"
    
    # Check for recent errors in system logs
    ERROR_COUNT=$(journalctl --since "1 hour ago" --priority=err | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "${RED}⚠️  $ERROR_COUNT errors in the last hour${NC}"
        echo "Recent critical errors:"
        journalctl --since "1 hour ago" --priority=err --no-pager | tail -5
    else
        echo -e "${GREEN}✅ No critical errors in the last hour${NC}"
    fi
    
    # Check authentication failures
    AUTH_FAILURES=$(journalctl --since "1 hour ago" | grep -i "authentication failure\|failed password" | wc -l)
    if [ "$AUTH_FAILURES" -gt 10 ]; then
        echo -e "${RED}⚠️  $AUTH_FAILURES authentication failures in the last hour${NC}"
    else
        echo -e "${GREEN}✅ Authentication: Normal activity${NC}"
    fi
    echo ""
}

check_security() {
    echo -e "${YELLOW}🔒 SECURITY STATUS${NC}"
    echo "----------------------------------------"
    
    # Check for users with sudo access
    SUDO_USERS=$(grep -E '^sudo:' /etc/group | cut -d: -f4)
    echo "Users with sudo access: $SUDO_USERS"
    
    # Check for users with bash shells
    SHELL_USERS=$(grep "/bin/bash" /etc/passwd | wc -l)
    echo "Users with shell access: $SHELL_USERS"
    
    # Check for failed login attempts
    FAILED_LOGINS=$(lastb 2>/dev/null | head -10 | wc -l)
    if [ "$FAILED_LOGINS" -gt 5 ]; then
        echo -e "${RED}⚠️  $FAILED_LOGINS recent failed login attempts${NC}"
        echo "Recent failed logins:"
        lastb 2>/dev/null | head -5
    else
        echo -e "${GREEN}✅ Login security: Normal${NC}"
    fi
    echo ""
}

check_docker() {
    echo -e "${YELLOW}🐳 DOCKER STATUS${NC}"
    echo "----------------------------------------"
    
    if command -v docker >/dev/null 2>&1; then
        if systemctl is-active --quiet docker; then
            echo -e "${GREEN}✅ Docker daemon: Running${NC}"
            
            # Container status
            RUNNING_CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -c "Up")
            TOTAL_CONTAINERS=$(docker ps -a --format "table {{.Names}}" | wc -l)
            echo "Containers: $RUNNING_CONTAINERS running / $TOTAL_CONTAINERS total"
            
            # Show problematic containers
            FAILED_CONTAINERS=$(docker ps -a --filter "status=exited" --filter "status=dead" --format "{{.Names}}")
            if [ ! -z "$FAILED_CONTAINERS" ]; then
                echo -e "${RED}⚠️  Failed containers:${NC}"
                echo "$FAILED_CONTAINERS"
            fi
            
            # Disk usage
            echo "Docker disk usage:"
            docker system df
        else
            echo -e "${RED}❌ Docker daemon: Stopped${NC}"
        fi
    else
        echo "Docker: Not installed"
    fi
    echo ""
}

check_kubernetes() {
    echo -e "${YELLOW}☸️  KUBERNETES STATUS${NC}"
    echo "----------------------------------------"
    
    if command -v kubectl >/dev/null 2>&1; then
        # Check if kubectl can connect
        if kubectl cluster-info >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Kubernetes cluster: Accessible${NC}"
            
            # Node status
            echo "Node status:"
            kubectl get nodes --no-headers | while read line; do
                node=$(echo $line | awk '{print $1}')
                status=$(echo $line | awk '{print $2}')
                if [ "$status" = "Ready" ]; then
                    echo -e "${GREEN}✅ $node: $status${NC}"
                else
                    echo -e "${RED}❌ $node: $status${NC}"
                fi
            done
            
            # Pod issues
            PROBLEM_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded | grep -v "NAME" | wc -l)
            if [ "$PROBLEM_PODS" -gt 0 ]; then
                echo -e "${RED}⚠️  $PROBLEM_PODS pods with issues${NC}"
                kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded
            else
                echo -e "${GREEN}✅ All pods: Healthy${NC}"
            fi
        else
            echo -e "${RED}❌ Kubernetes cluster: Not accessible${NC}"
        fi
    else
        echo "kubectl: Not installed"
    fi
    echo ""
}

generate_summary() {
    echo -e "${PURPLE}===============================================${NC}"
    echo -e "${PURPLE}                 SUMMARY                      ${NC}"
    echo -e "${PURPLE}===============================================${NC}"
    
    # Overall health score (basic implementation)
    ISSUES=0
    
    # Check if any critical thresholds exceeded
    LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    CORES=$(nproc)
    LOAD_PERCENT=$(echo "$LOAD_1MIN * 100 / $CORES" | bc -l | cut -d. -f1 2>/dev/null || echo "0")
    [ "$LOAD_PERCENT" -gt "$LOAD_THRESHOLD" ] && ISSUES=$((ISSUES + 1))
    
    MEMORY_INFO=$(free | grep Mem)
    TOTAL_MEM=$(echo $MEMORY_INFO | awk '{print $2}')
    USED_MEM=$(echo $MEMORY_INFO | awk '{print $3}')
    MEMORY_PERCENT=$(echo "$USED_MEM * 100 / $TOTAL_MEM" | bc)
    [ "$MEMORY_PERCENT" -gt "$MEMORY_THRESHOLD" ] && ISSUES=$((ISSUES + 1))
    
    HIGH_DISK=$(df -h | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{print $5}' | sed 's/%//g' | awk -v threshold="$DISK_THRESHOLD" '$1 > threshold' | wc -l)
    [ "$HIGH_DISK" -gt 0 ] && ISSUES=$((ISSUES + 1))
    
    if [ "$ISSUES" -eq 0 ]; then
        echo -e "${GREEN}🎉 SYSTEM STATUS: HEALTHY${NC}"
        echo "All critical metrics are within normal ranges."
    elif [ "$ISSUES" -le 2 ]; then
        echo -e "${YELLOW}⚠️  SYSTEM STATUS: WARNING${NC}"
        echo "Some metrics need attention but system is stable."
    else
        echo -e "${RED}🚨 SYSTEM STATUS: CRITICAL${NC}"
        echo "Multiple issues detected. Immediate attention required."
    fi
    
    echo ""
    echo "Quick actions available:"
    echo "• View detailed logs: journalctl -f"
    echo "• Monitor resources: htop"
    echo "• Check disk usage: ncdu /"
    echo "• Network monitoring: netstat -tulpn"
    echo ""
}

main() {
    print_header
    check_system_load
    check_memory
    check_disk_space
    check_network
    check_services
    check_logs
    check_security
    
    # Optional components (only if available)
    if command -v docker >/dev/null 2>&1; then
        check_docker
    fi
    
    if command -v kubectl >/dev/null 2>&1; then
        check_kubernetes
    fi
    
    generate_summary
}

# Run the health check
main "$@"
