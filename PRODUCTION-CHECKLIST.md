# Xibo Production Deployment Checklist

Use this checklist to ensure a smooth and secure production deployment of Xibo.

## Pre-Deployment Phase

### Server Preparation
- [ ] Production server is provisioned (4GB+ RAM, 20GB+ storage)
- [ ] Operating system is up to date (`sudo apt update && sudo apt upgrade -y`)
- [ ] Docker and Docker Compose are installed
- [ ] Git is installed
- [ ] Firewall is configured (UFW/iptables)
- [ ] Static IP address or domain name is configured
- [ ] DNS records are pointing to your server (if using a domain)

### Security Setup
- [ ] SSH key authentication is enabled
- [ ] Root login via SSH is disabled
- [ ] Non-root user with sudo privileges is created
- [ ] Fail2ban is installed and configured (optional but recommended)
- [ ] System timezone is set correctly (`sudo timedatectl set-timezone Your/Timezone`)

## Deployment Phase

### Repository Setup
- [ ] Repository is cloned to production server
  ```bash
  git clone https://github.com/nlangidrik/xibo-docker
  cd xibo-docker
  ```

### Configuration
- [ ] `config.env` file is created from template
  ```bash
  cp config.env.template config.env
  ```
- [ ] **CRITICAL:** Strong MYSQL_PASSWORD is set (16+ alphanumeric characters)
  ```bash
  # Generate secure password:
  openssl rand -base64 16 | tr -d '/+=' | head -c 16
  ```
- [ ] CMS_SERVER_NAME is set to production domain/IP
- [ ] SMTP credentials are configured with real email account
  - [ ] CMS_SMTP_SERVER is set
  - [ ] CMS_SMTP_USERNAME is set
  - [ ] CMS_SMTP_PASSWORD is set (use app-specific password for Gmail)
  - [ ] Test email sending after deployment
- [ ] File upload limits are adjusted if needed (CMS_PHP_UPLOAD_MAX_FILESIZE)
- [ ] config.env file permissions are secured (`chmod 600 config.env`)

### Firewall Configuration
- [ ] SSH port is allowed (default: 22)
  ```bash
  sudo ufw allow 22/tcp
  ```
- [ ] HTTP port is allowed (80)
  ```bash
  sudo ufw allow 80/tcp
  ```
- [ ] HTTPS port is allowed (443)
  ```bash
  sudo ufw allow 443/tcp
  ```
- [ ] Firewall is enabled
  ```bash
  sudo ufw enable
  ```
- [ ] Firewall status is verified
  ```bash
  sudo ufw status
  ```

### Xibo Deployment
- [ ] Scripts are made executable
  ```bash
  chmod +x start-xibo.sh stop-xibo.sh setup-nginx.sh
  ```
- [ ] Xibo is started successfully
  ```bash
  ./start-xibo.sh
  ```
- [ ] All containers are running
  ```bash
  docker ps
  ```
  Expected containers:
  - xibo-docker-cms-web-1
  - xibo-xmr-manual
  - xibo-docker-cms-db-1
  - xibo-docker-cms-memcached-1
  - xibo-docker-cms-quickchart-1

### Initial Xibo Setup
- [ ] Web interface is accessible (http://your-server-ip)
- [ ] Xibo setup wizard is completed
- [ ] Admin account is created with strong password
- [ ] Admin email is verified
- [ ] License key is entered (if applicable)
- [ ] Initial display group and layout are created
- [ ] XMR connectivity is working (check Status page in CMS)

## SSL/HTTPS Setup (Recommended)

### Nginx Installation
- [ ] Nginx is installed
  ```bash
  sudo apt install -y nginx
  ```
- [ ] Nginx is running
  ```bash
  sudo systemctl status nginx
  ```

### SSL Certificate
- [ ] Certbot is installed
  ```bash
  sudo apt install -y certbot python3-certbot-nginx
  ```
- [ ] Nginx configuration for Xibo is created (see nginx-xibo-config.conf)
- [ ] SSL certificate is obtained
  ```bash
  sudo certbot --nginx -d your-domain.com -d www.your-domain.com
  ```
- [ ] SSL certificate auto-renewal is configured
  ```bash
  sudo certbot renew --dry-run
  ```
- [ ] Auto-renewal cron job is set up
  ```bash
  # Add to crontab: sudo crontab -e
  0 12 * * * /usr/bin/certbot renew --quiet
  ```

### Nginx Configuration
- [ ] Nginx configuration is tested
  ```bash
  sudo nginx -t
  ```
- [ ] Nginx is reloaded
  ```bash
  sudo systemctl reload nginx
  ```
- [ ] HTTPS is accessible (https://your-domain.com)
- [ ] HTTP redirects to HTTPS
- [ ] XMR WebSocket connections are working through proxy

## Post-Deployment Phase

### Testing
- [ ] Can access CMS via HTTPS
- [ ] Can login with admin account
- [ ] Media library upload works
- [ ] Layouts can be created and previewed
- [ ] Display registration works
- [ ] XMR real-time messaging works (test with display)
- [ ] Email notifications are being sent
- [ ] Scheduled tasks are running (check Status > Logs)
- [ ] Database backups are being created in `./shared/backup/`

### Monitoring Setup
- [ ] Set up container health monitoring
  ```bash
  # Add to crontab
  */5 * * * * docker ps | grep -q xibo-docker-cms-web-1 || /path/to/xibo-docker/start-xibo.sh
  ```
- [ ] Set up disk space monitoring
  ```bash
  df -h
  ```
- [ ] Set up log rotation for Docker logs
- [ ] Configure alerts for critical issues (optional: use Prometheus/Grafana)

### Backup Strategy
- [ ] Automated database backups are enabled (Xibo does this by default)
- [ ] External backup location is configured
- [ ] Test database restore procedure
  ```bash
  # Test restore:
  docker exec -i xibo-docker-cms-db-1 mysql -u cms -p"$MYSQL_PASSWORD" cms < backup.sql
  ```
- [ ] Backup script is created for full system backup
- [ ] Backup schedule is configured via cron
- [ ] Backup retention policy is defined (e.g., keep 30 days)

### Auto-Start Configuration
- [ ] Systemd service is created for auto-start on boot
  ```bash
  sudo nano /etc/systemd/system/xibo.service
  ```
- [ ] Service is enabled
  ```bash
  sudo systemctl enable xibo.service
  ```
- [ ] Service is tested
  ```bash
  sudo systemctl start xibo.service
  sudo systemctl status xibo.service
  ```
- [ ] Server reboot test is performed

### Documentation
- [ ] Admin credentials are documented securely (password manager)
- [ ] Database password is documented securely
- [ ] SMTP credentials are documented
- [ ] Server access details are documented
- [ ] Backup locations are documented
- [ ] Recovery procedures are documented

## Maintenance Phase

### Regular Tasks
- [ ] Weekly: Check disk space usage
  ```bash
  du -sh ./shared/*
  df -h
  ```
- [ ] Weekly: Review application logs
  ```bash
  docker compose logs --tail 100
  ```
- [ ] Monthly: Update system packages
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```
- [ ] Monthly: Update Docker images
  ```bash
  docker compose pull
  docker compose up -d
  ```
- [ ] Monthly: Clean up old Docker images
  ```bash
  docker system prune -a
  ```
- [ ] Quarterly: Test backup restoration
- [ ] Quarterly: Review security settings

### Performance Optimization
- [ ] Memcached is working (check container logs)
- [ ] Database is optimized (Xibo does this automatically)
- [ ] Old media files are cleaned up regularly
- [ ] Display schedules are optimized
- [ ] Nginx caching is configured for static assets

## Troubleshooting Reference

### Quick Diagnostics
```bash
# Check all containers
docker ps

# Check specific container logs
docker logs xibo-docker-cms-web-1
docker logs xibo-xmr-manual
docker logs xibo-docker-cms-db-1

# Check container resources
docker stats

# Check system resources
htop
df -h
free -h

# Test database connection
docker exec -it xibo-docker-cms-db-1 mysql -u cms -p

# Check Nginx status
sudo systemctl status nginx
sudo nginx -t

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Common Issues
- **Container won't start:** Check logs with `docker logs <container-name>`
- **502 Bad Gateway:** Verify Xibo containers are running
- **Database connection error:** Check MYSQL_PASSWORD in config.env
- **File upload fails:** Increase CMS_PHP_UPLOAD_MAX_FILESIZE
- **XMR not connecting:** Check port 9505 and XMR container logs
- **Email not sending:** Verify SMTP credentials and test with telnet

## Security Hardening (Optional but Recommended)

- [ ] Enable fail2ban for SSH protection
- [ ] Configure automatic security updates
  ```bash
  sudo apt install unattended-upgrades
  sudo dpkg-reconfigure --priority=low unattended-upgrades
  ```
- [ ] Set up intrusion detection (AIDE, Tripwire)
- [ ] Configure log monitoring (logwatch, rsyslog)
- [ ] Enable SELinux/AppArmor
- [ ] Regular security audits
  ```bash
  sudo lynis audit system
  ```
- [ ] Keep Docker updated
- [ ] Review and limit container permissions

## Compliance Checks (If Applicable)

- [ ] GDPR compliance reviewed
- [ ] Data retention policies implemented
- [ ] Privacy policy updated
- [ ] User consent mechanisms in place
- [ ] Data encryption at rest (if required)
- [ ] Regular security assessments scheduled

## Sign-Off

**Deployed by:** _________________
**Date:** _________________
**Server:** _________________
**Domain:** _________________
**Version:** Xibo CMS 4.3.0

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

---

## Quick Reference Commands

```bash
# Start Xibo
./start-xibo.sh

# Stop Xibo
./stop-xibo.sh

# View logs
docker compose logs -f

# Check status
docker ps

# Backup database manually
docker exec xibo-docker-cms-db-1 mysqldump -u cms -p"$MYSQL_PASSWORD" cms > backup-$(date +%Y%m%d).sql

# Restart specific container
docker restart xibo-docker-cms-web-1

# Update Xibo
docker compose pull
docker compose up -d
```

**Emergency Contact:** _________________
**Support Email:** _________________

