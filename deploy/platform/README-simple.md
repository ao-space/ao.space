# AO.Space Platform - Simplified Deployment

Single-machine deployment for personal use with security hardening.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Cloud Platform Deployment](#cloud-platform-deployment)
- [DNS Configuration](#dns-configuration)
- [SSL Certificate](#ssl-certificate)
- [Security Hardening](#security-hardening)
- [Port Reference](#port-reference)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Docker 20.10+ and Docker Compose v2
- A domain with DNS access (e.g., Cloudflare)
- Public IP or port forwarding configured
- **Minimum**: 2 CPU, 4GB RAM, 40GB SSD
- **Recommended**: 4 CPU, 8GB RAM, 100GB SSD

---

## Quick Start

### Automated Secure Setup (Recommended)

```bash
cd deploy/platform

# Run secure setup wizard
chmod +x scripts/secure-setup.sh
./scripts/secure-setup.sh

# Add your SSL certificate
# (see SSL Certificate section below)

# Start the platform
docker compose -f docker-compose.simple.yml up -d

# Initialize network server
./scripts/init-network.sh

# Verify deployment
curl -H "Request-Id: test" https://your-domain.com/v2/platform/status
```

### Manual Setup

```bash
cd deploy/platform

# 1. Create and configure .env
cp .env.simple.example .env
# Generate passwords: openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24
nano .env

# 2. Set permissions
chmod 600 .env

# 3. Create data directories
mkdir -p data/{mysql,redis,ssl,services}
chmod 700 data/mysql data/redis data/ssl

# 4. Add SSL certificate
# Copy tls.crt and tls.key to data/ssl/
chmod 600 data/ssl/*

# 5. Start and verify
docker compose -f docker-compose.simple.yml up -d
./scripts/init-network.sh
```

---

## Cloud Platform Deployment

### AWS EC2

#### Instance Configuration
| Setting | Recommended |
|---------|-------------|
| Instance Type | t3.medium (4GB) or t3.large (8GB) |
| AMI | Ubuntu 22.04 LTS or Amazon Linux 2023 |
| Storage | 100GB gp3 SSD |
| Elastic IP | Yes (for stable DNS) |

#### Security Group Rules
| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| SSH | TCP | 22 | Your IP | Management |
| HTTP | TCP | 80 | 0.0.0.0/0 | Redirect to HTTPS |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Platform API |
| Custom | TCP | 61012 | 0.0.0.0/0 | GT Server |
| Custom | UDP | 3478 | 0.0.0.0/0 | STUN |

```bash
# Install Docker on Ubuntu
sudo apt update && sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
# Re-login to apply group

# Clone and deploy
git clone --recurse-submodules https://github.com/ao-space/ao.space.git
cd ao.space/deploy/platform
./scripts/secure-setup.sh
```

---

### Alibaba Cloud ECS

#### Instance Configuration
| Setting | Recommended |
|---------|-------------|
| Instance Type | ecs.c6.large (2vCPU, 4GB) or ecs.c6.xlarge |
| Image | Ubuntu 22.04 or Alibaba Cloud Linux 3 |
| System Disk | 100GB ESSD |
| Public IP | EIP (Elastic IP) |

#### Security Group Rules
```
Inbound:
  - 22/TCP   from Your IP    (SSH)
  - 80/TCP   from 0.0.0.0/0  (HTTP)
  - 443/TCP  from 0.0.0.0/0  (HTTPS)
  - 61012/TCP from 0.0.0.0/0 (GT Server)
  - 3478/UDP from 0.0.0.0/0  (STUN)

Outbound:
  - All traffic allowed
```

```bash
# Install Docker on Alibaba Cloud Linux
sudo yum install -y docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

---

### Tencent Cloud CVM

#### Instance Configuration
| Setting | Recommended |
|---------|-------------|
| Instance Type | S5.MEDIUM4 (2vCPU, 4GB) or S5.LARGE8 |
| Image | Ubuntu 22.04 LTS |
| System Disk | 100GB SSD |
| Public IP | EIP |

#### Security Group
Same ports as Alibaba Cloud.

---

### Azure VM

#### Instance Configuration
| Setting | Recommended |
|---------|-------------|
| Size | Standard_B2s (2vCPU, 4GB) or Standard_B2ms |
| Image | Ubuntu Server 22.04 LTS |
| OS Disk | 128GB Premium SSD |
| Public IP | Static |

#### Network Security Group
```
Inbound Security Rules:
  Priority  Name        Port    Protocol  Source
  100       SSH         22      TCP       Your IP
  110       HTTP        80      TCP       Any
  120       HTTPS       443     TCP       Any
  130       GTServer    61012   TCP       Any
  140       STUN        3478    UDP       Any
```

---

## DNS Configuration

### Cloudflare Setup

1. Go to Cloudflare Dashboard → Your Domain → DNS
2. Add these records (replace `YOUR_SERVER_IP`):

| Type | Name | Content | Proxy | TTL |
|------|------|---------|-------|-----|
| A | @ | YOUR_SERVER_IP | DNS only (gray) | Auto |
| A | * | YOUR_SERVER_IP | DNS only (gray) | Auto |

**Important**: Must use "DNS only" (gray cloud), not "Proxied" (orange cloud) for GT server to work.

### Other DNS Providers

Same concept - create A record for root domain and wildcard:
- `example.com` → YOUR_SERVER_IP
- `*.example.com` → YOUR_SERVER_IP

---

## SSL Certificate

### Option 1: Cloudflare Origin Certificate (Recommended for Cloudflare DNS)

1. Cloudflare Dashboard → SSL/TLS → Origin Server
2. Create Certificate:
   - Private key type: RSA (2048)
   - Hostnames: `*.example.com`, `example.com`
   - Validity: 15 years
3. Download and save:
   ```bash
   # Save certificate content to data/ssl/tls.crt
   # Save private key content to data/ssl/tls.key
   chmod 600 data/ssl/tls.crt data/ssl/tls.key
   ```

### Option 2: Let's Encrypt (Free, Auto-Renew)

```bash
# Install acme.sh
curl https://get.acme.sh | sh

# Using Cloudflare DNS (recommended)
export CF_Token="your-cloudflare-api-token"
export CF_Zone_ID="your-zone-id"

acme.sh --issue --dns dns_cf \
  -d example.com \
  -d '*.example.com'

# Copy certificates
mkdir -p deploy/platform/data/ssl
cp ~/.acme.sh/example.com/example.com.cer deploy/platform/data/ssl/tls.crt
cp ~/.acme.sh/example.com/example.com.key deploy/platform/data/ssl/tls.key
chmod 600 deploy/platform/data/ssl/*

# Set up auto-renewal
acme.sh --install-cert -d example.com \
  --key-file /path/to/deploy/platform/data/ssl/tls.key \
  --fullchain-file /path/to/deploy/platform/data/ssl/tls.crt \
  --reloadcmd "docker compose -f docker-compose.simple.yml restart aoplatform-nginx"
```

### Option 3: Commercial Certificate

Purchase from your provider and copy to `data/ssl/tls.crt` and `data/ssl/tls.key`.

---

## Security Hardening

### 1. Firewall Configuration (UFW)

```bash
# Install and configure UFW
sudo apt install -y ufw

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow required ports
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw allow 61012/tcp comment 'GT Server'
sudo ufw allow 3478/udp comment 'STUN'

# Enable firewall
sudo ufw enable
sudo ufw status verbose
```

### 2. SSH Hardening

```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Recommended settings:
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2

# Restart SSH
sudo systemctl restart sshd
```

### 3. Automatic Security Updates

```bash
# Ubuntu/Debian
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Verify
cat /etc/apt/apt.conf.d/20auto-upgrades
```

### 4. Fail2ban (Brute Force Protection)

```bash
# Install
sudo apt install -y fail2ban

# Configure
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

sudo systemctl enable --now fail2ban
```

### 5. Docker Security

```bash
# Run containers with limited privileges (already configured in compose)
# Verify no-new-privileges is set
docker inspect aoplatform-services | grep -A5 SecurityOpt
```

### 6. Log Rotation

```bash
# Configure Docker log rotation (already set in compose)
# Verify:
docker inspect aoplatform-services | grep -A10 LogConfig
```

---

## Port Reference

| Port | Protocol | Purpose | Required |
|------|----------|---------|----------|
| 80 | TCP | HTTP (redirects to HTTPS) | Yes |
| 443 | TCP | HTTPS (platform API + user spaces) | Yes |
| 61012 | TCP | GT Server (NAT traversal) | Yes |
| 3478 | UDP | STUN (P2P connection) | Yes |
| 22 | TCP | SSH (management) | Recommended |

---

## Container Overview

| Container | Purpose | Resources |
|-----------|---------|-----------|
| aoplatform-mysql | Database | ~500MB RAM |
| aoplatform-redis | Cache + routing | ~100MB RAM |
| aoplatform-services | Core API (Quarkus) | 512MB-1GB RAM |
| aoplatform-proxy | User space routing | ~100MB RAM |
| aoplatform-nginx | HTTPS termination | ~50MB RAM |
| aonetwork-server | NAT traversal | ~100MB RAM |

---

## Troubleshooting

### View Logs

```bash
# All services
docker compose -f docker-compose.simple.yml logs -f

# Specific service
docker compose -f docker-compose.simple.yml logs -f aoplatform-services

# Last 100 lines
docker compose -f docker-compose.simple.yml logs --tail=100 aoplatform-nginx
```

### Service Health

```bash
# Check all services
docker compose -f docker-compose.simple.yml ps

# Check specific container
docker inspect aoplatform-services --format='{{.State.Health.Status}}'
```

### Common Issues

**1. SSL certificate errors**
```bash
# Verify certificate
openssl x509 -in data/ssl/tls.crt -text -noout | head -20

# Check certificate matches key
openssl x509 -noout -modulus -in data/ssl/tls.crt | md5sum
openssl rsa -noout -modulus -in data/ssl/tls.key | md5sum
# Both should match
```

**2. Database connection failed**
```bash
# Check MySQL logs
docker compose -f docker-compose.simple.yml logs aoplatform-mysql

# Verify MySQL is healthy
docker exec aoplatform-mysql mysqladmin ping -u root -p
```

**3. Rate limiting issues**
```bash
# Check current rate limit setting
grep RATE_LIMIT_RPS .env

# Increase if needed (edit .env)
RATE_LIMIT_RPS=50

# Restart nginx
docker compose -f docker-compose.simple.yml restart aoplatform-nginx
```

### Full Restart

```bash
docker compose -f docker-compose.simple.yml down
docker compose -f docker-compose.simple.yml up -d
```

---

## Data Persistence

All data is stored in `./data/`:
- `data/mysql/` - Database files
- `data/redis/` - Cache and routing data
- `data/ssl/` - SSL certificates
- `data/services/` - Service attachments

### Backup

```bash
# Stop services
docker compose -f docker-compose.simple.yml stop

# Backup data directory
tar -czvf backup-$(date +%Y%m%d).tar.gz data/

# Restart services
docker compose -f docker-compose.simple.yml start
```

---

## Simplified API

Register a space with one API call:

```bash
curl -X POST https://your-domain.com/v2/platform/spaces \
  -H "Content-Type: application/json" \
  -H "Request-Id: $(uuidgen)" \
  -d '{
    "boxUUID": "your-box-uuid",
    "userId": "admin",
    "clientUUID": "your-client-uuid",
    "subdomain": "myspace"
  }'
```

See [Platform API Changes](../../docs/en/platform-api-changes.md) for complete API documentation.
