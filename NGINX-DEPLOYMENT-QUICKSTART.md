# Nginx Deployment Quick Start Guide

This guide will help you deploy Xibo with Nginx reverse proxy and SSL in minutes.

## 🚀 Automated Deployment (Recommended)

The easiest way to deploy Nginx with SSL for Xibo:

```bash
# On your production server (after Xibo is running):

# 1. Make the script executable
chmod +x deploy-to-nginx.sh

# 2. Run the deployment script
sudo ./deploy-to-nginx.sh your-domain.com your-email@example.com

# Example:
sudo ./deploy-to-nginx.sh cms.example.com admin@example.com
```

That's it! The script will:
- ✅ Install Nginx and Certbot (if needed)
- ✅ Configure Nginx for Xibo
- ✅ Enable SSL with Let's Encrypt
- ✅ Set up automatic certificate renewal
- ✅ Configure firewall
- ✅ Test everything

Access your Xibo at: **https://your-domain.com**

---

## 📝 Manual Deployment

If you prefer manual setup or already have Nginx installed:

### Step 1: Install Prerequisites

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

### Step 2: Deploy Nginx Configuration

```bash
# Copy the configuration file
sudo cp nginx-xibo-config.conf /etc/nginx/sites-available/xibo

# Edit and replace YOUR-DOMAIN.COM with your actual domain
sudo nano /etc/nginx/sites-available/xibo

# Find and replace all instances:
# YOUR-DOMAIN.COM → your-actual-domain.com
# (Use Ctrl+\ in nano for search and replace)
```

### Step 3: Enable the Site

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/xibo /etc/nginx/sites-enabled/

# Disable default site (optional)
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Step 4: Obtain SSL Certificate

```bash
# Get Let's Encrypt certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Follow the prompts and agree to terms
```

### Step 5: Configure Auto-Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Add to crontab
sudo crontab -e

# Add this line:
0 12 * * * /usr/bin/certbot renew --quiet
```

### Step 6: Configure Firewall

```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## 🔧 Configuration Customization

### Change Upload Limit

Edit `/etc/nginx/sites-available/xibo`:

```nginx
# Find this line:
client_max_body_size 2G;

# Change to your desired size:
client_max_body_size 5G;
```

Then reload: `sudo systemctl reload nginx`

### Enable Rate Limiting

1. Add to `/etc/nginx/nginx.conf` in the `http` block:

```nginx
http {
    # ... existing config ...
    
    # Rate limiting zones
    limit_req_zone $binary_remote_addr zone=xibo_login:10m rate=5r/m;
    limit_req_zone $binary_remote_addr zone=xibo_api:10m rate=30r/s;
}
```

2. Uncomment the rate limiting sections in `/etc/nginx/sites-available/xibo`

3. Reload: `sudo systemctl reload nginx`

### Custom SSL Certificate

If you have your own SSL certificate instead of Let's Encrypt:

```nginx
# Edit these lines in /etc/nginx/sites-available/xibo:
ssl_certificate /path/to/your/fullchain.pem;
ssl_certificate_key /path/to/your/privkey.pem;
ssl_trusted_certificate /path/to/your/chain.pem;
```

---

## 🧪 Testing Your Deployment

### Test 1: Check Nginx Status

```bash
sudo systemctl status nginx
sudo nginx -t
```

### Test 2: Test SSL Configuration

Visit: https://www.ssllabs.com/ssltest/analyze.html?d=your-domain.com

Expected grade: **A or A+**

### Test 3: Test Security Headers

```bash
curl -I https://your-domain.com
```

Should see headers like:
- `Strict-Transport-Security`
- `X-Frame-Options`
- `X-Content-Type-Options`

### Test 4: Test HTTP to HTTPS Redirect

```bash
curl -I http://your-domain.com
```

Should return: `301 Moved Permanently` with `Location: https://...`

### Test 5: Test XMR WebSocket

1. Login to Xibo CMS
2. Go to **Administration > Settings > Displays**
3. Check "XMR Public Address" shows your domain
4. Open browser console (F12) and look for WebSocket connections

### Test 6: Test File Upload

1. Login to Xibo CMS
2. Go to **Library > Add Media**
3. Upload a large file (test your size limit)

---

## 📊 Monitoring

### View Logs

```bash
# Nginx access logs
sudo tail -f /var/log/nginx/xibo-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/xibo-error.log

# Xibo application logs
docker logs -f xibo-docker-cms-web-1

# XMR logs
docker logs -f xibo-xmr-manual
```

### Check SSL Certificate

```bash
# View certificate details
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run
```

### Monitor Performance

```bash
# Nginx status
sudo systemctl status nginx

# Check connections
sudo netstat -an | grep :443 | wc -l

# Check processes
ps aux | grep nginx
```

---

## 🐛 Troubleshooting

### Issue: 502 Bad Gateway

**Cause:** Xibo containers not running

**Solution:**
```bash
docker ps | grep xibo
# If containers are missing:
./start-xibo.sh
```

### Issue: SSL Certificate Error

**Cause:** DNS not pointing to server or certificate expired

**Solution:**
```bash
# Check DNS
dig +short your-domain.com

# Check certificate
sudo certbot certificates

# Renew if needed
sudo certbot renew --force-renewal
```

### Issue: WebSocket Connection Failed

**Cause:** XMR proxy not configured correctly

**Solution:**
```bash
# Check XMR is running
docker ps | grep xmr

# Check XMR logs
docker logs xibo-xmr-manual

# Test port
curl http://localhost:9505
```

### Issue: File Upload Fails

**Cause:** Upload limit too small

**Solution:**
```bash
# Edit Nginx config
sudo nano /etc/nginx/sites-available/xibo

# Find and increase:
client_max_body_size 5G;

# Also check Xibo config.env:
CMS_PHP_UPLOAD_MAX_FILESIZE=5G

# Restart both
sudo systemctl reload nginx
./stop-xibo.sh
./start-xibo.sh
```

### Issue: Nginx Won't Start

**Cause:** Configuration error or port conflict

**Solution:**
```bash
# Test configuration
sudo nginx -t

# Check what's using port 80/443
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Check Nginx error log
sudo tail -f /var/log/nginx/error.log
```

### Issue: Slow Performance

**Solution:**
```bash
# Enable Nginx caching (already in config)
# Check buffer sizes in /etc/nginx/sites-available/xibo

# Monitor resources
htop
docker stats
```

---

## 🔒 Security Best Practices

### 1. Keep Everything Updated

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Update Xibo
docker compose pull
docker compose up -d

# Update SSL certificates (automatic via cron)
sudo certbot renew
```

### 2. Configure Fail2Ban (Optional)

```bash
# Install
sudo apt install -y fail2ban

# Configure for Nginx
sudo nano /etc/fail2ban/jail.local
```

Add:
```ini
[nginx-http-auth]
enabled = true

[nginx-noscript]
enabled = true

[nginx-badbots]
enabled = true
```

### 3. Enable ModSecurity (Advanced)

```bash
sudo apt install -y libmodsecurity3 modsecurity-crs
# Follow Nginx ModSecurity setup guide
```

### 4. Regular Security Audits

```bash
# Install Lynis
sudo apt install -y lynis

# Run audit
sudo lynis audit system
```

---

## 📚 Additional Resources

### Official Documentation
- Xibo: https://xibo.org.uk/docs
- Nginx: https://nginx.org/en/docs/
- Let's Encrypt: https://letsencrypt.org/docs/

### SSL Testing
- SSL Labs: https://www.ssllabs.com/ssltest/
- Security Headers: https://securityheaders.com/

### Community Support
- Xibo Community: https://community.xibo.org.uk/
- Xibo GitHub: https://github.com/xibosignage/xibo

---

## 📞 Quick Command Reference

```bash
# Nginx Management
sudo systemctl status nginx      # Check status
sudo systemctl start nginx       # Start
sudo systemctl stop nginx        # Stop
sudo systemctl reload nginx      # Reload config
sudo systemctl restart nginx     # Restart
sudo nginx -t                    # Test config

# SSL Certificate Management
sudo certbot certificates        # List certificates
sudo certbot renew              # Renew certificates
sudo certbot renew --dry-run    # Test renewal
sudo certbot delete             # Delete certificate

# Xibo Management
./start-xibo.sh                 # Start Xibo
./stop-xibo.sh                  # Stop Xibo
docker ps                       # Check containers
docker logs <container>         # View logs

# Firewall Management
sudo ufw status                 # Check firewall
sudo ufw allow 443/tcp          # Allow HTTPS
sudo ufw enable                 # Enable firewall

# Log Viewing
sudo tail -f /var/log/nginx/xibo-access.log
sudo tail -f /var/log/nginx/xibo-error.log
docker logs -f xibo-docker-cms-web-1
```

---

## ✅ Post-Deployment Checklist

- [ ] Nginx is running: `sudo systemctl status nginx`
- [ ] SSL certificate is valid: `sudo certbot certificates`
- [ ] HTTP redirects to HTTPS
- [ ] Xibo is accessible at https://your-domain.com
- [ ] Can login to Xibo CMS
- [ ] XMR WebSocket is connected (check Status page)
- [ ] File upload works
- [ ] Email notifications work
- [ ] Firewall is configured
- [ ] Auto-renewal is set up
- [ ] Security headers are present
- [ ] SSL Labs grade is A or A+
- [ ] Backups are configured
- [ ] Monitoring is set up

---

**Need Help?**

Check `PRODUCTION-CHECKLIST.md` for complete deployment checklist.

Check `PRODUCTION-DEPLOYMENT.md` for detailed production guide.

