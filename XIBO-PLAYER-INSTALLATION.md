# Xibo Player Installation Guide

This guide covers installing Xibo players on various devices including Raspberry Pi and thin clients.

## Overview

Xibo players are lightweight applications that connect to your Xibo CMS to display content. They run independently on display devices and communicate with your CMS server.

## Supported Platforms

### Raspberry Pi
- **Raspberry Pi OS** (recommended)
- **Ubuntu for Raspberry Pi**
- **DietPi** (lightweight option)

### Thin Clients
- **Windows 10/11 IoT**
- **Linux-based thin clients**
- **Chrome OS devices**

### Other Platforms
- **Windows 10/11**
- **Ubuntu/Debian**
- **CentOS/RHEL**
- **macOS**

## Raspberry Pi Installation

### Prerequisites
- Raspberry Pi 4 (4GB RAM recommended) or newer
- MicroSD card (32GB+ recommended)
- Stable internet connection
- HDMI display

### Method 1: Xibo Pi OS (Recommended)

1. **Download Xibo Pi OS:**
   ```bash
   # Download from Xibo website
   wget https://github.com/xibosignage/xibo-pi-os/releases/latest/download/xibo-pi-os.img.xz
   ```

2. **Flash to SD Card:**
   ```bash
   # Extract and flash (replace /dev/sdX with your SD card)
   xzcat xibo-pi-os.img.xz | sudo dd of=/dev/sdX bs=4M status=progress
   ```

3. **Configure Network:**
   - Insert SD card into Pi
   - Boot and connect via SSH or directly
   - Default credentials: `pi/xibo`

4. **Configure Xibo Player:**
   ```bash
   sudo xibo-config
   ```

### Method 2: Manual Installation on Raspberry Pi OS

1. **Install Raspberry Pi OS:**
   - Download from [raspberrypi.org](https://www.raspberrypi.org/downloads/)
   - Flash to SD card using Raspberry Pi Imager

2. **Update System:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Install Dependencies:**
   ```bash
   sudo apt install -y curl wget unzip
   ```

4. **Download Xibo Player:**
   ```bash
   # Create player directory
   sudo mkdir -p /opt/xibo-player
   cd /opt/xibo-player
   
   # Download latest player
   wget https://github.com/xibosignage/xibo-player/releases/latest/download/xibo-player-linux-arm64.zip
   unzip xibo-player-linux-arm64.zip
   ```

5. **Install as Service:**
   ```bash
   # Create systemd service
   sudo nano /etc/systemd/system/xibo-player.service
   ```

   Add this content:
   ```ini
   [Unit]
   Description=Xibo Player
   After=network.target

   [Service]
   Type=simple
   User=pi
   WorkingDirectory=/opt/xibo-player
   ExecStart=/opt/xibo-player/xibo-player
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   ```

6. **Enable and Start:**
   ```bash
   sudo systemctl enable xibo-player
   sudo systemctl start xibo-player
   ```

### Method 3: Using Xibo Pi OS Builder

1. **Clone the builder:**
   ```bash
   git clone https://github.com/xibosignage/xibo-pi-os.git
   cd xibo-pi-os
   ```

2. **Build custom image:**
   ```bash
   # Install dependencies
   sudo apt install -y qemu-user-static debootstrap
   
   # Build image
   sudo ./build.sh
   ```

## Thin Client Installation

### Windows Thin Clients

1. **Download Windows Player:**
   ```powershell
   # Download from Xibo website
   Invoke-WebRequest -Uri "https://github.com/xibosignage/xibo-player/releases/latest/download/xibo-player-windows-x64.zip" -OutFile "xibo-player.zip"
   ```

2. **Extract and Install:**
   ```powershell
   Expand-Archive -Path "xibo-player.zip" -DestinationPath "C:\xibo-player"
   ```

3. **Create Windows Service:**
   ```powershell
   # Run as Administrator
   sc create "XiboPlayer" binPath="C:\xibo-player\xibo-player.exe" start=auto
   sc start "XiboPlayer"
   ```

4. **Configure Auto-Login:**
   - Use Group Policy or registry to enable auto-login
   - Set Xibo player to start automatically

### Linux Thin Clients

1. **Install Dependencies:**
   ```bash
   sudo apt update
   sudo apt install -y curl wget unzip
   ```

2. **Download and Install:**
   ```bash
   # Create directory
   sudo mkdir -p /opt/xibo-player
   cd /opt/xibo-player
   
   # Download appropriate version
   wget https://github.com/xibosignage/xibo-player/releases/latest/download/xibo-player-linux-x64.zip
   unzip xibo-player-linux-x64.zip
   ```

3. **Create Service:**
   ```bash
   sudo nano /etc/systemd/system/xibo-player.service
   ```

   Add the same service content as Raspberry Pi method.

4. **Enable Service:**
   ```bash
   sudo systemctl enable xibo-player
   sudo systemctl start xibo-player
   ```

## Player Configuration

### Initial Setup

1. **Access Player Interface:**
   - Open browser to `http://player-ip:9696`
   - Or use the player's built-in interface

2. **Configure CMS Connection:**
   - **CMS Address**: `https://your-cms-domain.com` or `http://your-cms-ip`
   - **Display Name**: Give your display a descriptive name
   - **Display Key**: Leave blank for automatic generation

3. **Network Settings:**
   - Ensure player can reach CMS on port 80/443
   - Ensure CMS can reach player on port 9505 (XMR)

### Advanced Configuration

1. **Display Settings:**
   ```json
   {
     "displayName": "Reception Display",
     "displayProfile": "Default",
     "screenShotRequestInterval": 300,
     "collectInterval": 300,
     "downloadWindowStart": "00:00",
     "downloadWindowEnd": "23:59"
   }
   ```

2. **Network Configuration:**
   ```json
   {
     "xmrNetworkAddress": "your-cms-domain.com",
     "xmrPubPort": 9505,
     "xmrSubPort": 9505
   }
   ```

## Troubleshooting

### Common Issues

1. **Player Won't Connect to CMS:**
   ```bash
   # Test connectivity
   ping your-cms-domain.com
   telnet your-cms-domain.com 80
   ```

2. **XMR Connection Issues:**
   ```bash
   # Check XMR port
   telnet your-cms-domain.com 9505
   ```

3. **Display Not Showing Content:**
   - Check if display is approved in CMS
   - Verify display profile is assigned
   - Check schedule is active

4. **Performance Issues:**
   - Ensure adequate RAM (4GB+ recommended)
   - Check storage space
   - Monitor CPU usage

### Logs and Debugging

1. **View Player Logs:**
   ```bash
   # Linux
   journalctl -u xibo-player -f
   
   # Windows
   Get-EventLog -LogName Application -Source "XiboPlayer"
   ```

2. **Player Web Interface:**
   - Access `http://player-ip:9696` for diagnostics
   - Check connection status and logs

## Security Considerations

### Network Security
- Use VPN for remote displays
- Implement firewall rules
- Use HTTPS for CMS communication

### Device Security
- Disable unnecessary services
- Enable automatic updates
- Use strong passwords
- Consider device encryption

### CMS Security
- Use strong display keys
- Regularly rotate credentials
- Monitor display connections
- Implement access controls

## Performance Optimization

### Raspberry Pi Optimization
```bash
# Increase GPU memory split
sudo nano /boot/config.txt
# Add: gpu_mem=128

# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable wifi-powersave

# Optimize for display use
sudo raspi-config
# Advanced Options > Memory Split > 128
```

### General Optimization
- Use SSD storage when possible
- Ensure adequate cooling
- Monitor temperature
- Use wired network connection

## Maintenance

### Regular Tasks
- Monitor player status
- Check for updates
- Review logs
- Test connectivity

### Updates
```bash
# Linux
sudo systemctl stop xibo-player
# Download new version
sudo systemctl start xibo-player

# Windows
# Stop service, replace files, restart service
```

## Support Resources

- **Xibo Community Forum**: https://community.xibo.org.uk/
- **Player Documentation**: https://xibo.org.uk/docs/player/
- **GitHub Repository**: https://github.com/xibosignage/xibo-player
- **Raspberry Pi OS**: https://github.com/xibosignage/xibo-pi-os

## Quick Start Checklist

- [ ] Choose installation method
- [ ] Download appropriate player version
- [ ] Install on target device
- [ ] Configure network settings
- [ ] Connect to CMS
- [ ] Approve display in CMS
- [ ] Assign display profile
- [ ] Create and assign schedule
- [ ] Test content playback
- [ ] Set up monitoring
