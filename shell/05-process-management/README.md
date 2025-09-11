# ⚙️ Process Management Commands

## 🎯 Interview Focus Areas
- Process lifecycle and states
- Signal handling and process control
- Job scheduling and automation
- Performance monitoring and optimization
- Troubleshooting runaway processes
- System service management

---

## 🟢 Basic Process Commands

### Process Information
```bash
# List processes
ps aux
ps -ef
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu

# Process tree
pstree
pstree -p  # Show PIDs
ps axjf    # Process tree with ps

# Real-time process monitoring
top
htop  # Enhanced version
atop  # Advanced system activity monitor
```

### Process Control
```bash
# Background and foreground jobs
command &  # Run in background
jobs       # List active jobs
fg %1      # Bring job 1 to foreground
bg %1      # Send job 1 to background
nohup command &  # Run immune to hangups

# Process termination
kill PID
kill -TERM PID  # Graceful termination
kill -KILL PID  # Force kill
kill -9 PID     # Same as KILL
killall process_name
pkill -f pattern
```

---

## 🟡 Intermediate Process Management

### Signal Management
```bash
# Common signals
kill -l  # List all signals

# Signal examples
kill -HUP PID    # Reload configuration (1)
kill -INT PID    # Interrupt (2)
kill -QUIT PID   # Quit (3)
kill -TERM PID   # Terminate (15)
kill -KILL PID   # Kill (9)
kill -STOP PID   # Stop (19)
kill -CONT PID   # Continue (18)
kill -USR1 PID   # User-defined signal 1 (10)
kill -USR2 PID   # User-defined signal 2 (12)
```

### Process Priorities
```bash
# Nice values (-20 to 19, lower = higher priority)
nice -n 10 command
renice 5 -p PID
renice -10 -u username

# Check process priority
ps -eo pid,ni,cmd

# Real-time priorities (requires root)
chrt -f -p 99 PID  # FIFO scheduling
chrt -r -p 50 PID  # Round-robin scheduling
```

### Process Monitoring
```bash
# Detailed process information
ps -o pid,ppid,cmd,wchan PID
cat /proc/PID/status
cat /proc/PID/cmdline
cat /proc/PID/environ

# Process resource usage
pidstat -p PID 1 5  # CPU usage
pidstat -r -p PID 1 5  # Memory usage
pidstat -d -p PID 1 5  # I/O usage

# Memory maps
pmap -d PID
cat /proc/PID/maps
```

---

## 🔴 Expert Level Process Management

### Advanced Process Control
```bash
# Process namespaces
unshare --pid --fork --mount-proc bash
ps aux  # Will show different process tree

# Control groups (cgroups)
cgcreate -g cpu,memory:/mygroup
cgset -r cpu.shares=512 mygroup
cgexec -g cpu,memory:mygroup command

# Process accounting
accton /var/log/pacct
lastcomm  # Show process accounting info
sa -u     # Show user accounting summary
```

### System Service Management
```bash
# Systemd service management
systemctl status service_name
systemctl start service_name
systemctl stop service_name
systemctl restart service_name
systemctl reload service_name
systemctl enable service_name
systemctl disable service_name

# Service information
systemctl list-units --type=service
systemctl list-unit-files --type=service
systemctl show service_name
journalctl -u service_name -f
```

### Job Scheduling
```bash
# Cron jobs
crontab -l  # List user cron jobs
crontab -e  # Edit user cron jobs
crontab -u user -l  # List jobs for specific user

# System cron
cat /etc/crontab
ls /etc/cron.d/
ls /etc/cron.daily/

# At jobs (one-time scheduling)
at now + 5 minutes
at 2:30 PM today
atq  # List pending jobs
atrm job_number  # Remove job

# Systemd timers (modern alternative to cron)
systemctl list-timers
systemctl status timer_name
```

---

## 🚨 Process Troubleshooting Scenarios

### Scenario 1: High CPU Usage
```bash
# Identify CPU-hungry processes
top -o %CPU
ps aux --sort=-%cpu | head -10

# Analyze specific process
top -p PID
pidstat -p PID 1 10

# Check for CPU-bound loops
strace -p PID
perf top -p PID

# System-wide CPU analysis
mpstat 1 5
sar -u 1 5
```

### Scenario 2: Memory Leaks
```bash
# Monitor memory usage over time
while true; do
    echo "$(date): $(ps -o pid,vsz,rss,comm -p PID)"
    sleep 60
done

# Detailed memory analysis
pmap -d PID
cat /proc/PID/smaps
valgrind --tool=memcheck --leak-check=full ./program

# System memory pressure
dmesg | grep -i "killed process"  # OOM killer
cat /proc/pressure/memory  # PSI memory pressure
```

### Scenario 3: Zombie Processes
```bash
# Find zombie processes
ps aux | grep "<defunct>"
ps -eo pid,stat,comm | grep "Z"

# Find parent of zombie
ps -o pid,ppid,stat,comm -p ZOMBIE_PID

# Clean up zombies (kill parent if necessary)
kill -CHLD PARENT_PID  # Ask parent to reap children
```

### Scenario 4: Runaway Processes
```bash
# Emergency process termination
pkill -f "runaway_pattern"
killall -9 process_name

# Prevent fork bombs
ulimit -u 1000  # Limit number of processes per user

# System-wide limits
echo "* hard nproc 4096" >> /etc/security/limits.conf
```

---

## 📊 Process Monitoring Scripts

### Process Monitor Script
```bash
#!/bin/bash
# process-monitor.sh

PID=${1:-$$}
INTERVAL=${2:-5}
DURATION=${3:-300}

echo "Monitoring PID $PID for $DURATION seconds (interval: ${INTERVAL}s)"
echo "Time,CPU%,MEM%,VSZ,RSS,Status,Command"

end_time=$(($(date +%s) + DURATION))

while [ $(date +%s) -lt $end_time ]; do
    if kill -0 $PID 2>/dev/null; then
        stats=$(ps -o pid,%cpu,%mem,vsz,rss,stat,comm -p $PID --no-headers)
        echo "$(date +%H:%M:%S),$stats"
    else
        echo "$(date +%H:%M:%S),Process $PID not found"
        break
    fi
    sleep $INTERVAL
done
```

### Top Consumers Script
```bash
#!/bin/bash
# top-consumers.sh

echo "=== Top Process Consumers ==="
echo "Date: $(date)"

echo -e "\n=== Top 5 CPU Consumers ==="
ps aux --sort=-%cpu | head -6

echo -e "\n=== Top 5 Memory Consumers ==="
ps aux --sort=-%mem | head -6

echo -e "\n=== Processes Using Most File Descriptors ==="
lsof | awk '{print $2}' | sort | uniq -c | sort -nr | head -5 | while read count pid; do
    echo "PID $pid: $count open files ($(ps -p $pid -o comm= 2>/dev/null))"
done

echo -e "\n=== Load Average ==="
uptime

echo -e "\n=== Process States ==="
ps aux | awk '{print $8}' | sort | uniq -c | sort -nr
```

### Service Health Check Script
```bash
#!/bin/bash
# service-health-check.sh

SERVICES="ssh apache2 mysql nginx"
LOG_FILE="/var/log/service-health.log"

echo "$(date): Service health check started" | tee -a $LOG_FILE

for service in $SERVICES; do
    if systemctl is-active --quiet $service; then
        echo "$(date): $service - OK" | tee -a $LOG_FILE
    else
        echo "$(date): $service - FAILED" | tee -a $LOG_FILE
        
        # Try to restart failed service
        echo "$(date): Attempting to restart $service" | tee -a $LOG_FILE
        systemctl restart $service
        
        sleep 5
        
        if systemctl is-active --quiet $service; then
            echo "$(date): $service - RESTARTED SUCCESSFULLY" | tee -a $LOG_FILE
        else
            echo "$(date): $service - RESTART FAILED" | tee -a $LOG_FILE
        fi
    fi
done

echo "$(date): Service health check completed" | tee -a $LOG_FILE
```

---

## 🔧 Performance Optimization

### Process Scheduling Optimization
```bash
# CPU affinity (bind process to specific CPU cores)
taskset -c 0,1 command  # Run on cores 0 and 1
taskset -cp 0,1 PID     # Change affinity of running process

# NUMA optimization
numactl --cpubind=0 --membind=0 command
numastat -p PID  # Show NUMA memory allocation

# I/O scheduling
ionice -c 1 -n 4 command  # Real-time I/O class, priority 4
ionice -c 3 command       # Idle I/O class
```

### Resource Limits
```bash
# Set resource limits
ulimit -c unlimited  # Core dump size
ulimit -n 4096      # Number of open files
ulimit -u 1000      # Number of processes
ulimit -v 1000000   # Virtual memory (KB)

# System-wide limits (/etc/security/limits.conf)
echo "* soft nofile 4096" >> /etc/security/limits.conf
echo "* hard nofile 8192" >> /etc/security/limits.conf

# Check current limits
ulimit -a
cat /proc/PID/limits
```

---

## 🎯 Interview Questions & Answers

### Q1: "Explain process states in Linux"
**Answer:**
```bash
# Process states:
# R - Running/Runnable
# S - Interruptible Sleep
# D - Uninterruptible Sleep (usually I/O)
# T - Stopped
# Z - Zombie (defunct)

# Check process states
ps aux | awk '{print $8}' | sort | uniq -c

# Example interpretation:
ps -eo pid,stat,comm
# STAT column shows:
# S    - sleeping
# R    - running
# D    - disk sleep
# Z    - zombie
# T    - stopped
```

### Q2: "How do you troubleshoot a process that won't die?"
**Answer:**
```bash
# Step 1: Try graceful termination
kill -TERM PID

# Step 2: Check process state
ps -o pid,stat,wchan PID

# Step 3: If in D state (uninterruptible sleep)
# - Process is waiting for I/O
# - Cannot be killed until I/O completes
# - Check for disk/network issues

# Step 4: Force kill (last resort)
kill -KILL PID

# Step 5: If still won't die, check for:
# - Kernel threads (cannot be killed)
# - Hardware issues
# - System reboot may be needed
```

### Q3: "What's the difference between fork() and exec()?"
**Answer:**
```bash
# fork(): Creates exact copy of current process
# - Parent and child processes
# - Same memory space initially (copy-on-write)
# - Different PIDs

# exec(): Replaces current process image
# - Same PID
# - New program loaded
# - Memory space replaced

# Example demonstration:
# fork() creates child:
bash -c 'echo $$; (echo child: $$)'

# exec() replaces process:
bash -c 'echo before: $$; exec echo after: $$'
```

---

## 🔍 Advanced Process Analysis

### Process Dependencies
```bash
# Find process dependencies
ldd /usr/bin/command  # Shared library dependencies
pldd PID  # Runtime dependencies

# Process file usage
lsof -p PID  # Files opened by process
fuser /path/to/file  # Processes using file

# Network connections by process
lsof -i -P -n | grep PID
netstat -tulpn | grep PID
```

### Debugging and Tracing
```bash
# System call tracing
strace -p PID
strace -f -e trace=open,read,write command

# Library call tracing
ltrace -p PID

# Performance profiling
perf record -g command
perf report

# Core dumps
ulimit -c unlimited
gdb program core.PID
```

---

## 📈 Automation and Scripting

### Process Management Functions
```bash
# Function to check if process is running
is_running() {
    local pid=$1
    kill -0 $pid 2>/dev/null
    return $?
}

# Function to wait for process to finish
wait_for_process() {
    local pid=$1
    local timeout=${2:-300}
    local count=0
    
    while kill -0 $pid 2>/dev/null; do
        if [ $count -ge $timeout ]; then
            echo "Process $pid did not finish within $timeout seconds"
            return 1
        fi
        sleep 1
        ((count++))
    done
    return 0
}

# Function to restart service safely
restart_service() {
    local service=$1
    
    if systemctl is-active --quiet $service; then
        echo "Stopping $service..."
        systemctl stop $service
        
        # Wait for complete shutdown
        while systemctl is-active --quiet $service; do
            sleep 1
        done
    fi
    
    echo "Starting $service..."
    systemctl start $service
    
    if systemctl is-active --quiet $service; then
        echo "$service restarted successfully"
    else
        echo "Failed to restart $service"
        return 1
    fi
}
```

This comprehensive process management guide covers all essential commands and scenarios for DevOps interviews and daily operations!
