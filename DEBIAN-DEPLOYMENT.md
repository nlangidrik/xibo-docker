# Xibo Debian VM Deployment Guide

This guide is specifically tailored for deploying Xibo on a Debian virtual machine.

## Debian VM Prerequisites

### System Requirements
- **Debian Version**: 11 (Bullseye) or 12 (Bookworm) recommended
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Storage**: Minimum 20GB free space
- **CPU**: 2+ cores recommended
- **Network**: Static IP recommended for production

### Install Docker on Debian

```bash
# Update package index
sudo apt update

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker
```

### Install Git
```bash
sudo apt install -y git
```

## Deploy Xibo

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd xibo-docker
```

### 2. Configure Environment
```bash
# Copy template
cp config.env.template config.env

# Edit configuration (use nano, vim, or your preferred editor)
nano config.env
```

**Key Debian-specific settings:**
```bash
# Set your server's IP or domain
CMS_SERVER_NAME=your-debian-vm-ip-or-domain

# Set a strong MySQL password
MYSQL_PASSWORD=YourSecurePassword123

# Configure SMTP (optional but recommended)
CMS_SMTP_SERVER=smtp.gmail.com:587
CMS_SMTP_USERNAME=your-email@gmail.com
CMS_SMTP_PASSWORD=your-app-password
```

### 3. Start Xibo
```bash
# Make script executable
chmod +x start-xibo.sh

# Start Xibo
./start-xibo.sh
```

### 4. Verify Installation
```bash
# Check all containers are running
docker ps

# Test web interface
curl -I http://localhost
```

## Debian-Specific Configuration

### Firewall Setup (UFW)
```bash
# Install UFW if not present
sudo apt install -y ufw

# Allow SSH (important!)
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### System Optimization
```bash
# Increase file descriptor limits
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimize kernel parameters
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Auto-start on Boot
Create a systemd service to auto-start Xibo:

```bash
# Create service file
sudo nano /etc/systemd/system/xibo.service
```

Add this content:
```ini
[Unit]
Description=Xibo Docker Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/path/to/your/xibo-docker
ExecStart=/path/to/your/xibo-docker/start-xibo.sh
ExecStop=/path/to/your/xibo-docker/stop-xibo.sh
User=your-username
Group=docker

[Install]
WantedBy=multi-user.target
```

Enable the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable xibo.service
```

## Monitoring and Maintenance

### Check Service Status
```bash
# Check Xibo containers
docker ps | grep xibo

# Check system resources
htop
df -h

# Check logs
docker compose logs
```

### Backup Script for Debian
Create a backup script:

```bash
nano backup-xibo.sh
```

```bash
#!/bin/bash
# Xibo Backup Script for Debian

BACKUP_DIR="/backup/xibo-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup database
docker exec xibo-docker-cms-db-1 mysqldump -u cms -p"$MYSQL_PASSWORD" cms > "$BACKUP_DIR/database.sql"

# Backup shared directory
cp -r ./shared "$BACKUP_DIR/"

# Compress backup
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo "Backup created: $BACKUP_DIR.tar.gz"
```

Make it executable:
```bash
chmod +x backup-xibo.sh
```

## Troubleshooting

### Common Debian Issues

**Permission Denied:**
```bash
# Fix Docker permissions
sudo usermod -aG docker $USER
# Logout and login again
```

**Port Already in Use:**
```bash
# Check what's using port 80
sudo netstat -tlnp | grep :80
sudo lsof -i :80
```

**Docker Service Not Starting:**
```bash
# Check Docker status
sudo systemctl status docker
sudo journalctl -u docker.service
```

**Memory Issues:**
```bash
# Check memory usage
free -h
# Add swap if needed
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## Security Recommendations

1. **Keep Debian Updated:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Use SSH Keys:**
   ```bash
   # Generate SSH key pair
   ssh-keygen -t rsa -b 4096
   ```

3. **Regular Backups:**
   - Set up automated backups using cron
   - Store backups on external storage

4. **Monitor Logs:**
   ```bash
   # Install log monitoring
   sudo apt install -y logwatch
   ```

## Access Your Xibo

Once deployed, access your Xibo installation at:
- **Local**: `http://localhost`
- **Network**: `http://your-debian-vm-ip`
- **Domain**: `http://your-domain.com` (if configured)

The startup script handles all the complexity, so your Xibo will be running at 100% capacity with full XMR functionality!
