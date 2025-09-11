# 💾 Disk Usage & Management Commands

## 🎯 Interview Focus Areas
- Disk space troubleshooting in production
- Partition management and resizing
- Mount operations and fstab configuration
- RAID and LVM management
- Filesystem performance optimization

---

## 🟢 Basic Disk Usage Commands

### Disk Space Overview
```bash
# Check disk usage by filesystem
df -h
df -i  # Check inode usage
df -T  # Show filesystem type

# Check directory sizes
du -h /var/log
du -sh /home/*  # Summary of each user directory
du -h --max-depth=1 /

# Find largest files/directories
du -ah / | sort -rh | head -20
find / -type f -size +100M 2>/dev/null
```

### Quick Disk Health Checks
```bash
# Check mount points
mount | grep -E '^/dev'
cat /proc/mounts
findmnt -D  # Show filesystem tree

# Check disk I/O
iostat -x 1 5
iotop -ao  # Show processes doing I/O
```

---

## 🟡 Intermediate Partition Management

### Partition Operations
```bash
# List all block devices
lsblk -f
blkid  # Show UUID and filesystem types

# Partition management
fdisk -l  # List all partitions
fdisk /dev/sdb  # Interactive partitioning
parted /dev/sdb print  # GPT partition info

# Create partitions
parted /dev/sdb mklabel gpt
parted /dev/sdb mkpart primary ext4 0% 100%
partprobe /dev/sdb  # Refresh partition table
```

### Filesystem Creation and Management
```bash
# Create filesystems
mkfs.ext4 /dev/sdb1
mkfs.xfs -f /dev/sdb1
mkfs.btrfs /dev/sdb1

# Filesystem checks and repairs
fsck -y /dev/sdb1
xfs_repair /dev/sdb1
btrfs check /dev/sdb1

# Resize filesystems
resize2fs /dev/sdb1  # ext4
xfs_growfs /mount/point  # XFS
btrfs filesystem resize max /mount/point  # Btrfs
```

### Mount Operations
```bash
# Manual mounting
mount /dev/sdb1 /mnt/data
mount -t xfs /dev/sdb1 /mnt/data
mount -o remount,rw /mnt/data

# Unmounting
umount /mnt/data
umount -l /mnt/data  # Lazy unmount
fuser -mv /mnt/data  # Check what's using the mount

# Permanent mounts (fstab)
echo "/dev/sdb1 /mnt/data ext4 defaults,noatime 0 2" >> /etc/fstab
mount -a  # Mount all fstab entries
```

---

## 🔴 Expert Level Operations

### LVM Management
```bash
# Physical Volume operations
pvcreate /dev/sdb1 /dev/sdc1
pvdisplay
pvs  # Short format

# Volume Group operations
vgcreate data_vg /dev/sdb1 /dev/sdc1
vgextend data_vg /dev/sdd1
vgdisplay
vgs

# Logical Volume operations
lvcreate -L 10G -n data_lv data_vg
lvcreate -l 100%FREE -n data_lv data_vg
lvextend -L +5G /dev/data_vg/data_lv
lvresize -l +100%FREE /dev/data_vg/data_lv
lvs
```

### RAID Management
```bash
# Software RAID with mdadm
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb1 /dev/sdc1
mdadm --detail /dev/md0
cat /proc/mdstat

# RAID monitoring and maintenance
mdadm --monitor /dev/md0
mdadm /dev/md0 --fail /dev/sdb1  # Mark device as failed
mdadm /dev/md0 --remove /dev/sdb1
mdadm /dev/md0 --add /dev/sdd1  # Add replacement

# Save RAID configuration
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
```

### Advanced Filesystem Operations
```bash
# Btrfs advanced operations
btrfs subvolume create /mnt/data/subvol1
btrfs subvolume snapshot /mnt/data /mnt/data/snapshot1
btrfs filesystem defragment /mnt/data
btrfs scrub start /mnt/data

# XFS advanced operations
xfs_info /mnt/data
xfs_fsr /mnt/data  # Defragmentation
xfs_quota -x -c 'report -h' /mnt/data

# ZFS operations (if available)
zpool create datapool /dev/sdb
zfs create datapool/dataset1
zfs snapshot datapool/dataset1@snap1
zfs list -t snapshot
```

---

## 🚨 Production Troubleshooting Scenarios

### Scenario 1: Disk Full Emergency
```bash
# Quick identification of space hogs
df -h | grep -E '(9[0-9]|100)%'
du -sh /var/log/* | sort -rh | head -10
find /var/log -name "*.log" -size +100M -mtime +7

# Emergency cleanup
journalctl --vacuum-time=7d
find /tmp -type f -atime +7 -delete
find /var/log -name "*.log.[0-9]*" -mtime +30 -delete

# Immediate space recovery
truncate -s 0 /var/log/large.log
> /var/log/large.log  # Alternative method
```

### Scenario 2: Filesystem Corruption
```bash
# Identify corruption
dmesg | grep -i "ext4\|xfs\|error"
fsck -n /dev/sdb1  # Read-only check

# Recovery steps
umount /dev/sdb1
fsck -y /dev/sdb1  # Auto-fix
mount /dev/sdb1 /mnt/data

# XFS corruption recovery
umount /dev/sdb1
xfs_repair -n /dev/sdb1  # Check only
xfs_repair /dev/sdb1  # Repair
```

### Scenario 3: Performance Issues
```bash
# Disk performance analysis
iostat -x 1 10
iotop -ao
atop -d

# Check for high I/O wait
top -o %CPU
vmstat 1 10

# Filesystem performance tuning
mount -o remount,noatime,nodiratime /mnt/data
echo deadline > /sys/block/sdb/queue/scheduler
```

---

## 📊 Monitoring and Alerting

### Disk Space Monitoring Script
```bash
#!/bin/bash
# disk-monitor.sh
THRESHOLD=90

df -h | awk 'NR>1 {print $5 " " $6}' | while read output; do
    usage=$(echo $output | awk '{print $1}' | sed 's/%//g')
    partition=$(echo $output | awk '{print $2}')
    
    if [ $usage -ge $THRESHOLD ]; then
        echo "ALERT: $partition is ${usage}% full"
        # Send alert (email, Slack, etc.)
    fi
done
```

### SMART Monitoring
```bash
# Install smartmontools
smartctl -a /dev/sda
smartctl -t short /dev/sda  # Run short self-test
smartctl -l selftest /dev/sda  # View test results

# Monitor SMART attributes
smartctl -A /dev/sda | grep -E "(Reallocated|Current_Pending|Offline_Uncorrectable)"
```

---

## 🎯 Interview Questions & Answers

### Q1: "How do you troubleshoot a server with 100% disk usage?"
**Answer:**
```bash
# 1. Identify the problematic filesystem
df -h

# 2. Find largest directories
du -sh /* | sort -rh | head -10

# 3. Find large files
find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null

# 4. Check for deleted but open files
lsof +L1

# 5. Immediate cleanup options
journalctl --vacuum-time=3d
find /tmp -type f -atime +1 -delete
```

### Q2: "How do you extend a filesystem without downtime?"
**Answer:**
```bash
# For LVM (most common scenario):
# 1. Extend the logical volume
lvextend -L +10G /dev/vg_name/lv_name

# 2. Extend the filesystem
resize2fs /dev/vg_name/lv_name  # ext4
xfs_growfs /mount/point         # XFS

# For cloud environments:
# AWS: Modify EBS volume, then extend filesystem
# GCP: Resize persistent disk, then extend filesystem
```

### Q3: "Explain the difference between mount options: noatime vs relatime"
**Answer:**
- **noatime**: Never updates access time - best performance
- **relatime**: Updates access time only if modified time is newer
- **atime**: Updates access time on every read - performance impact
```bash
mount -o remount,noatime /home  # Best for performance
mount -o remount,relatime /home # Balanced approach
```

---

## 🔧 Daily Operations Checklist

```bash
#!/bin/bash
# daily-disk-check.sh

echo "=== Daily Disk Health Check ==="
echo "Date: $(date)"

echo -e "\n1. Disk Usage:"
df -h | grep -vE '^Filesystem|tmpfs|cdrom'

echo -e "\n2. Largest Directories in /:"
du -sh /* 2>/dev/null | sort -rh | head -5

echo -e "\n3. I/O Statistics:"
iostat -x 1 1 | tail -n +4

echo -e "\n4. Mount Status:"
findmnt -D | head -10

echo -e "\n5. RAID Status (if applicable):"
[ -f /proc/mdstat ] && cat /proc/mdstat

echo -e "\n6. LVM Status:"
vgs 2>/dev/null || echo "LVM not configured"

echo "=== Check Complete ==="
```

---

## 📚 Additional Resources

### Performance Tuning References
- **I/O Schedulers**: deadline, cfq, noop
- **Filesystem Options**: noatime, nodiratime, barriers
- **Read-ahead Settings**: blockdev --setra

### Backup and Recovery
```bash
# dd for disk cloning
dd if=/dev/sda of=/dev/sdb bs=4M status=progress

# rsync for file-level backup
rsync -avHAXS --progress /source/ /destination/

# tar for archival
tar -czf backup.tar.gz --exclude=/proc --exclude=/sys /
```

This comprehensive guide covers all disk management scenarios you'll encounter in DevOps interviews and daily operations!
