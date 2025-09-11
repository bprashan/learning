# 🖥️ Virtualization (QEMU/KVM) Commands

## 🎯 Interview Focus Areas
- Virtual machine lifecycle management
- Performance optimization and tuning
- Network and storage configuration
- Migration and backup strategies
- Troubleshooting virtualization issues
- Container vs VM architecture

---

## 🟢 Basic QEMU/KVM Commands

### Virtualization Check
```bash
# Check if virtualization is supported
egrep -c '(vmx|svm)' /proc/cpuinfo
lscpu | grep Virtualization

# Check if KVM modules are loaded
lsmod | grep kvm
ls -la /dev/kvm

# Install KVM tools
yum install qemu-kvm libvirt virt-install  # RHEL/CentOS
apt install qemu-kvm libvirt-daemon-system virtinst  # Ubuntu
```

### Basic VM Operations
```bash
# List VMs
virsh list --all
virsh dominfo vm_name

# Start/stop VMs
virsh start vm_name
virsh shutdown vm_name
virsh destroy vm_name  # Force shutdown
virsh reboot vm_name

# VM console access
virsh console vm_name
virt-viewer vm_name  # GUI console
```

### VM Configuration
```bash
# Show VM configuration
virsh dumpxml vm_name
virsh dominfo vm_name

# Edit VM configuration
virsh edit vm_name

# Clone VM
virt-clone --original original_vm --name new_vm --file /path/to/new_disk.qcow2
```

---

## 🟡 Intermediate Virtualization Management

### VM Creation
```bash
# Create VM with virt-install
virt-install \
  --name test_vm \
  --ram 2048 \
  --disk path=/var/lib/libvirt/images/test_vm.qcow2,size=20 \
  --vcpus 2 \
  --os-type linux \
  --os-variant ubuntu20.04 \
  --network bridge=virbr0 \
  --graphics none \
  --console pty,target_type=serial \
  --location 'http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/' \
  --extra-args 'console=ttyS0,115200n8 serial'

# Create VM from ISO
virt-install \
  --name vm_from_iso \
  --ram 1024 \
  --disk path=/var/lib/libvirt/images/vm.qcow2,size=10 \
  --vcpus 1 \
  --os-type linux \
  --os-variant generic \
  --network bridge=virbr0 \
  --cdrom /path/to/install.iso
```

### Disk Management
```bash
# Create disk images
qemu-img create -f qcow2 disk.qcow2 10G
qemu-img create -f raw disk.img 10G

# Disk information
qemu-img info disk.qcow2
qemu-img check disk.qcow2

# Resize disk
qemu-img resize disk.qcow2 +5G
virsh blockresize vm_name /path/to/disk.qcow2 15G

# Convert disk formats
qemu-img convert -f qcow2 -O raw disk.qcow2 disk.img
qemu-img convert -f raw -O qcow2 disk.img disk.qcow2 -c  # Compressed
```

### Snapshots
```bash
# Create snapshot
virsh snapshot-create-as vm_name snapshot_name "Description"
qemu-img snapshot -c snapshot_name disk.qcow2

# List snapshots
virsh snapshot-list vm_name
qemu-img snapshot -l disk.qcow2

# Restore snapshot
virsh snapshot-revert vm_name snapshot_name
qemu-img snapshot -a snapshot_name disk.qcow2

# Delete snapshot
virsh snapshot-delete vm_name snapshot_name
qemu-img snapshot -d snapshot_name disk.qcow2
```

---

## 🔴 Expert Level Virtualization

### Performance Tuning
```bash
# CPU optimization
virsh vcpuinfo vm_name
virsh vcpupin vm_name 0 1  # Pin vCPU 0 to physical CPU 1

# Memory management
virsh setmem vm_name 4096M
virsh setmaxmem vm_name 8192M

# NUMA optimization
virsh numatune vm_name --mode strict --nodeset 0
numactl --hardware  # Check NUMA topology

# Balloon driver
virsh qemu-monitor-command vm_name --hmp 'info balloon'
virsh setmem vm_name 2048M --live
```

### Advanced Networking
```bash
# Create bridge network
brctl addbr br0
brctl addif br0 eth0
ip link set br0 up

# Using virsh networking
virsh net-list --all
virsh net-define network.xml
virsh net-start network_name
virsh net-autostart network_name

# SR-IOV configuration
echo 4 > /sys/class/net/eth0/device/sriov_numvfs
virsh nodedev-list | grep pci
virsh attach-device vm_name device.xml
```

### Live Migration
```bash
# Check migration compatibility
virsh migrate --help

# Live migration
virsh migrate --live vm_name qemu+ssh://destination_host/system

# Storage migration
virsh migrate --live --copy-storage-all vm_name qemu+ssh://dest_host/system

# Migration with specific options
virsh migrate --live --verbose --compressed \
  --unsafe --persistent --undefinesource \
  vm_name qemu+ssh://dest_host/system
```

---

## 🚨 Virtualization Troubleshooting

### VM Performance Issues
```bash
# Check VM resource usage
virsh cpu-stats vm_name
virsh domstats vm_name

# Memory statistics
virsh dommemstat vm_name

# Block I/O statistics
virsh domblkstat vm_name

# Network I/O statistics
virsh domifstat vm_name interface_name

# Host performance impact
top -p $(pgrep qemu)
perf top -p $(pgrep qemu)
```

### VM Connectivity Issues
```bash
# Check VM network configuration
virsh domiflist vm_name
virsh net-dhcp-leases default

# Bridge connectivity
brctl show
ip link show type bridge

# Firewall rules for libvirt
iptables -L LIBVIRT_INP
iptables -t nat -L LIBVIRT_PRT
```

### VM Boot Issues
```bash
# Check VM logs
virsh console vm_name
tail -f /var/log/libvirt/qemu/vm_name.log

# Boot from rescue disk
virsh attach-disk vm_name /path/to/rescue.iso hdc --type cdrom

# Check VM XML configuration
virsh dumpxml vm_name | grep -A 5 -B 5 boot
```

---

## 📊 Virtualization Monitoring Scripts

### VM Resource Monitor
```bash
#!/bin/bash
# vm-resource-monitor.sh

VM_NAME=${1:-"all"}
INTERVAL=${2:-5}

if [ "$VM_NAME" = "all" ]; then
    VMS=$(virsh list --name)
else
    VMS=$VM_NAME
fi

echo "Monitoring VM resources (interval: ${INTERVAL}s)"
echo "VM_NAME,CPU_TIME,MEMORY_ACTUAL,MEMORY_AVAILABLE,DISK_RD,DISK_WR"

while true; do
    for vm in $VMS; do
        if virsh domstate $vm | grep -q running; then
            CPU_TIME=$(virsh cpu-stats $vm --total | grep cpu_time | awk '{print $3}')
            MEM_ACTUAL=$(virsh dommemstat $vm | grep actual | awk '{print $2}')
            MEM_AVAIL=$(virsh dommemstat $vm | grep available | awk '{print $2}')
            DISK_RD=$(virsh domblkstat $vm | grep rd_bytes | awk '{print $2}')
            DISK_WR=$(virsh domblkstat $vm | grep wr_bytes | awk '{print $2}')
            
            echo "$vm,$CPU_TIME,$MEM_ACTUAL,$MEM_AVAIL,$DISK_RD,$DISK_WR"
        fi
    done
    sleep $INTERVAL
done
```

### VM Health Check Script
```bash
#!/bin/bash
# vm-health-check.sh

echo "=== VM Health Check Report ==="
echo "Date: $(date)"
echo ""

echo "=== Host Virtualization Status ==="
echo "KVM Module: $(lsmod | grep kvm | wc -l) modules loaded"
echo "Libvirt Status: $(systemctl is-active libvirtd)"
echo ""

echo "=== VM Status ==="
virsh list --all
echo ""

echo "=== VM Resource Usage ==="
for vm in $(virsh list --name); do
    if [ -n "$vm" ]; then
        echo "VM: $vm"
        echo "  State: $(virsh domstate $vm)"
        echo "  CPU Usage: $(virsh cpu-stats $vm --total | grep cpu_time | awk '{print $3}') ns"
        echo "  Memory: $(virsh dommemstat $vm | grep actual | awk '{print $2}') KB actual"
        echo "  Autostart: $(virsh dominfo $vm | grep Autostart | awk '{print $2}')"
        echo ""
    fi
done

echo "=== Storage Pools ==="
virsh pool-list --all
echo ""

echo "=== Network Status ==="
virsh net-list --all
echo ""

echo "=== Host Resources ==="
echo "  CPU Cores: $(nproc)"
echo "  Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "  Load Average: $(uptime | awk -F'load average:' '{print $2}')"
```

### VM Backup Script
```bash
#!/bin/bash
# vm-backup.sh

VM_NAME=$1
BACKUP_DIR="/backup/vms"
DATE=$(date +%Y%m%d_%H%M%S)

if [ -z "$VM_NAME" ]; then
    echo "Usage: $0 <vm_name>"
    exit 1
fi

mkdir -p $BACKUP_DIR

echo "Starting backup of VM: $VM_NAME"

# Create snapshot
echo "Creating snapshot..."
virsh snapshot-create-as $VM_NAME backup_$DATE "Backup snapshot created $(date)"

# Export VM configuration
echo "Backing up VM configuration..."
virsh dumpxml $VM_NAME > $BACKUP_DIR/${VM_NAME}_config_$DATE.xml

# Backup disk images
echo "Backing up disk images..."
for disk in $(virsh domblklist $VM_NAME | grep -v "^-" | awk 'NR>1 {print $2}'); do
    if [ -f "$disk" ]; then
        disk_name=$(basename $disk)
        echo "Backing up $disk..."
        cp "$disk" "$BACKUP_DIR/${VM_NAME}_${disk_name}_$DATE"
        
        # Create checksum
        sha256sum "$BACKUP_DIR/${VM_NAME}_${disk_name}_$DATE" > "$BACKUP_DIR/${VM_NAME}_${disk_name}_$DATE.sha256"
    fi
done

# Remove snapshot after backup
echo "Cleaning up snapshot..."
virsh snapshot-delete $VM_NAME backup_$DATE

echo "Backup completed: $BACKUP_DIR"
ls -la $BACKUP_DIR/*$DATE*
```

---

## 🎯 Container vs VM Comparison

### Performance Comparison
```bash
# VM resource overhead
virsh domstats vm_name | grep memory
virsh domstats vm_name | grep cpu

# Container resource usage
docker stats container_name
podman stats container_name

# Boot time comparison
time virsh start vm_name
time docker run -d image_name
```

### Use Case Scenarios
```bash
# VMs are better for:
# - Different OS requirements
# - Strong isolation needs
# - Legacy applications
# - Compliance requirements

# Containers are better for:
# - Microservices architecture
# - CI/CD pipelines
# - Application packaging
# - Resource efficiency
```

---

## 🎯 Interview Questions & Answers

### Q1: "What's the difference between QEMU and KVM?"
**Answer:**
```bash
# QEMU: Machine emulator and virtualizer
# - Can emulate different architectures
# - Software-only virtualization
# - Slower but more flexible

# KVM: Kernel-based Virtual Machine
# - Hardware-assisted virtualization
# - Linux kernel module
# - Faster performance

# Together: QEMU + KVM
# - QEMU provides device emulation
# - KVM provides hardware acceleration
# - Best of both worlds

# Check KVM support
grep -E '(vmx|svm)' /proc/cpuinfo
lsmod | grep kvm
```

### Q2: "How do you migrate a VM with minimal downtime?"
**Answer:**
```bash
# Live migration process:
# 1. Pre-migration checks
virsh migrate --help | grep live

# 2. Start live migration
virsh migrate --live --verbose vm_name qemu+ssh://dest_host/system

# 3. Monitor migration
virsh domjobinfo vm_name

# 4. Post-migration verification
virsh list --all  # On both hosts
ping vm_ip  # Test connectivity

# Factors affecting downtime:
# - Memory size and change rate
# - Network bandwidth
# - Storage type (shared vs local)
```

### Q3: "How do you troubleshoot VM performance issues?"
**Answer:**
```bash
# Step 1: Check VM resource allocation
virsh dominfo vm_name
virsh vcpuinfo vm_name

# Step 2: Monitor resource usage
virsh cpu-stats vm_name
virsh dommemstat vm_name
virsh domblkstat vm_name

# Step 3: Check host resources
top -p $(pgrep qemu)
iostat -x 1 5

# Step 4: Optimize configuration
# - Increase memory/CPU if needed
# - Enable virtio drivers
# - Use CPU pinning for critical VMs
# - Optimize disk I/O (virtio, caching)

# Step 5: Network optimization
# - Use virtio network driver
# - Check bridge configuration
# - Monitor network statistics
```

---

## 🔧 Advanced Virtualization Features

### GPU Passthrough
```bash
# Enable IOMMU
echo "intel_iommu=on" >> /etc/default/grub  # Intel
echo "amd_iommu=on" >> /etc/default/grub   # AMD
update-grub

# Bind GPU to VFIO
echo "vfio-pci" > /etc/modules-load.d/vfio-pci.conf
echo "options vfio-pci ids=10de:1234" > /etc/modprobe.d/vfio.conf

# Attach GPU to VM
virsh attach-device vm_name gpu.xml --persistent
```

### Nested Virtualization
```bash
# Enable nested virtualization
echo "options kvm_intel nested=1" > /etc/modprobe.d/kvm.conf
echo "options kvm_amd nested=1" > /etc/modprobe.d/kvm.conf

# Verify nested support
cat /sys/module/kvm_intel/parameters/nested
cat /proc/cpuinfo | grep vmx  # Should show in VM
```

This comprehensive virtualization guide covers QEMU/KVM management essential for DevOps interviews and production environments!
