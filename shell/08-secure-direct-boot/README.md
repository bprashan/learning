# 🔐 Secure Boot & Direct Boot Commands

## 🎯 Interview Focus Areas
- UEFI Secure Boot implementation and troubleshooting
- Boot process security and integrity
- Direct boot mechanisms and optimization
- Certificate management for secure boot
- Boot loader security and configuration
- Trusted boot and measured boot concepts

---

## 🟢 Basic Boot Security Concepts

### UEFI and Secure Boot Status
```bash
# Check if system uses UEFI
ls /sys/firmware/efi
efibootmgr -v
cat /proc/efi/esrt  # EFI System Resource Table

# Secure Boot status
mokutil --sb-state
bootctl status  # systemd-boot systems
dmesg | grep -i "secure boot"

# Boot mode information
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "Legacy BIOS"
cat /sys/class/dmi/id/bios_version
```

### Boot Process Analysis
```bash
# Boot time analysis
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# Boot loader information
efibootmgr -v
cat /boot/efi/EFI/*/grub.cfg  # GRUB on UEFI
cat /boot/grub/grub.cfg       # GRUB on BIOS

# Kernel command line
cat /proc/cmdline
```

### TPM (Trusted Platform Module) Status
```bash
# Check TPM presence
ls /dev/tpm*
cat /sys/class/tpm/tpm*/device/description

# TPM tools
tpm2_getcap handles-transient
tpm2_getcap properties-fixed
tpm2_pcrread  # Platform Configuration Registers
```

---

## 🟡 Intermediate Secure Boot Management

### MOK (Machine Owner Key) Management
```bash
# List enrolled keys
mokutil --list-enrolled
mokutil --list-enrolled --ca  # Certificate authorities

# Enroll new MOK key
mokutil --import /path/to/key.der
mokutil --list-new  # Show keys pending enrollment

# Delete MOK keys
mokutil --delete /path/to/key.der
mokutil --list-delete  # Show keys pending deletion

# Reset MOK
mokutil --reset
```

### Secure Boot Key Management
```bash
# Check secure boot variables
efi-readvar -v PK    # Platform Key
efi-readvar -v KEK   # Key Exchange Key
efi-readvar -v db    # Signature Database
efi-readvar -v dbx   # Forbidden Signature Database

# Update secure boot variables (requires setup mode)
efi-updatevar -f /path/to/key.esl db
efi-updatevar -f /path/to/key.esl KEK

# Create key databases
cert-to-efi-sig-list cert.pem cert.esl
sign-efi-sig-list -k PK.key -c PK.pem db cert.esl cert.auth
```

### GRUB Secure Boot Configuration
```bash
# Generate GRUB configuration
grub-mkconfig -o /boot/grub/grub.cfg

# Sign GRUB modules
grub-install --target=x86_64-efi --efi-directory=/boot/efi \
  --bootloader-id=GRUB --secure-boot

# Verify GRUB signature
sbverify --list /boot/efi/EFI/GRUB/grubx64.efi
```

---

## 🔴 Expert Level Boot Security

### Custom Secure Boot Implementation
```bash
# Generate custom keys
openssl req -new -x509 -newkey rsa:2048 -keyout PK.key -out PK.pem \
  -days 3650 -nodes -subj "/CN=Platform Key/"

openssl req -new -x509 -newkey rsa:2048 -keyout KEK.key -out KEK.pem \
  -days 3650 -nodes -subj "/CN=Key Exchange Key/"

openssl req -new -x509 -newkey rsa:2048 -keyout db.key -out db.pem \
  -days 3650 -nodes -subj "/CN=Signature Database/"

# Convert to EFI format
cert-to-efi-sig-list -g "$(uuidgen)" PK.pem PK.esl
cert-to-efi-sig-list -g "$(uuidgen)" KEK.pem KEK.esl
cert-to-efi-sig-list -g "$(uuidgen)" db.pem db.esl

# Sign databases
sign-efi-sig-list -k PK.key -c PK.pem KEK KEK.esl KEK.auth
sign-efi-sig-list -k KEK.key -c KEK.pem db db.esl db.auth
sign-efi-sig-list -k PK.key -c PK.pem PK PK.esl PK.auth
```

### Direct Boot Configuration
```bash
# Direct kernel boot (bypass bootloader)
efibootmgr --create --disk /dev/sda --part 1 \
  --loader /vmlinuz --label "Direct Boot" \
  --unicode 'root=/dev/sda2 ro quiet'

# systemd-boot configuration
bootctl install
cat > /boot/loader/loader.conf << EOF
default arch
timeout 3
editor 0
EOF

cat > /boot/loader/entries/arch.conf << EOF
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=/dev/sda2 rw
EOF
```

### Measured Boot and Attestation
```bash
# PCR (Platform Configuration Register) values
tpm2_pcrread sha256

# Extend PCR with measurement
echo "test measurement" | tpm2_pcrextend 16:sha256

# Create attestation key
tpm2_createak -C primary.ctx -c ak.ctx -u ak.pub -r ak.priv

# Quote PCR values
tpm2_quote -c ak.ctx -l sha256:0,1,2,3,4,5,6,7 -q "nonce" -m quote.msg -s quote.sig
```

---

## 🚨 Boot Security Troubleshooting

### Secure Boot Issues
```bash
# Common secure boot problems
dmesg | grep -i "secure boot"
dmesg | grep -i "verification failed"

# Check if kernel is signed
sbverify --list /boot/vmlinuz-$(uname -r)

# Verify bootloader signature
sbverify --list /boot/efi/EFI/*/grubx64.efi

# Boot without secure boot (emergency)
# 1. Enter UEFI setup
# 2. Disable Secure Boot
# 3. Boot system
# 4. Fix signing issues
# 5. Re-enable Secure Boot
```

### MOK Enrollment Issues
```bash
# Check MOK enrollment status
mokutil --sb-state
mokutil --list-enrolled

# Clear MOK enrollment queue
mokutil --reset

# Manual MOK enrollment
# 1. Boot system
# 2. MOK Manager will appear
# 3. Select "Enroll MOK"
# 4. Browse to key file
# 5. Enter password
# 6. Reboot
```

### Boot Performance Issues
```bash
# Analyze slow boot
systemd-analyze blame | head -20
systemd-analyze critical-chain

# Boot chart visualization
systemd-analyze plot > boot-chart.svg

# Disable unnecessary services
systemctl disable service_name
systemctl mask service_name  # Completely disable
```

---

## 📊 Boot Security Monitoring Scripts

### Secure Boot Status Monitor
```bash
#!/bin/bash
# secure-boot-monitor.sh

LOG_FILE="/var/log/secure-boot-status.log"

echo "$(date): Secure Boot Status Check" | tee -a $LOG_FILE

# Check Secure Boot state
SB_STATE=$(mokutil --sb-state 2>/dev/null | grep "SecureBoot" | awk '{print $2}')
echo "$(date): Secure Boot: $SB_STATE" | tee -a $LOG_FILE

# Check MOK state
MOK_COUNT=$(mokutil --list-enrolled 2>/dev/null | grep "SHA1 Fingerprint" | wc -l)
echo "$(date): Enrolled MOK certificates: $MOK_COUNT" | tee -a $LOG_FILE

# Check for pending MOK operations
NEW_MOKS=$(mokutil --list-new 2>/dev/null | grep "SHA1 Fingerprint" | wc -l)
DEL_MOKS=$(mokutil --list-delete 2>/dev/null | grep "SHA1 Fingerprint" | wc -l)

if [ $NEW_MOKS -gt 0 ]; then
    echo "$(date): WARNING: $NEW_MOKS MOK certificates pending enrollment" | tee -a $LOG_FILE
fi

if [ $DEL_MOKS -gt 0 ]; then
    echo "$(date): WARNING: $DEL_MOKS MOK certificates pending deletion" | tee -a $LOG_FILE
fi

# Check kernel signature
KERNEL_PATH="/boot/vmlinuz-$(uname -r)"
if sbverify --list "$KERNEL_PATH" &>/dev/null; then
    echo "$(date): Kernel signature: VALID" | tee -a $LOG_FILE
else
    echo "$(date): Kernel signature: INVALID or MISSING" | tee -a $LOG_FILE
fi

echo "$(date): Check completed" | tee -a $LOG_FILE
```

### Boot Time Analyzer
```bash
#!/bin/bash
# boot-time-analyzer.sh

REPORT_FILE="/var/log/boot-time-analysis.log"

echo "=== Boot Time Analysis ===" | tee $REPORT_FILE
echo "Date: $(date)" | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Overall boot time
echo "=== Overall Boot Time ===" | tee -a $REPORT_FILE
systemd-analyze | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Top 10 slowest services
echo "=== Top 10 Slowest Services ===" | tee -a $REPORT_FILE
systemd-analyze blame | head -10 | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Critical chain
echo "=== Critical Chain ===" | tee -a $REPORT_FILE
systemd-analyze critical-chain | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Boot loader time
FIRMWARE_TIME=$(systemd-analyze | grep "firmware" | awk '{print $4}')
LOADER_TIME=$(systemd-analyze | grep "loader" | awk '{print $6}')

echo "=== Boot Stages ===" | tee -a $REPORT_FILE
echo "Firmware: $FIRMWARE_TIME" | tee -a $REPORT_FILE
echo "Loader: $LOADER_TIME" | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Generate plot
systemd-analyze plot > /tmp/boot-chart.svg
echo "Boot chart saved to: /tmp/boot-chart.svg" | tee -a $REPORT_FILE
```

### TPM Status Monitor
```bash
#!/bin/bash
# tpm-monitor.sh

if [ ! -c /dev/tpm0 ]; then
    echo "TPM device not found"
    exit 1
fi

echo "=== TPM Status Report ==="
echo "Date: $(date)"
echo ""

# TPM version
echo "=== TPM Version ==="
cat /sys/class/tpm/tpm0/device/description
echo ""

# PCR values
echo "=== PCR Values ==="
tpm2_pcrread sha256:0,1,2,3,4,5,6,7,8,9
echo ""

# TPM capabilities
echo "=== TPM Capabilities ==="
tpm2_getcap properties-fixed | grep -E "(TPM_PT_FAMILY_INDICATOR|TPM_PT_LEVEL|TPM_PT_REVISION)"
echo ""

# Measured boot events
if [ -f /sys/kernel/security/tpm0/binary_bios_measurements ]; then
    echo "=== Recent Boot Events ==="
    # Parse binary measurements (simplified)
    hexdump -C /sys/kernel/security/tpm0/binary_bios_measurements | tail -10
fi
```

---

## 🔧 Boot Optimization and Security

### Secure Boot Best Practices
```bash
# 1. Use custom keys instead of manufacturer keys
# 2. Regularly update and rotate keys
# 3. Monitor for unauthorized key enrollment
# 4. Implement measured boot with TPM
# 5. Use direct boot for faster boot times

# Key rotation script
rotate_secure_boot_keys() {
    # Backup current keys
    mkdir -p /backup/secure-boot-keys/$(date +%Y%m%d)
    
    # Generate new keys
    # ... (key generation commands)
    
    # Update secure boot variables
    # ... (update commands)
    
    echo "Secure Boot keys rotated successfully"
}
```

### Direct Boot Optimization
```bash
# Skip bootloader timeout
echo 'GRUB_TIMEOUT=0' >> /etc/default/grub
update-grub

# Use systemd-boot for faster boot
bootctl install
# Configure entries in /boot/loader/entries/

# Optimize initramfs
echo 'COMPRESS="lz4"' >> /etc/initramfs-tools/initramfs.conf
update-initramfs -u

# Disable unnecessary services
systemctl disable bluetooth.service
systemctl disable cups.service
systemctl mask plymouth-start.service
```

---

## 🎯 Interview Questions & Answers

### Q1: "What is Secure Boot and how does it work?"
**Answer:**
```bash
# Secure Boot is a UEFI security feature that ensures
# only signed bootloaders and kernels can run

# Chain of trust:
# 1. UEFI firmware verifies bootloader signature
# 2. Bootloader verifies kernel signature
# 3. Kernel verifies module signatures

# Check Secure Boot status
mokutil --sb-state
dmesg | grep -i "secure boot"

# Key hierarchy:
# PK (Platform Key) -> KEK (Key Exchange Key) -> db (Database)
```

### Q2: "How do you troubleshoot a system that won't boot after enabling Secure Boot?"
**Answer:**
```bash
# Troubleshooting steps:

# 1. Check if kernel is signed
sbverify --list /boot/vmlinuz-$(uname -r)

# 2. Check bootloader signature
sbverify --list /boot/efi/EFI/*/grubx64.efi

# 3. Check for MOK enrollment issues
mokutil --list-enrolled

# 4. Temporary workaround - disable Secure Boot in UEFI
# 5. Fix signing issues
# 6. Re-enable Secure Boot

# Common fixes:
# - Enroll MOK key for unsigned drivers
# - Update bootloader
# - Reinstall kernel with signed version
```

### Q3: "Explain the difference between Secure Boot and Trusted Boot"
**Answer:**
```bash
# Secure Boot:
# - UEFI feature
# - Verifies cryptographic signatures
# - Prevents unsigned code execution
# - Binary decision: allow or deny

# Trusted Boot (Measured Boot):
# - Uses TPM to measure boot components
# - Records measurements in PCRs
# - Enables attestation and sealing
# - Provides audit trail

# Check TPM measurements
tpm2_pcrread sha256

# Trusted Boot enables:
# - Remote attestation
# - Sealed storage
# - Boot integrity monitoring
```

---

## 🔒 Advanced Security Features

### LUKS with TPM Integration
```bash
# Bind LUKS key to TPM PCRs
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 /dev/sda1

# Automatic LUKS unlock during boot
echo "luks-volume /dev/sda1 none tpm2-device=auto,tpm2-pcrs=0+2+7" >> /etc/crypttab
```

### Boot Attestation
```bash
# Generate attestation report
tpm2_quote -c ak.ctx -l sha256:0,1,2,3,4,5,6,7 -q $(openssl rand -hex 16) \
  -m quote.msg -s quote.sig

# Verify attestation
tpm2_checkquote -u ak.pub -m quote.msg -s quote.sig -f quote.pcrs -g sha256
```

This comprehensive secure boot guide covers all essential security concepts and commands for DevOps interviews and secure system administration!
