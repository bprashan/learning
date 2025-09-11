# 🌐 Networking Commands

## 🎯 Interview Focus Areas
- Network troubleshooting methodologies
- Firewall configuration and debugging
- DNS resolution issues
- Load balancer and proxy configuration
- Network performance optimization
- Security scanning and hardening

---

## 🟢 Basic Network Commands

### Network Interface Management
```bash
# Interface information
ip addr show
ip link show
ifconfig  # Legacy but still used

# Interface statistics
ip -s link show
cat /proc/net/dev
netstat -i

# Enable/disable interfaces
ip link set eth0 up
ip link set eth0 down
ifup eth0 / ifdown eth0
```

### IP Configuration
```bash
# Add/remove IP addresses
ip addr add 192.168.1.100/24 dev eth0
ip addr del 192.168.1.100/24 dev eth0

# Default gateway
ip route show
ip route add default via 192.168.1.1
route -n  # Legacy routing table

# DNS configuration
cat /etc/resolv.conf
systemd-resolve --status
resolvectl status
```

### Basic Connectivity Tests
```bash
# Ping tests
ping -c 4 8.8.8.8
ping6 -c 4 2001:4860:4860::8888

# Traceroute
traceroute google.com
tracepath google.com
mtr google.com  # Continuous traceroute

# Port connectivity
telnet google.com 80
nc -zv google.com 80  # Netcat port check
```

---

## 🟡 Intermediate Network Operations

### Port and Connection Monitoring
```bash
# Active connections
netstat -tulpn  # All listening ports
ss -tulpn       # Modern replacement for netstat
ss -4 state listening  # IPv4 listening sockets

# Established connections
netstat -tn
ss -tn state established

# Process-port mapping
lsof -i :80
fuser -n tcp 80
```

### Network Traffic Analysis
```bash
# Real-time traffic monitoring
iftop  # Interface traffic
nload  # Network load monitor
bmon   # Bandwidth monitor

# Packet capture
tcpdump -i eth0 -n
tcpdump -i eth0 host 192.168.1.100
tcpdump -i eth0 port 80 -w capture.pcap

# Network statistics
netstat -s  # Protocol statistics
ss -s       # Socket statistics summary
```

### DNS Troubleshooting
```bash
# DNS lookups
nslookup google.com
dig google.com
dig @8.8.8.8 google.com
host google.com

# Reverse DNS
dig -x 8.8.8.8
nslookup 8.8.8.8

# DNS cache operations
systemd-resolve --flush-caches
resolvectl flush-caches
```

---

## 🔴 Expert Level Networking

### Advanced Routing
```bash
# Policy-based routing
ip rule add from 192.168.1.0/24 table 100
ip route add default via 10.0.0.1 table 100
ip route flush cache

# Multiple routing tables
echo "100 custom" >> /etc/iproute2/rt_tables
ip route show table custom

# VLAN configuration
ip link add link eth0 name eth0.100 type vlan id 100
ip addr add 192.168.100.1/24 dev eth0.100
ip link set eth0.100 up
```

### Bridge and Tunnel Configuration
```bash
# Bridge setup
brctl addbr br0
brctl addif br0 eth0
ip link set br0 up

# Using ip commands (modern approach)
ip link add br0 type bridge
ip link set eth0 master br0
ip link set br0 up

# Tunnel creation
ip tunnel add tun0 mode gre local 10.0.0.1 remote 10.0.0.2
ip addr add 172.16.0.1/30 dev tun0
ip link set tun0 up
```

### Network Namespaces
```bash
# Create namespace
ip netns add test_ns
ip netns list

# Configure namespace
ip link add veth0 type veth peer name veth1
ip link set veth1 netns test_ns
ip netns exec test_ns ip addr add 10.0.0.1/24 dev veth1
ip netns exec test_ns ip link set veth1 up

# Execute commands in namespace
ip netns exec test_ns ping 10.0.0.2
```

---

## 🛡️ Firewall and Security

### iptables Management
```bash
# List rules
iptables -L -n -v
iptables -t nat -L -n -v

# Basic rules
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -j DROP

# NAT configuration
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Save/restore rules
iptables-save > /etc/iptables/rules.v4
iptables-restore < /etc/iptables/rules.v4
```

### Firewalld (RHEL/CentOS)
```bash
# Service management
systemctl status firewalld
firewall-cmd --state

# Zone management
firewall-cmd --get-default-zone
firewall-cmd --list-all-zones
firewall-cmd --set-default-zone=public

# Rule management
firewall-cmd --add-service=http --permanent
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
```

### UFW (Ubuntu)
```bash
# Basic UFW operations
ufw status
ufw enable
ufw default deny incoming
ufw default allow outgoing

# Allow specific services
ufw allow ssh
ufw allow 80/tcp
ufw allow from 192.168.1.0/24
```

---

## 🚨 Network Troubleshooting Scenarios

### Scenario 1: Cannot Connect to Service
```bash
# Step 1: Check local service
systemctl status service_name
netstat -tlnp | grep :80

# Step 2: Check firewall
iptables -L -n | grep :80
firewall-cmd --list-services

# Step 3: Check routing
ip route get 192.168.1.100
ping -c 1 192.168.1.100

# Step 4: Check DNS
nslookup service.domain.com
dig service.domain.com

# Step 5: Test with different tools
curl -v http://service.domain.com
telnet service.domain.com 80
nc -zv service.domain.com 80
```

### Scenario 2: High Network Latency
```bash
# Network latency analysis
ping -c 10 target_host
mtr --report target_host

# Check for packet loss
ping -c 100 target_host | grep "packet loss"

# Network interface errors
ip -s link show eth0
ethtool -S eth0

# Check network congestion
ss -i  # Socket information with congestion details
```

### Scenario 3: DNS Resolution Issues
```bash
# Test DNS servers
dig @8.8.8.8 domain.com
dig @1.1.1.1 domain.com

# Check DNS configuration
cat /etc/resolv.conf
systemd-resolve --status

# Clear DNS cache
systemd-resolve --flush-caches
service nscd restart  # If nscd is running

# Test with different record types
dig domain.com A
dig domain.com AAAA
dig domain.com MX
```

---

## 📊 Network Monitoring Scripts

### Network Health Check Script
```bash
#!/bin/bash
# network-health-check.sh

echo "=== Network Health Check ==="
echo "Date: $(date)"

# Check interface status
echo -e "\n1. Interface Status:"
ip link show | grep -E "^[0-9]+:" | awk '{print $2 $9}' | sed 's/:/ -/'

# Check IP configuration
echo -e "\n2. IP Configuration:"
ip addr show | grep "inet " | grep -v "127.0.0.1"

# Check default gateway
echo -e "\n3. Default Gateway:"
ip route | grep default

# Check DNS
echo -e "\n4. DNS Test:"
for dns in 8.8.8.8 1.1.1.1; do
    if ping -c 1 $dns &>/dev/null; then
        echo "DNS $dns: OK"
    else
        echo "DNS $dns: FAILED"
    fi
done

# Check internet connectivity
echo -e "\n5. Internet Connectivity:"
if curl -s --connect-timeout 5 http://google.com &>/dev/null; then
    echo "Internet: OK"
else
    echo "Internet: FAILED"
fi

echo "=== Check Complete ==="
```

### Port Scanner Script
```bash
#!/bin/bash
# port-scanner.sh

TARGET=${1:-localhost}
PORTS=${2:-"22 23 25 53 80 110 143 443 993 995"}

echo "Scanning $TARGET for open ports..."

for port in $PORTS; do
    if nc -zv -w1 $TARGET $port 2>/dev/null; then
        echo "Port $port: OPEN"
    else
        echo "Port $port: CLOSED"
    fi
done
```

### Network Traffic Monitor
```bash
#!/bin/bash
# traffic-monitor.sh

INTERFACE=${1:-eth0}
INTERVAL=${2:-5}

echo "Monitoring traffic on $INTERFACE (interval: ${INTERVAL}s)"
echo "Press Ctrl+C to stop"

while true; do
    RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
    
    sleep $INTERVAL
    
    RX_BYTES_NEW=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX_BYTES_NEW=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
    
    RX_RATE=$(( (RX_BYTES_NEW - RX_BYTES) / INTERVAL ))
    TX_RATE=$(( (TX_BYTES_NEW - TX_BYTES) / INTERVAL ))
    
    echo "$(date): RX: $(numfmt --to=iec $RX_RATE)/s TX: $(numfmt --to=iec $TX_RATE)/s"
done
```

---

## 🎯 Performance Optimization

### Network Tuning Parameters
```bash
# TCP tuning
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> /etc/sysctl.conf

# Apply changes
sysctl -p

# Check current values
sysctl net.core.rmem_max
sysctl net.ipv4.tcp_congestion_control
```

### Interface Tuning
```bash
# Check interface settings
ethtool eth0

# Modify interface parameters
ethtool -G eth0 rx 4096 tx 4096  # Ring buffer size
ethtool -K eth0 tso on gso on    # Offloading features
ethtool -s eth0 speed 1000 duplex full  # Speed/duplex
```

---

## 🎯 Interview Questions & Answers

### Q1: "How do you troubleshoot packet loss?"
**Answer:**
```bash
# 1. Check interface statistics
ip -s link show eth0
ethtool -S eth0 | grep -i drop

# 2. Use mtr for path analysis
mtr --report-cycles 100 target_host

# 3. Check buffer sizes
ss -i  # Look for retransmissions
netstat -s | grep -i drop

# 4. Monitor with tcpdump
tcpdump -i eth0 -c 1000 | wc -l  # Packet count
```

### Q2: "Explain the difference between TCP and UDP, with examples"
**Answer:**
```bash
# TCP (Transmission Control Protocol):
# - Connection-oriented, reliable
# - Examples: HTTP, SSH, FTP
netstat -tn  # Show TCP connections

# UDP (User Datagram Protocol):
# - Connectionless, faster
# - Examples: DNS, DHCP, NTP
netstat -un  # Show UDP connections

# Test TCP connection
nc -v google.com 80

# Test UDP connection
nc -vu 8.8.8.8 53
```

### Q3: "How do you configure a Linux server as a router?"
**Answer:**
```bash
# 1. Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf

# 2. Configure NAT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# 3. Save configuration
iptables-save > /etc/iptables/rules.v4
```

---

## 🔒 Security Commands

### Network Security Scanning
```bash
# Port scanning
nmap -sS target_host  # SYN scan
nmap -sU target_host  # UDP scan
nmap -A target_host   # Aggressive scan

# Network discovery
nmap -sn 192.168.1.0/24  # Ping sweep
arp-scan -I eth0 192.168.1.0/24

# SSL/TLS testing
openssl s_client -connect google.com:443
nmap --script ssl-enum-ciphers -p 443 google.com
```

### Intrusion Detection
```bash
# Monitor for suspicious connections
netstat -tn | awk '{print $5}' | sort | uniq -c | sort -nr

# Check for unusual network activity
ss -tp | grep ESTAB | awk '{print $4}' | sort | uniq -c

# Monitor failed connection attempts
journalctl -u ssh | grep "Failed password"
```

This comprehensive networking guide covers all essential commands for DevOps interviews and daily network administration tasks!
