# 🐧 OS & Kernel Information Commands

## 🎯 Interview Focus Areas
- System identification and version management
- Kernel parameter tuning and optimization
- Boot process troubleshooting
- Hardware detection and driver management
- System logging and debugging
- Performance analysis at kernel level

---

## 🟢 Basic System Information

### Operating System Details
```bash
# OS version and distribution
cat /etc/os-release
lsb_release -a
hostnamectl
cat /etc/redhat-release  # RHEL/CentOS
cat /etc/debian_version  # Debian/Ubuntu

# System architecture
uname -a
uname -m   # Machine hardware
uname -p   # Processor type
arch

# Hostname information
hostname
hostname -f  # FQDN
hostname -i  # IP address
```

### Kernel Information
```bash
# Kernel version
uname -r
cat /proc/version
cat /proc/sys/kernel/osrelease

# Kernel command line
cat /proc/cmdline

# Kernel modules
lsmod
modinfo module_name
cat /proc/modules
```

### System Uptime and Load
```bash
# System uptime
uptime
cat /proc/uptime
who -b  # Boot time

# System load
cat /proc/loadavg
w  # Load with user information
```

---

## 🟡 Intermediate System Analysis

### Hardware Information
```bash
# CPU information
lscpu
cat /proc/cpuinfo
nproc  # Number of processors

# Memory information
free -h
cat /proc/meminfo
dmidecode -t memory  # Detailed memory info

# Hardware overview
lshw  # List hardware
lshw -short
lspci  # PCI devices
lsusb  # USB devices
lsblk  # Block devices
```

### Kernel Parameters
```bash
# View kernel parameters
sysctl -a
sysctl kernel.hostname
cat /proc/sys/kernel/hostname

# Modify kernel parameters
sysctl -w kernel.parameter=value
echo value > /proc/sys/kernel/parameter

# Persistent changes
echo "kernel.parameter = value" >> /etc/sysctl.conf
sysctl -p  # Reload sysctl.conf
```

### Module Management
```bash
# Load/unload modules
modprobe module_name
modprobe -r module_name  # Remove module
rmmod module_name

# Module dependencies
depmod -a
modprobe -D module_name  # Show dependencies

# Module configuration
cat /etc/modprobe.conf
ls /etc/modprobe.d/
```

---

## 🔴 Expert Level Kernel Operations

### Kernel Compilation and Management
```bash
# Kernel source management
uname -r  # Current kernel version
ls /boot/  # Available kernels

# Kernel configuration
cat /boot/config-$(uname -r)
zcat /proc/config.gz  # Current kernel config

# GRUB management
grub2-mkconfig -o /boot/grub2/grub.cfg
update-grub  # Debian/Ubuntu
grub2-set-default 0  # Set default kernel
```

### Advanced Kernel Debugging
```bash
# Kernel ring buffer
dmesg
dmesg -T  # With timestamps
dmesg -l err,crit,alert,emerg  # Only errors

# Kernel debugging
echo 1 > /proc/sys/kernel/sysrq
echo c > /proc/sysrq-trigger  # Crash dump (dangerous!)

# Kernel symbols
cat /proc/kallsyms
nm /boot/vmlinuz-$(uname -r)
```

### System Call Monitoring
```bash
# System call statistics
cat /proc/stat
cat /proc/interrupts
cat /proc/softirqs

# Per-process system calls
strace -c command
strace -p PID -c

# Kernel tracing
ftrace  # Function tracer
perf record -a sleep 10  # System-wide profiling
```

---

## 🚨 System Troubleshooting Scenarios

### Scenario 1: Boot Issues
```bash
# Check boot logs
journalctl -b  # Current boot
journalctl -b -1  # Previous boot
dmesg | head -50  # Early boot messages

# GRUB troubleshooting
grub2-install /dev/sda
update-grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Kernel panic analysis
cat /var/crash/*  # Crash dumps
kdump-analyze  # If kdump is configured
```

### Scenario 2: Hardware Detection Issues
```bash
# Hardware detection
lshw -class network  # Network hardware
lspci -v  # Verbose PCI info
lsusb -v  # Verbose USB info

# Driver issues
lsmod | grep driver_name
modinfo driver_name
dmesg | grep -i firmware

# Hardware errors
mcelog  # Machine check errors
edac-util  # Memory errors
```

### Scenario 3: Performance Issues
```bash
# Kernel performance analysis
cat /proc/stat  # CPU statistics
cat /proc/meminfo  # Memory statistics
cat /proc/vmstat  # Virtual memory statistics

# I/O performance
cat /proc/diskstats
iostat -x 1 5

# Network performance
cat /proc/net/dev
cat /proc/net/netstat
```

---

## 📊 System Monitoring Scripts

### System Info Collection Script
```bash
#!/bin/bash
# system-info.sh

echo "=== System Information Report ==="
echo "Generated: $(date)"
echo "Hostname: $(hostname)"
echo ""

echo "=== Operating System ==="
cat /etc/os-release
echo ""

echo "=== Kernel Information ==="
uname -a
echo "Kernel parameters:"
cat /proc/cmdline
echo ""

echo "=== Hardware Information ==="
echo "CPU:"
lscpu | grep -E "Model name|CPU\(s\)|Architecture"
echo ""
echo "Memory:"
free -h
echo ""
echo "Storage:"
lsblk
echo ""

echo "=== Network Interfaces ==="
ip addr show
echo ""

echo "=== System Load ==="
uptime
echo ""

echo "=== Loaded Modules ==="
lsmod | wc -l
echo "Total modules loaded: $(lsmod | wc -l)"
echo ""

echo "=== Recent System Messages ==="
dmesg | tail -10
```

### Kernel Parameter Backup Script
```bash
#!/bin/bash
# kernel-params-backup.sh

BACKUP_DIR="/etc/sysctl.backup"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Backing up kernel parameters..."

# Backup current sysctl configuration
sysctl -a > $BACKUP_DIR/sysctl_all_$DATE.conf

# Backup custom configurations
if [ -f /etc/sysctl.conf ]; then
    cp /etc/sysctl.conf $BACKUP_DIR/sysctl_conf_$DATE.backup
fi

# Backup sysctl.d directory
if [ -d /etc/sysctl.d/ ]; then
    cp -r /etc/sysctl.d $BACKUP_DIR/sysctl_d_$DATE/
fi

echo "Kernel parameters backed up to $BACKUP_DIR"
ls -la $BACKUP_DIR/
```

### Hardware Change Detection Script
```bash
#!/bin/bash
# hardware-monitor.sh

BASELINE_FILE="/var/log/hardware-baseline.txt"
CURRENT_FILE="/tmp/hardware-current.txt"
LOG_FILE="/var/log/hardware-changes.log"

# Create baseline if it doesn't exist
if [ ! -f $BASELINE_FILE ]; then
    echo "Creating hardware baseline..."
    lshw -short > $BASELINE_FILE
    lspci >> $BASELINE_FILE
    lsusb >> $BASELINE_FILE
    echo "Baseline created at $BASELINE_FILE"
    exit 0
fi

# Generate current hardware info
lshw -short > $CURRENT_FILE
lspci >> $CURRENT_FILE
lsusb >> $CURRENT_FILE

# Compare with baseline
if ! diff $BASELINE_FILE $CURRENT_FILE > /dev/null; then
    echo "$(date): Hardware changes detected" | tee -a $LOG_FILE
    diff $BASELINE_FILE $CURRENT_FILE | tee -a $LOG_FILE
    
    # Update baseline
    cp $CURRENT_FILE $BASELINE_FILE
else
    echo "$(date): No hardware changes detected" >> $LOG_FILE
fi

rm $CURRENT_FILE
```

---

## 🔧 Kernel Tuning and Optimization

### Common Kernel Parameters
```bash
# Network tuning
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216
sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"

# Memory management
sysctl -w vm.swappiness=10
sysctl -w vm.dirty_ratio=15
sysctl -w vm.dirty_background_ratio=5

# Security parameters
sysctl -w kernel.dmesg_restrict=1
sysctl -w kernel.kptr_restrict=2
sysctl -w net.ipv4.conf.all.send_redirects=0

# File system parameters
sysctl -w fs.file-max=65536
sysctl -w fs.inotify.max_user_watches=524288
```

### Performance Tuning
```bash
# CPU scaling governor
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# I/O scheduler
echo deadline > /sys/block/sda/queue/scheduler

# Transparent huge pages
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# NUMA balancing
echo 0 > /proc/sys/kernel/numa_balancing
```

---

## 🎯 Interview Questions & Answers

### Q1: "How do you check what kernel version is running and what modules are loaded?"
**Answer:**
```bash
# Kernel version
uname -r
cat /proc/version

# Loaded modules
lsmod
cat /proc/modules

# Module information
modinfo module_name

# Check if specific module is loaded
lsmod | grep module_name
```

### Q2: "Explain the Linux boot process"
**Answer:**
```bash
# Boot process stages:
# 1. BIOS/UEFI -> Hardware initialization
# 2. Bootloader (GRUB) -> Load kernel
# 3. Kernel -> Initialize hardware, mount root filesystem
# 4. Init system (systemd) -> Start services

# Check boot process
journalctl -b  # Boot logs
dmesg | head -50  # Kernel boot messages
systemctl list-units --type=service  # Services started

# Boot time analysis
systemd-analyze
systemd-analyze blame  # Slowest services
```

### Q3: "How do you troubleshoot kernel panics?"
**Answer:**
```bash
# Enable kdump for crash analysis
yum install kexec-tools  # RHEL/CentOS
systemctl enable kdump

# Analyze crash dumps
crash /var/crash/vmcore
kdump-analyze

# Check for hardware issues
mcelog  # Machine check errors
dmesg | grep -i "hardware error"

# Common causes:
# - Hardware failures
# - Driver bugs
# - Memory corruption
# - Filesystem corruption
```

---

## 📈 Advanced System Analysis

### Kernel Performance Analysis
```bash
# Kernel function profiling
perf record -a -g sleep 10
perf report

# Function call tracing
echo function > /sys/kernel/debug/tracing/current_tracer
cat /sys/kernel/debug/tracing/trace

# Interrupt analysis
cat /proc/interrupts
watch -n1 cat /proc/interrupts
```

### Memory Management Analysis
```bash
# Memory information
cat /proc/meminfo
cat /proc/slabinfo  # Kernel memory usage
cat /proc/buddyinfo  # Memory fragmentation

# Virtual memory statistics
vmstat 1 5
cat /proc/vmstat

# Swap analysis
cat /proc/swaps
swapon --show
```

### File System and I/O Analysis
```bash
# File system information
cat /proc/filesystems
cat /proc/mounts
findmnt -D

# I/O statistics
cat /proc/diskstats
iostat -x 1 5

# Block device information
lsblk -f
blkid
```

---

## 🔒 Security and Hardening

### Kernel Security Features
```bash
# SELinux status
getenforce
sestatus
cat /proc/cmdline | grep selinux

# AppArmor status
aa-status
cat /proc/cmdline | grep apparmor

# Kernel address space layout randomization
cat /proc/sys/kernel/randomize_va_space

# Control Flow Integrity
dmesg | grep -i cfi
```

### Security Monitoring
```bash
# Audit system
auditctl -l  # List audit rules
aureport  # Audit reports
ausearch -m USER_LOGIN  # Search audit logs

# Kernel security events
dmesg | grep -i "segfault\|oops\|protection"
journalctl -k | grep -i security
```

This comprehensive OS and kernel guide covers all essential commands and concepts for DevOps interviews and system administration!
