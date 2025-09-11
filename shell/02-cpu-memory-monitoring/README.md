# 🧠 CPU & Memory Monitoring Commands

## 🎯 Interview Focus Areas
- Performance bottleneck identification
- Memory leak detection and resolution
- CPU utilization optimization
- Load average interpretation
- Process resource consumption analysis

---

## 🟢 Basic CPU & Memory Commands

### System Overview
```bash
# Quick system status
top
htop  # Enhanced version with better UI
atop  # Advanced system monitor

# Load averages
uptime
w  # Who is logged in and load
cat /proc/loadavg

# CPU information
lscpu
cat /proc/cpuinfo
nproc  # Number of processors
```

### Memory Overview
```bash
# Memory usage
free -h
free -m  # In megabytes
cat /proc/meminfo

# Memory by process
ps aux --sort=-%mem | head -10
ps aux --sort=-%cpu | head -10

# Swap usage
swapon --show
cat /proc/swaps
```

---

## 🟡 Intermediate Monitoring

### Advanced CPU Monitoring
```bash
# CPU usage per core
mpstat -P ALL 1 5
iostat -c 1 5  # CPU utilization

# Process CPU usage
pidstat -p ALL 1 5
pidstat -u 1 5  # CPU statistics

# CPU frequency and scaling
cpufreq-info
cat /proc/cpuinfo | grep MHz
```

### Memory Deep Dive
```bash
# Memory usage by process
pmap -d <PID>  # Memory map of process
smaps <PID>    # Detailed memory usage

# Virtual memory statistics
vmstat 1 5
vmstat -s  # Summary statistics

# Page fault analysis
sar -B 1 5  # Paging statistics
```

### System Resource Monitoring
```bash
# Overall system activity
sar -u 1 5   # CPU utilization
sar -r 1 5   # Memory utilization
sar -q 1 5   # Load average and run queue

# Historical data
sar -u -f /var/log/sa/sa$(date +%d)  # Yesterday's CPU data
```

---

## 🔴 Expert Level Monitoring

### Performance Profiling
```bash
# CPU profiling with perf
perf top  # Real-time CPU profiling
perf record -g ./application
perf report  # Analyze recorded data

# System call tracing
strace -p <PID>  # Trace system calls
strace -c ./application  # Count system calls

# Advanced process monitoring
lsof -p <PID>  # Open files by process
/proc/<PID>/status  # Detailed process status
```

### Memory Analysis
```bash
# Memory fragmentation
cat /proc/buddyinfo
cat /proc/pagetypeinfo

# NUMA analysis
numactl --hardware
numastat
numastat -p <PID>

# Memory allocation tracking
valgrind --tool=massif ./application
cat /proc/<PID>/smaps | grep -E "(Size|Rss|Pss)"
```

### Advanced Monitoring Tools
```bash
# System activity reporter
sadc 1 60 /tmp/sysact.log  # Collect data
sar -A -f /tmp/sysact.log   # Analyze data

# Process accounting
accton /var/log/pacct
lastcomm  # Show process accounting info

# Kernel tracing
ftrace  # Function tracer
trace-cmd record -p function_graph
```

---

## 🚨 Production Troubleshooting Scenarios

### Scenario 1: High CPU Usage
```bash
# Identify CPU-hungry processes
top -o %CPU
ps aux --sort=-%cpu | head -20

# Detailed CPU analysis
pidstat -u 1 10
mpstat -P ALL 1 10

# Check for specific issues
# - Context switching
pidstat -w 1 5
# - Interrupts
cat /proc/interrupts
watch -n1 cat /proc/interrupts

# CPU throttling check
dmesg | grep -i "cpu.*throttl"
```

### Scenario 2: Memory Exhaustion
```bash
# Immediate memory check
free -h
ps aux --sort=-%mem | head -20

# Memory leak detection
while true; do
    echo "$(date): $(free -m | grep Mem:)"
    sleep 60
done

# OOM killer analysis
dmesg | grep -i "killed process"
journalctl -k | grep -i "killed process"

# Memory cleanup
echo 3 > /proc/sys/vm/drop_caches  # Clear caches
sync && echo 1 > /proc/sys/vm/drop_caches  # Page cache only
```

### Scenario 3: Load Average Issues
```bash
# Load average analysis
uptime
cat /proc/loadavg

# Running vs waiting processes
ps -eo state,pid,comm | grep -E "^(R|D)"

# I/O wait analysis
iostat -x 1 5
iotop -ao

# Process states breakdown
ps aux | awk '{print $8}' | sort | uniq -c
```

---

## 📊 Monitoring Scripts

### CPU Monitoring Script
```bash
#!/bin/bash
# cpu-monitor.sh

THRESHOLD=80
LOG_FILE="/var/log/cpu-monitor.log"

while true; do
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    CPU_PERCENT=${CPU_USAGE%.*}
    
    if [ "$CPU_PERCENT" -gt "$THRESHOLD" ]; then
        echo "$(date): High CPU usage: ${CPU_USAGE}%" | tee -a $LOG_FILE
        
        # Log top processes
        echo "Top CPU processes:" >> $LOG_FILE
        ps aux --sort=-%cpu | head -5 >> $LOG_FILE
        echo "---" >> $LOG_FILE
    fi
    
    sleep 60
done
```

### Memory Monitoring Script
```bash
#!/bin/bash
# memory-monitor.sh

THRESHOLD=90
LOG_FILE="/var/log/memory-monitor.log"

while true; do
    MEM_USAGE=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100)}')
    MEM_PERCENT=${MEM_USAGE%.*}
    
    if [ "$MEM_PERCENT" -gt "$THRESHOLD" ]; then
        echo "$(date): High memory usage: ${MEM_USAGE}%" | tee -a $LOG_FILE
        
        # Log memory details
        free -h >> $LOG_FILE
        echo "Top memory processes:" >> $LOG_FILE
        ps aux --sort=-%mem | head -5 >> $LOG_FILE
        echo "---" >> $LOG_FILE
    fi
    
    sleep 60
done
```

### Comprehensive System Monitor
```bash
#!/bin/bash
# system-health-monitor.sh

LOG_FILE="/var/log/system-health.log"
DATE=$(date)

echo "=== System Health Report - $DATE ===" | tee -a $LOG_FILE

# CPU Information
echo -e "\n1. CPU Usage:" | tee -a $LOG_FILE
mpstat 1 1 | tail -1 | tee -a $LOG_FILE

# Memory Information
echo -e "\n2. Memory Usage:" | tee -a $LOG_FILE
free -h | tee -a $LOG_FILE

# Load Average
echo -e "\n3. Load Average:" | tee -a $LOG_FILE
uptime | tee -a $LOG_FILE

# Top Processes by CPU
echo -e "\n4. Top CPU Processes:" | tee -a $LOG_FILE
ps aux --sort=-%cpu | head -5 | tee -a $LOG_FILE

# Top Processes by Memory
echo -e "\n5. Top Memory Processes:" | tee -a $LOG_FILE
ps aux --sort=-%mem | head -5 | tee -a $LOG_FILE

# Disk I/O
echo -e "\n6. Disk I/O:" | tee -a $LOG_FILE
iostat -x 1 1 | tail -n +4 | tee -a $LOG_FILE

echo "=================================" | tee -a $LOG_FILE
```

---

## 🎯 Performance Tuning Commands

### CPU Optimization
```bash
# CPU scaling governor
echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
cpufreq-set -g performance

# CPU affinity
taskset -c 0,1 ./cpu_intensive_app
numactl --cpubind=0 --membind=0 ./application

# IRQ balancing
irqbalance --oneshot
echo 2 > /proc/irq/24/smp_affinity  # Bind IRQ to CPU 1
```

### Memory Optimization
```bash
# Swappiness tuning
echo 10 > /proc/sys/vm/swappiness  # Reduce swap usage

# Memory overcommit
echo 2 > /proc/sys/vm/overcommit_memory
echo 80 > /proc/sys/vm/overcommit_ratio

# Huge pages configuration
echo 1024 > /proc/sys/vm/nr_hugepages
hugeadm --pool-list

# Memory compaction
echo 1 > /proc/sys/vm/compact_memory
```

---

## 🎯 Interview Questions & Answers

### Q1: "Explain load average and when it becomes concerning"
**Answer:**
```bash
# Load average shows:
# - 1-minute, 5-minute, 15-minute averages
# - Number of processes waiting for CPU or I/O

uptime
# Example output: load average: 2.1, 1.8, 1.5

# Rule of thumb:
# - Load = Number of CPU cores: OK
# - Load > Number of CPU cores: Concerning
# - Load > 2x CPU cores: Critical

# Check number of CPUs
nproc
# If 4 CPUs and load is 8.0, system is overloaded
```

### Q2: "How do you identify a memory leak?"
**Answer:**
```bash
# 1. Monitor memory growth over time
while true; do
    echo "$(date): $(ps -o pid,vsz,rss,comm -p <PID>)"
    sleep 300
done

# 2. Use valgrind for detailed analysis
valgrind --tool=memcheck --leak-check=full ./application

# 3. Monitor with smem
smem -p -k -c "pid pss uss comm"

# 4. Check /proc/meminfo trends
watch -n 5 'cat /proc/meminfo | grep -E "(MemFree|MemAvailable|Buffers|Cached)"'
```

### Q3: "What causes high iowait and how do you troubleshoot it?"
**Answer:**
```bash
# High iowait indicates processes waiting for I/O

# 1. Identify I/O bottlenecks
iostat -x 1 5  # Look for high %util
iotop -ao      # See which processes doing I/O

# 2. Check disk health
smartctl -a /dev/sda

# 3. Analyze I/O patterns
pidstat -d 1 5  # I/O by process
lsof +L1        # Find deleted but open files

# 4. Optimize I/O
# - Change I/O scheduler
echo deadline > /sys/block/sda/queue/scheduler
# - Increase read-ahead
blockdev --setra 256 /dev/sda
```

---

## 📈 Real-time Monitoring Dashboard

### One-liner System Status
```bash
# Complete system overview
echo "CPU: $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage "%"}') | MEM: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100}') | LOAD: $(uptime | awk -F'load average:' '{print $2}') | DISK: $(df -h / | awk 'NR==2{print $5}')"
```

### Continuous Monitoring
```bash
#!/bin/bash
# live-monitor.sh
while true; do
    clear
    echo "=== LIVE SYSTEM MONITOR ==="
    echo "Time: $(date)"
    echo "Uptime: $(uptime)"
    echo ""
    echo "=== CPU ==="
    mpstat 1 1 | tail -1
    echo ""
    echo "=== MEMORY ==="
    free -h
    echo ""
    echo "=== TOP PROCESSES ==="
    ps aux --sort=-%cpu | head -6
    sleep 5
done
```

This comprehensive guide provides all the CPU and memory monitoring commands essential for DevOps interviews and daily operations!
