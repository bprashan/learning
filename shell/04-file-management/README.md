# 📁 File Management Commands

## 🎯 Interview Focus Areas
- Advanced file operations and automation
- Permission management and ACLs
- Archive creation and extraction
- File searching and text processing
- Backup and synchronization strategies
- Security and file integrity

---

## 🟢 Basic File Operations

### File Creation and Viewing
```bash
# Create files
touch file.txt
echo "content" > file.txt
cat > file.txt << EOF
multi-line
content
EOF

# View files
cat file.txt
less file.txt
head -n 10 file.txt
tail -n 10 file.txt
tail -f /var/log/syslog  # Follow file changes
```

### Directory Operations
```bash
# Create directories
mkdir -p /path/to/nested/dir
mkdir -m 755 directory

# Copy operations
cp file.txt backup.txt
cp -r source_dir dest_dir
cp -a source dest  # Archive mode (preserve all)

# Move operations
mv file.txt newname.txt
mv file.txt /new/location/
```

### File Information
```bash
# File details
ls -la
stat file.txt
file file.txt  # File type detection

# Disk usage
du -h file.txt
du -sh directory/
df -h  # Filesystem usage
```

---

## 🟡 Intermediate File Management

### Advanced File Operations
```bash
# Hard and symbolic links
ln file.txt hardlink.txt
ln -s /path/to/file symlink.txt

# Find broken symlinks
find /path -type l -exec test ! -e {} \; -print

# File comparison
diff file1.txt file2.txt
cmp file1.txt file2.txt
comm file1.txt file2.txt  # Compare sorted files
```

### File Searching
```bash
# Find files by name
find /path -name "*.txt"
find /path -iname "*.TXT"  # Case insensitive
locate filename  # Using locate database

# Find by attributes
find /path -type f -size +100M
find /path -type f -mtime -7  # Modified in last 7 days
find /path -type f -perm 644
find /path -user username
find /path -group groupname
```

### Text Processing
```bash
# Search within files
grep "pattern" file.txt
grep -r "pattern" /path/  # Recursive
grep -n "pattern" file.txt  # Show line numbers
grep -v "pattern" file.txt  # Invert match

# Advanced text manipulation
sed 's/old/new/g' file.txt  # Replace text
awk '{print $1}' file.txt   # Print first column
sort file.txt
uniq file.txt
cut -d: -f1 /etc/passwd  # Extract fields
```

---

## 🔴 Expert Level Operations

### Advanced Text Processing
```bash
# Complex sed operations
sed -n '10,20p' file.txt  # Print lines 10-20
sed '/pattern/d' file.txt  # Delete lines with pattern
sed -i 's/old/new/g' file.txt  # In-place editing

# AWK scripting
awk 'BEGIN{FS=":"} {print $1,$3}' /etc/passwd
awk '{sum+=$1} END{print sum}' numbers.txt
awk 'NR==2,NR==5' file.txt  # Print lines 2-5

# Stream processing
sort -k2,2n file.txt  # Sort by second column numerically
join file1.txt file2.txt  # Join files on common field
paste file1.txt file2.txt  # Combine files column-wise
```

### File Permissions and Security
```bash
# Basic permissions
chmod 755 file.txt
chmod u+x,g+r,o-w file.txt
chown user:group file.txt
chgrp group file.txt

# Special permissions
chmod +t /tmp  # Sticky bit
chmod g+s directory  # SGID
chmod u+s executable  # SUID

# Access Control Lists (ACLs)
setfacl -m u:user:rwx file.txt
setfacl -m g:group:rx file.txt
getfacl file.txt
setfacl -x u:user file.txt  # Remove ACL
```

### Archive and Compression
```bash
# tar operations
tar -czf archive.tar.gz directory/
tar -cjf archive.tar.bz2 directory/
tar -tf archive.tar.gz  # List contents
tar -xzf archive.tar.gz  # Extract

# Other compression tools
gzip file.txt
gunzip file.txt.gz
zip -r archive.zip directory/
unzip archive.zip

# Advanced archiving
tar --exclude='*.log' -czf backup.tar.gz /home/user/
tar -czf - directory/ | ssh remote_host 'cat > backup.tar.gz'
```

---

## 🚨 Production File Management Scenarios

### Scenario 1: Large File Cleanup
```bash
# Find large files
find /var/log -type f -size +100M -exec ls -lh {} \;

# Clean old log files
find /var/log -name "*.log" -mtime +30 -delete
find /tmp -type f -atime +7 -delete

# Compress old files
find /var/log -name "*.log" -mtime +7 -exec gzip {} \;

# Truncate active log files (if needed)
> /var/log/large.log
truncate -s 0 /var/log/large.log
```

### Scenario 2: Backup Operations
```bash
# Incremental backup with rsync
rsync -avz --delete /source/ /backup/

# Backup with date stamp
tar -czf backup_$(date +%Y%m%d).tar.gz /important/data/

# Remote backup over SSH
rsync -avz -e ssh /local/path/ user@remote:/backup/path/

# Database backup
mysqldump -u root -p database_name | gzip > db_backup_$(date +%Y%m%d).sql.gz
```

### Scenario 3: File Integrity and Security
```bash
# Generate checksums
md5sum file.txt > file.txt.md5
sha256sum file.txt > file.txt.sha256

# Verify checksums
md5sum -c file.txt.md5
sha256sum -c file.txt.sha256

# Find SUID/SGID files
find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \;

# Find world-writable files
find / -type f -perm -o+w -exec ls -l {} \; 2>/dev/null
```

---

## 📊 File Management Scripts

### File Cleanup Script
```bash
#!/bin/bash
# file-cleanup.sh

LOG_DIR="/var/log"
BACKUP_DIR="/backup"
DAYS_OLD=30

echo "Starting file cleanup process..."

# Clean old log files
echo "Cleaning log files older than $DAYS_OLD days..."
find $LOG_DIR -name "*.log" -mtime +$DAYS_OLD -type f -exec rm -f {} \;

# Compress remaining log files
echo "Compressing log files..."
find $LOG_DIR -name "*.log" -mtime +7 -type f -exec gzip {} \;

# Clean old backups
echo "Cleaning old backup files..."
find $BACKUP_DIR -name "backup_*" -mtime +90 -type f -exec rm -f {} \;

# Clean temporary files
echo "Cleaning temporary files..."
find /tmp -type f -atime +7 -exec rm -f {} \; 2>/dev/null

echo "Cleanup completed."
```

### Backup Script
```bash
#!/bin/bash
# backup-script.sh

SOURCE_DIR="/home"
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_$DATE.tar.gz"
LOG_FILE="/var/log/backup.log"

echo "$(date): Starting backup process" | tee -a $LOG_FILE

# Create backup
if tar -czf $BACKUP_DIR/$BACKUP_NAME $SOURCE_DIR 2>>$LOG_FILE; then
    echo "$(date): Backup completed successfully: $BACKUP_NAME" | tee -a $LOG_FILE
    
    # Generate checksum
    cd $BACKUP_DIR
    sha256sum $BACKUP_NAME > $BACKUP_NAME.sha256
    
    # Remove backups older than 30 days
    find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +30 -delete
    find $BACKUP_DIR -name "backup_*.sha256" -mtime +30 -delete
    
    echo "$(date): Old backups cleaned up" | tee -a $LOG_FILE
else
    echo "$(date): Backup failed" | tee -a $LOG_FILE
    exit 1
fi
```

### File Monitoring Script
```bash
#!/bin/bash
# file-monitor.sh

WATCH_DIR="/etc"
LOG_FILE="/var/log/file-monitor.log"

# Monitor file changes using inotify
inotifywait -m -r -e create,delete,modify,move $WATCH_DIR |
while read path action file; do
    echo "$(date): $action detected on $path$file" | tee -a $LOG_FILE
    
    # Additional actions based on file type
    case $file in
        *.conf)
            echo "$(date): Configuration file changed: $file" | tee -a $LOG_FILE
            ;;
        passwd|shadow|group)
            echo "$(date): Security file modified: $file" | tee -a $LOG_FILE
            ;;
    esac
done
```

---

## 🔍 Advanced File Search and Analysis

### Complex Find Operations
```bash
# Find files with specific criteria
find /var -name "*.log" -size +50M -mtime +7 -exec ls -lh {} \;

# Find and execute commands
find /home -name "*.tmp" -type f -exec rm {} \;
find /etc -name "*.conf" -exec grep -l "password" {} \;

# Find with multiple conditions
find /var/log \( -name "*.log" -o -name "*.out" \) -size +10M

# Find files by content
grep -r "search_term" /path/to/search/
find /path -type f -exec grep -l "pattern" {} \;
```

### File Analysis Tools
```bash
# File statistics
wc -l file.txt  # Line count
wc -w file.txt  # Word count
wc -c file.txt  # Character count

# File encoding detection
file -i file.txt
chardet file.txt

# Binary file analysis
hexdump -C file.bin
od -x file.bin  # Octal dump
strings binary_file  # Extract readable strings
```

---

## 🎯 Interview Questions & Answers

### Q1: "How do you find and delete all files larger than 100MB that haven't been accessed in 30 days?"
**Answer:**
```bash
find / -type f -size +100M -atime +30 -exec ls -lh {} \; 2>/dev/null
# To delete (be careful!):
find / -type f -size +100M -atime +30 -delete 2>/dev/null
```

### Q2: "Explain the difference between hard links and symbolic links"
**Answer:**
```bash
# Hard link: Direct reference to inode
ln original.txt hardlink.txt
ls -li original.txt hardlink.txt  # Same inode number

# Symbolic link: Pointer to filename
ln -s original.txt symlink.txt
ls -li original.txt symlink.txt  # Different inode numbers

# Key differences:
# - Hard links: Cannot cross filesystems, cannot link directories
# - Symbolic links: Can cross filesystems, can link directories
# - Hard links: Original file deletion doesn't break link
# - Symbolic links: Original file deletion breaks link
```

### Q3: "How do you copy files while preserving all attributes and permissions?"
**Answer:**
```bash
# Using cp with archive mode
cp -a source destination

# Using rsync (preferred for large operations)
rsync -avz source/ destination/

# What -a preserves:
# - Permissions (mode, ownership, ACLs)
# - Timestamps (modification, access)
# - Symbolic links
# - Device files and special files
```

---

## 📈 Performance Optimization

### Efficient File Operations
```bash
# Fast file copying for large files
dd if=/source/file of=/dest/file bs=1M status=progress

# Parallel processing with xargs
find /path -name "*.log" -print0 | xargs -0 -P 4 gzip

# Memory-mapped file operations
mmap large_file.txt  # If available

# Use appropriate buffer sizes
rsync -avz --bwlimit=1000 source/ dest/  # Bandwidth limiting
```

### File System Optimization
```bash
# Tune filesystem parameters
tune2fs -l /dev/sda1  # Display filesystem parameters
tune2fs -o journal_data_writeback /dev/sda1

# Check filesystem fragmentation
e4defrag -c /home  # ext4 defragmentation check
```

---

## 🔐 Security Best Practices

### File Permission Auditing
```bash
# Find world-writable directories
find / -type d -perm -o+w -exec ls -ld {} \; 2>/dev/null

# Find files with unusual permissions
find / -type f -perm 777 -exec ls -l {} \; 2>/dev/null

# Audit SUID/SGID files
find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \; 2>/dev/null

# Check file ownership
find /home -nouser -o -nogroup -exec ls -l {} \; 2>/dev/null
```

### File Integrity Monitoring
```bash
# Create file integrity database
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Check for changes
aide --check

# Tripwire alternative using find and checksums
find /etc -type f -exec sha256sum {} \; > /baseline/etc_checksums.txt
```

This comprehensive file management guide covers all essential commands and scenarios for DevOps interviews and daily operations!
