# 🎯 DevOps Interview Scenarios & Command Challenges

## 🎯 Real-World Scenarios for Interview Practice

This section contains **real-world troubleshooting scenarios** that are commonly asked in DevOps interviews. Each scenario includes the problem description, investigation steps, and complete solutions.

---

## 🚨 Critical Production Scenarios

### Scenario 1: "Production Server Running Out of Disk Space"
**Interview Question:** *"A production web server is running at 98% disk usage and users are complaining about service unavailability. Walk me through your troubleshooting steps."*

**Investigation Commands:**
```bash
# Step 1: Quick assessment
df -h
du -sh /* | sort -rh | head -10

# Step 2: Find large files
find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh | head -20

# Step 3: Check for deleted but open files
lsof +L1

# Step 4: Identify specific problem areas
du -sh /var/log/* | sort -rh | head -10
find /var/log -name "*.log" -size +50M -mtime -1

# Step 5: Safe cleanup actions
# Compress old logs
find /var/log -name "*.log" -mtime +7 -exec gzip {} \;

# Clean old rotated logs
find /var/log -name "*.log.[0-9]*" -mtime +30 -delete

# Truncate active large logs (if safe)
truncate -s 0 /var/log/large-application.log
```

**Expected Answer Flow:**
1. Assess severity and impact
2. Identify root cause quickly
3. Implement immediate safe fixes
4. Plan long-term prevention
5. Monitor and verify

---

### Scenario 2: "High Load Average and System Unresponsiveness"
**Interview Question:** *"The system load average is 15.0 on a 4-core server and users can't log in. How do you diagnose and fix this?"*

**Investigation Commands:**
```bash
# Step 1: Current system state
uptime
w  # Check logged in users
top -n 1 | head -20

# Step 2: Process analysis
ps aux --sort=-%cpu | head -20
ps aux --sort=-%mem | head -20

# Step 3: I/O wait analysis
iostat -x 1 5
iotop -ao  # Show processes doing I/O

# Step 4: Memory pressure check
free -h
cat /proc/meminfo | grep -E "(MemFree|MemAvailable|SwapFree)"
dmesg | grep -i "killed process"  # OOM killer

# Step 5: Detailed process investigation
pidstat -u 1 5  # CPU usage by process
pidstat -d 1 5  # Disk I/O by process

# Step 6: Emergency actions
# Kill runaway processes
pkill -f problematic_process_pattern

# Restart overloaded services
systemctl restart heavy_service

# Free memory caches if needed
sync && echo 3 > /proc/sys/vm/drop_caches
```

---

### Scenario 3: "Network Connectivity Issues"
**Interview Question:** *"Users report they can't access the company website, but internal services work fine. How do you troubleshoot this?"*

**Investigation Commands:**
```bash
# Step 1: Basic connectivity
ping 8.8.8.8  # Test internet
ping company-website.com  # Test specific site
nslookup company-website.com  # DNS resolution

# Step 2: Network path analysis
traceroute company-website.com
mtr --report company-website.com

# Step 3: Local network configuration
ip addr show
ip route show
cat /etc/resolv.conf

# Step 4: Service status
systemctl status nginx
systemctl status apache2
netstat -tulpn | grep :80
netstat -tulpn | grep :443

# Step 5: Firewall check
iptables -L -n
firewall-cmd --list-all  # If using firewalld

# Step 6: Log analysis
tail -f /var/log/nginx/error.log
tail -f /var/log/apache2/error.log
journalctl -u nginx -f
```

---

## 💡 Technical Deep-Dive Scenarios

### Scenario 4: "Database Performance Degradation"
**Interview Question:** *"The application database is running slowly, and query response times have increased 10x. How do you investigate?"*

**Investigation Commands:**
```bash
# Step 1: System resource check
top -p $(pgrep mysql)  # Database process
iostat -x 1 5  # Disk I/O
free -h  # Memory usage

# Step 2: Database-specific analysis
# MySQL
mysql -e "SHOW PROCESSLIST;"
mysql -e "SHOW ENGINE INNODB STATUS\G"
mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"

# PostgreSQL
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
sudo -u postgres psql -c "SELECT * FROM pg_stat_user_tables;"

# Step 3: Check for locks and blocking
mysql -e "SHOW OPEN TABLES WHERE In_use > 0;"
mysql -e "SELECT * FROM information_schema.INNODB_LOCKS;"

# Step 4: Log analysis
tail -f /var/log/mysql/slow.log
tail -f /var/log/mysql/error.log

# Step 5: System-level database monitoring
pidstat -d -p $(pgrep mysql) 1 5
lsof -p $(pgrep mysql) | grep -c "REG"  # Open files
```

---

### Scenario 5: "SSL Certificate Expiry Crisis"
**Interview Question:** *"Users are getting SSL certificate errors on your website. It's Saturday night and you need to fix it. What do you do?"*

**Investigation Commands:**
```bash
# Step 1: Check certificate status
openssl s_client -connect website.com:443 -servername website.com
echo | openssl s_client -connect website.com:443 2>/dev/null | openssl x509 -noout -dates

# Step 2: Check local certificate files
find /etc/ssl /etc/nginx /etc/apache2 -name "*.crt" -o -name "*.pem" | xargs -I {} openssl x509 -in {} -noout -subject -dates 2>/dev/null

# Step 3: Automated certificate check
for cert in /etc/ssl/certs/*.pem; do
    echo "Checking $cert"
    openssl x509 -in "$cert" -noout -enddate
done

# Step 4: Emergency renewal (Let's Encrypt)
certbot renew --dry-run
certbot renew --force-renewal

# Step 5: Service restart
nginx -t  # Test configuration
systemctl reload nginx

# Step 6: Verification
curl -I https://website.com
openssl s_client -connect website.com:443 | grep "Verify return code"
```

---

## 🔧 Container and Orchestration Scenarios

### Scenario 6: "Docker Container Won't Start"
**Interview Question:** *"A critical application container fails to start in production. How do you troubleshoot and fix it?"*

**Investigation Commands:**
```bash
# Step 1: Container status
docker ps -a
docker logs container_name
docker inspect container_name

# Step 2: Image investigation
docker images
docker history image_name
docker run --rm -it image_name /bin/bash  # Debug interactively

# Step 3: Resource constraints
docker stats
df -h  # Disk space
free -h  # Memory

# Step 4: Network issues
docker network ls
docker port container_name

# Step 5: Volume and mount issues
docker volume ls
docker inspect volume_name

# Step 6: Emergency restart strategies
docker restart container_name
docker rm container_name && docker run [original_parameters]

# Step 7: Health check debugging
docker exec container_name curl localhost:8080/health
```

---

### Scenario 7: "Kubernetes Pod CrashLoopBackOff"
**Interview Question:** *"A Kubernetes pod is in CrashLoopBackOff state and the application is down. Debug and fix it."*

**Investigation Commands:**
```bash
# Step 1: Pod status
kubectl get pods -o wide
kubectl describe pod pod_name

# Step 2: Log analysis
kubectl logs pod_name
kubectl logs pod_name --previous  # Previous container instance
kubectl logs pod_name -c container_name  # Multi-container pod

# Step 3: Resource investigation
kubectl top pod pod_name
kubectl describe node node_name

# Step 4: Configuration check
kubectl get pod pod_name -o yaml
kubectl get configmap
kubectl get secrets

# Step 5: Events analysis
kubectl get events --sort-by=.metadata.creationTimestamp

# Step 6: Debug with temporary pod
kubectl run debug-pod --image=busybox --rm -it -- /bin/sh

# Step 7: Health check debugging
kubectl exec pod_name -- curl localhost:8080/health
kubectl port-forward pod_name 8080:8080
```

---

## 🎪 Interactive Challenge Script

### Create an Interactive Interview Simulator

<function_calls>
<invoke name="create_file">
<parameter name="content">#!/bin/bash
# interview-simulator.sh - Interactive DevOps Interview Practice

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCORE=0
TOTAL_QUESTIONS=0

print_header() {
    clear
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  DevOps Interview Simulator    ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

ask_question() {
    local question="$1"
    local expected_cmd="$2"
    local explanation="$3"
    
    TOTAL_QUESTIONS=$((TOTAL_QUESTIONS + 1))
    
    echo -e "${YELLOW}Scenario $TOTAL_QUESTIONS:${NC}"
    echo "$question"
    echo ""
    echo -e "${BLUE}Your command:${NC}"
    read -r user_answer
    
    if [[ "$user_answer" == *"$expected_cmd"* ]]; then
        echo -e "${GREEN}✅ Correct!${NC}"
        SCORE=$((SCORE + 1))
    else
        echo -e "${RED}❌ Incorrect${NC}"
        echo -e "${GREEN}Expected command: $expected_cmd${NC}"
    fi
    
    echo -e "${BLUE}Explanation:${NC} $explanation"
    echo ""
    read -p "Press Enter to continue..."
    echo ""
}

scenario_disk_space() {
    print_header
    echo -e "${RED}🚨 EMERGENCY: Production server at 98% disk usage!${NC}"
    echo ""
    
    ask_question \
        "Q1: How do you quickly check which directories are using the most space?" \
        "du -sh /*" \
        "du -sh /* shows human-readable sizes for all top-level directories, helping identify the largest consumers."
    
    ask_question \
        "Q2: How do you find files larger than 100MB that might be safe to clean?" \
        "find / -type f -size +100M" \
        "This finds all files larger than 100MB. Add -mtime +30 to find old files that might be safe to remove."
    
    ask_question \
        "Q3: How do you check for deleted files that are still using disk space?" \
        "lsof +L1" \
        "lsof +L1 shows files that have been deleted but are still open by processes, preventing disk space recovery."
}

scenario_high_load() {
    print_header
    echo -e "${RED}🚨 EMERGENCY: System load average is 15.0 on a 4-core server!${NC}"
    echo ""
    
    ask_question \
        "Q1: How do you quickly identify which processes are consuming the most CPU?" \
        "ps aux --sort=-%cpu" \
        "This sorts processes by CPU usage in descending order, showing the biggest CPU consumers first."
    
    ask_question \
        "Q2: How do you check if high load is due to I/O wait?" \
        "iostat -x" \
        "iostat -x shows extended I/O statistics including %iowait, which indicates if processes are waiting for I/O."
    
    ask_question \
        "Q3: How do you check for memory pressure and potential OOM kills?" \
        "dmesg | grep -i killed" \
        "This searches kernel messages for OOM (Out of Memory) killer events that might explain system issues."
}

scenario_network() {
    print_header
    echo -e "${RED}🚨 NETWORK ISSUE: Users can't access the website!${NC}"
    echo ""
    
    ask_question \
        "Q1: How do you test if the web server process is listening on port 80?" \
        "netstat -tulpn | grep :80" \
        "This shows all processes listening on port 80. Alternative: ss -tulpn | grep :80"
    
    ask_question \
        "Q2: How do you trace the network path to identify where connectivity fails?" \
        "traceroute" \
        "traceroute shows the network path and identifies where packets are being dropped or delayed."
    
    ask_question \
        "Q3: How do you check if DNS resolution is working correctly?" \
        "nslookup" \
        "nslookup tests DNS resolution. Alternative commands: dig or host."
}

scenario_ssl() {
    print_header
    echo -e "${RED}🚨 SSL CRISIS: Certificate expired on production website!${NC}"
    echo ""
    
    ask_question \
        "Q1: How do you check the expiry date of an SSL certificate for a website?" \
        "openssl s_client -connect" \
        "openssl s_client -connect domain.com:443 | openssl x509 -noout -dates shows certificate validity dates."
    
    ask_question \
        "Q2: How do you renew a Let's Encrypt certificate?" \
        "certbot renew" \
        "certbot renew attempts to renew all certificates. Use --force-renewal for immediate renewal."
    
    ask_question \
        "Q3: After updating certificates, how do you reload nginx without downtime?" \
        "nginx -s reload" \
        "nginx -s reload reloads configuration without stopping the service. Alternative: systemctl reload nginx"
}

scenario_docker() {
    print_header
    echo -e "${RED}🚨 CONTAINER ISSUE: Application container won't start!${NC}"
    echo ""
    
    ask_question \
        "Q1: How do you check the logs of a failed container?" \
        "docker logs" \
        "docker logs container_name shows container output. Use --tail and -f for recent logs and following."
    
    ask_question \
        "Q2: How do you run a container interactively for debugging?" \
        "docker run -it" \
        "docker run -it image_name /bin/bash runs the container interactively with a shell for debugging."
    
    ask_question \
        "Q3: How do you check if the container has resource constraints?" \
        "docker stats" \
        "docker stats shows real-time resource usage (CPU, memory, I/O) for running containers."
}

scenario_kubernetes() {
    print_header
    echo -e "${RED}🚨 K8S ISSUE: Pod stuck in CrashLoopBackOff!${NC}"
    echo ""
    
    ask_question \
        "Q1: How do you get detailed information about why a pod is failing?" \
        "kubectl describe pod" \
        "kubectl describe pod shows events, conditions, and detailed status information about the pod."
    
    ask_question \
        "Q2: How do you check the logs of a crashed container in Kubernetes?" \
        "kubectl logs --previous" \
        "kubectl logs --previous shows logs from the previous container instance before it crashed."
    
    ask_question \
        "Q3: How do you check resource limits and requests for a pod?" \
        "kubectl get pod -o yaml" \
        "kubectl get pod -o yaml shows the complete pod specification including resource requests and limits."
}

show_results() {
    print_header
    echo -e "${BLUE}🎯 Interview Simulation Complete!${NC}"
    echo ""
    echo -e "Score: ${GREEN}$SCORE${NC} out of ${BLUE}$TOTAL_QUESTIONS${NC}"
    
    PERCENTAGE=$((SCORE * 100 / TOTAL_QUESTIONS))
    
    if [ $PERCENTAGE -ge 80 ]; then
        echo -e "${GREEN}🎉 Excellent! You're ready for senior DevOps interviews!${NC}"
    elif [ $PERCENTAGE -ge 60 ]; then
        echo -e "${YELLOW}👍 Good job! Review the areas you missed and practice more.${NC}"
    else
        echo -e "${RED}📚 Keep studying! Focus on hands-on practice with these commands.${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📖 Study Recommendations:${NC}"
    echo "1. Practice these commands on real systems"
    echo "2. Set up lab environments to simulate these scenarios"
    echo "3. Review the explanation guides in each section"
    echo "4. Time yourself - interviews have time pressure!"
    echo ""
}

main_menu() {
    while true; do
        print_header
        echo -e "${BLUE}Choose a scenario to practice:${NC}"
        echo ""
        echo "1. 💾 Disk Space Emergency"
        echo "2. 🔥 High Load Average Crisis"
        echo "3. 🌐 Network Connectivity Issues"
        echo "4. 🔒 SSL Certificate Expiry"
        echo "5. 🐳 Docker Container Problems"
        echo "6. ☸️  Kubernetes Pod Issues"
        echo "7. 🎯 Full Interview Simulation"
        echo "8. 📊 Exit"
        echo ""
        echo -e "${YELLOW}Enter your choice (1-8):${NC}"
        read -r choice
        
        case $choice in
            1) scenario_disk_space ;;
            2) scenario_high_load ;;
            3) scenario_network ;;
            4) scenario_ssl ;;
            5) scenario_docker ;;
            6) scenario_kubernetes ;;
            7) 
                scenario_disk_space
                scenario_high_load
                scenario_network
                scenario_ssl
                scenario_docker
                scenario_kubernetes
                show_results
                ;;
            8) 
                echo -e "${GREEN}Good luck with your interviews!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Start the simulator
main_menu
