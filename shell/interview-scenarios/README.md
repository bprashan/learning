# 🎯 DevOps Interview Scenarios & Command Challenges

## 🎯 Real-World Scenarios for Interview Practice

This section contains **real-world troubleshooting scenarios** that are commonly asked in DevOps interviews. Each scenario includes the problem description, investigation steps, and complete solutions.

## 📁 Contents

- **📋 README.md** - This comprehensive scenario guide
- **🎪 interview-simulator.sh** - Interactive Linux interview practice script
- **🎪 interview-simulator.ps1** - Interactive Windows PowerShell interview practice script
- **⚡ quick-health-check.sh** - Rapid system health assessment tool (Linux)
- **⚡ quick-health-check.ps1** - Rapid system health assessment tool (Windows)
- **📅 daily-ops-checklist.sh** - Comprehensive daily operations checklist

## 🚀 Quick Start

### For Linux Users:
```bash
# Make scripts executable
chmod +x *.sh

# Run interactive interview simulator
./interview-simulator.sh

# Perform quick health check
./quick-health-check.sh

# Run daily operations checklist
./daily-ops-checklist.sh
```

### For Windows Users:
```powershell
# Run interactive interview simulator
.\interview-simulator.ps1

# Perform quick health check
.\quick-health-check.ps1
```

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

## 🎪 Interactive Tools

### 🎯 Interview Simulator Scripts

#### Linux Version (interview-simulator.sh)
- **Interactive scenarios** with real-time scoring
- **Color-coded feedback** for correct/incorrect answers
- **Multiple difficulty levels** for progression
- **Complete explanations** for each command
- **Progress tracking** across sessions

#### Windows PowerShell Version (interview-simulator.ps1)
- **Windows-specific commands** and tools
- **PowerShell cmdlets** for system administration
- **Same interactive format** as Linux version
- **Cross-platform compatibility** notes

#### Usage:
```bash
# Linux
./interview-simulator.sh

# Windows
.\interview-simulator.ps1
```

---

## ⚡ Quick Health Check Tools

### 🏥 System Health Assessment

#### Linux Version (quick-health-check.sh)
- **Comprehensive system analysis** in under 30 seconds
- **Color-coded alerts** for critical issues
- **Automated threshold checking** for CPU, memory, disk
- **Service status verification**
- **Security checks** for common vulnerabilities
- **Docker and Kubernetes integration**

#### Windows Version (quick-health-check.ps1)
- **Windows-specific health metrics**
- **PowerShell-based system analysis**
- **Event log monitoring**
- **Service status checking**
- **Performance counter integration**

#### Features:
- 🔥 System load and CPU usage
- 💾 Memory and swap utilization
- 💿 Disk space monitoring
- 🌐 Network connectivity tests
- ⚙️ Critical service status
- 🔒 Security assessment
- 🐳 Container health (if available)
- ☸️ Kubernetes cluster status (if available)

#### Usage:
```bash
# Linux - Quick health check
./quick-health-check.sh

# Windows - PowerShell health check
.\quick-health-check.ps1
```

---

## 📅 Daily Operations Checklist

### 📋 Comprehensive Daily Operations (daily-ops-checklist.sh)

#### Complete System Audit Tool
- **90+ automated checks** across all system areas
- **Detailed logging** with timestamps
- **Email reporting** capability
- **Action recommendations** based on findings
- **Compliance tracking** for security standards

#### Check Categories:
1. **🏥 System Health** - Load, memory, disk, uptime
2. **⚙️ Service Status** - Critical services and failed units
3. **🌐 Network** - Connectivity, DNS, port status
4. **🔒 Security** - Failed logins, permissions, vulnerabilities
5. **💾 Backups** - Recent backup verification
6. **🔐 SSL Certificates** - Expiry warnings and renewals
7. **📋 Log Files** - Error analysis and rotation
8. **🐳 Containers** - Docker and Kubernetes health
9. **📊 Performance** - I/O wait, swap usage, file descriptors

#### Sample Output:
```
✅ [PASS] System Uptime - System uptime is healthy
⚠️  [WARN] Load Average - Load average 2.1 is elevated for 2 cores
✅ [PASS] Memory Usage - Memory usage is normal (67%)
❌ [FAIL] Disk Space - Critical disk usage: /dev/sda1:91%
✅ [PASS] SSH Service - Service is running
```

#### Usage:
```bash
# Run complete daily checklist
./daily-ops-checklist.sh

# View generated log
tail -f /var/log/daily-ops-checklist.log
```

---

## 🎯 Interview Success Tips

### 📚 Study Strategy

1. **Practice Regularly**
   - Use the interactive simulators daily
   - Time yourself on scenario solutions
   - Practice explaining your thought process

2. **Understand the Why**
   - Don't just memorize commands
   - Understand when and why to use each tool
   - Learn to troubleshoot when commands don't work

3. **Build Mental Models**
   - Create flowcharts for common scenarios
   - Understand system interactions
   - Practice systematic troubleshooting

4. **Hands-On Experience**
   - Set up lab environments
   - Break things intentionally and fix them
   - Practice on different operating systems

### 🎭 Interview Performance Tips

1. **Structured Approach**
   - Always start with assessment of impact and urgency
   - Gather information before taking action
   - Explain your reasoning throughout

2. **Communication**
   - Think out loud during problem-solving
   - Ask clarifying questions about the environment
   - Explain trade-offs in your solutions

3. **Real-World Considerations**
   - Consider security implications
   - Think about impact on users
   - Plan for monitoring and prevention

4. **Follow-Up Actions**
   - Always verify your fixes worked
   - Consider long-term improvements
   - Document lessons learned

---

## 🔗 Related Study Materials

- **[01-disk-management](../01-disk-management/)** - Comprehensive disk commands
- **[02-cpu-memory-monitoring](../02-cpu-memory-monitoring/)** - Performance analysis tools
- **[03-networking-commands](../03-networking-commands/)** - Network troubleshooting
- **[04-file-management](../04-file-management/)** - File system operations
- **[05-process-management](../05-process-management/)** - Process control and monitoring
- **[06-os-kernel-info](../06-os-kernel-info/)** - System information commands
- **[07-virtualization-qemu-kvm](../07-virtualization-qemu-kvm/)** - Virtualization management

---

## 📖 Additional Resources

### 📚 Interview Preparation
- Practice on [LeetCode](https://leetcode.com) for algorithmic thinking
- Use [HackerRank](https://hackerrank.com) for system administration
- Study [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### 🛠️ Lab Environments
- **VirtualBox/VMware** for local testing
- **AWS Free Tier** for cloud practice
- **Docker Desktop** for container scenarios
- **Minikube** for Kubernetes learning

### 📜 Documentation
- **Linux man pages** - `man command_name`
- **Red Hat Enterprise Linux docs**
- **Ubuntu Server documentation**
- **Docker official documentation**
- **Kubernetes official tutorials**

---

## 🎯 Final Thoughts

> **"The best way to learn is by doing. The best way to interview is by practicing real scenarios."**

These scenarios and tools are designed to bridge the gap between theoretical knowledge and practical application. Use them regularly, customize them for your environment, and most importantly, understand the principles behind each solution.

Remember: In DevOps interviews, **problem-solving methodology** is often more important than memorizing specific commands. Show your systematic approach, explain your reasoning, and demonstrate how you would prevent similar issues in the future.

**Good luck with your interviews! 🚀**
