# 🚀 Xibo Production Deployment - Ready to Go!

## ✅ What's Been Done

### 1. Improvements Committed ✓
- ✅ Fixed Windows Docker volume mount paths in `start-xibo.bat`
- ✅ All changes pushed to: https://github.com/nlangidrik/xibo-docker

### 2. Production Tools Created ✓
- ✅ **nginx-xibo-config.conf** - Complete Nginx configuration with SSL
- ✅ **deploy-to-nginx.sh** - Automated deployment script
- ✅ **PRODUCTION-CHECKLIST.md** - Comprehensive deployment checklist
- ✅ **NGINX-DEPLOYMENT-QUICKSTART.md** - Quick start guide

---

## 🎯 Deploy to Your Production Server

### Option 1: Automated (Easiest - 2 Commands!)

```bash
# On your production server:

# 1. Clone the repository
git clone https://github.com/nlangidrik/xibo-docker
cd xibo-docker

# 2. Create config.env with production settings
cp config.env.template config.env
nano config.env
# Set: MYSQL_PASSWORD, CMS_SERVER_NAME, CMS_SMTP_* credentials

# 3. Start Xibo
chmod +x start-xibo.sh
./start-xibo.sh

# 4. Deploy Nginx with SSL (automated!)
chmod +x deploy-to-nginx.sh
sudo ./deploy-to-nginx.sh your-domain.com your-email@example.com
```

**That's it!** Your Xibo will be live at https://your-domain.com with full SSL! 🎉

### Option 2: Manual (More Control)

Follow the detailed guide in `NGINX-DEPLOYMENT-QUICKSTART.md`

---

## 📋 Your Nginx Configuration Includes

### Security Features ✓
- ✅ SSL/TLS 1.2 & 1.3 with strong ciphers
- ✅ HTTP Strict Transport Security (HSTS)
- ✅ Security headers (XSS, Clickjacking, MIME-sniffing protection)
- ✅ HTTP to HTTPS redirect
- ✅ Hidden file protection
- ✅ Rate limiting (optional, configurable)

### Performance Features ✓
- ✅ Static file caching (images, CSS, JS)
- ✅ Media file optimization
- ✅ Compression settings
- ✅ Buffer optimization
- ✅ Connection pooling

### Xibo-Specific Features ✓
- ✅ XMR WebSocket proxy (port 9505)
- ✅ Large file upload support (2GB default, configurable)
- ✅ Long timeout for uploads
- ✅ Proper header forwarding

---

## 📝 Nginx Configuration Code

Here's the complete configuration in **nginx-xibo-config.conf**:

### Key Sections:

**1. SSL Configuration**
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_certificate /etc/letsencrypt/live/YOUR-DOMAIN.COM/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/YOUR-DOMAIN.COM/privkey.pem;
```

**2. Security Headers**
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
```

**3. Xibo CMS Proxy**
```nginx
location / {
    proxy_pass http://127.0.0.1:80;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # WebSocket support
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

**4. XMR WebSocket Proxy (Critical for Displays)**
```nginx
location /xmr {
    proxy_pass http://127.0.0.1:9505;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    
    # Long timeouts for persistent connections
    proxy_read_timeout 86400s;
    proxy_send_timeout 86400s;
}
```

**5. File Upload Optimization**
```nginx
client_max_body_size 2G;
client_body_timeout 300s;
```

**6. Static File Caching**
```nginx
location ~* \.(jpg|jpeg|png|gif|ico|svg|webp)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

location ~* \.(css|js)$ {
    expires 7d;
    add_header Cache-Control "public";
}
```

---

## 🔐 Critical Security Steps

### Before Deploying to Production:

1. **Generate Strong MySQL Password**
   ```bash
   # Use this to generate a secure password:
   openssl rand -base64 16 | tr -d '/+=' | head -c 16
   ```

2. **Update config.env**
   ```bash
   MYSQL_PASSWORD=<your-generated-password>
   CMS_SERVER_NAME=your-domain.com
   CMS_SMTP_USERNAME=your-real-email@gmail.com
   CMS_SMTP_PASSWORD=your-app-password
   ```

3. **Never Commit config.env**
   - Already protected by `.gitignore` ✓
   - Only commit `config.env.template`

---

## 📊 Testing Your Deployment

After deployment, test these:

### 1. SSL Grade Test
Visit: https://www.ssllabs.com/ssltest/analyze.html?d=your-domain.com
**Expected:** Grade A or A+

### 2. Security Headers Test
```bash
curl -I https://your-domain.com
```
Should show: HSTS, X-Frame-Options, CSP headers

### 3. HTTP Redirect Test
```bash
curl -I http://your-domain.com
```
Should return: `301 Moved Permanently`

### 4. WebSocket Test
- Login to Xibo CMS
- Go to **Status** page
- Check XMR status shows "Connected"

### 5. Upload Test
- Upload a large media file
- Verify it completes successfully

---

## 📁 File Structure After Deployment

```
your-server:/opt/xibo-docker/
├── start-xibo.sh              ← Start Xibo
├── stop-xibo.sh               ← Stop Xibo
├── deploy-to-nginx.sh         ← Deploy Nginx (run once)
├── config.env                 ← Your production config
├── docker-compose.yml         ← Docker orchestration
│
├── nginx-xibo-config.conf     ← Nginx config template
├── PRODUCTION-CHECKLIST.md    ← Complete checklist
├── NGINX-DEPLOYMENT-QUICKSTART.md  ← Quick guide
│
└── shared/                    ← Data directory
    ├── db/                    ← MySQL database
    ├── backup/                ← Automated backups
    └── cms/
        ├── library/           ← Media files
        └── web/               ← Web assets
```

---

## 🎯 Quick Deployment Cheat Sheet

```bash
# === INITIAL DEPLOYMENT ===

# 1. Clone repository
git clone https://github.com/nlangidrik/xibo-docker
cd xibo-docker

# 2. Configure
cp config.env.template config.env
nano config.env  # Set MYSQL_PASSWORD, domain, SMTP

# 3. Start Xibo
chmod +x start-xibo.sh
./start-xibo.sh

# 4. Deploy Nginx + SSL (ONE COMMAND!)
chmod +x deploy-to-nginx.sh
sudo ./deploy-to-nginx.sh your-domain.com admin@example.com

# 5. Access
https://your-domain.com

# === DAILY OPERATIONS ===

# Start Xibo
./start-xibo.sh

# Stop Xibo
./stop-xibo.sh

# View logs
docker logs -f xibo-docker-cms-web-1

# Check status
docker ps

# Reload Nginx (after config changes)
sudo systemctl reload nginx

# === MAINTENANCE ===

# Update Xibo
docker compose pull
docker compose up -d

# Renew SSL (automatic, or manual)
sudo certbot renew

# Backup database
docker exec xibo-docker-cms-db-1 mysqldump -u cms -p cms > backup.sql

# Check disk space
df -h
du -sh ./shared/*
```

---

## 🆘 Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| **502 Bad Gateway** | `docker ps` then `./start-xibo.sh` |
| **SSL Error** | Check DNS: `dig +short your-domain.com` |
| **Upload Fails** | Increase `client_max_body_size` in Nginx |
| **XMR Not Connected** | Check `docker logs xibo-xmr-manual` |
| **Nginx Won't Start** | `sudo nginx -t` to test config |
| **Can't Login** | Check `docker logs xibo-docker-cms-web-1` |

---

## 📚 Documentation Reference

- **Production Checklist:** `PRODUCTION-CHECKLIST.md` (comprehensive)
- **Nginx Quick Start:** `NGINX-DEPLOYMENT-QUICKSTART.md` (fast setup)
- **Full Guide:** `PRODUCTION-DEPLOYMENT.md` (detailed)
- **Debian Specific:** `DEBIAN-DEPLOYMENT.md` (Debian VMs)

---

## ✅ Repository Status

- **Repository:** https://github.com/nlangidrik/xibo-docker
- **Branch:** master
- **Status:** ✅ All changes committed and pushed
- **Ready for:** Production deployment

---

## 🎉 Next Steps

1. **Clone to Production Server**
   ```bash
   git clone https://github.com/nlangidrik/xibo-docker
   ```

2. **Follow Automated Deployment**
   - Use `deploy-to-nginx.sh` for easiest setup
   - Or follow `NGINX-DEPLOYMENT-QUICKSTART.md` for manual

3. **Complete Setup**
   - Use `PRODUCTION-CHECKLIST.md` to ensure nothing is missed

4. **Go Live!**
   - Access your Xibo at https://your-domain.com
   - Complete Xibo setup wizard
   - Add displays and start signage! 🎬

---

## 💡 Pro Tips

1. **Before DNS Update:** Test with IP first: `http://your-server-ip`
2. **After DNS Update:** Wait 5-10 min, then run SSL deployment
3. **Test Locally First:** Deploy to a test server before production
4. **Backups:** Automated daily backups go to `./shared/backup/`
5. **Monitoring:** Set up alerts for container health and disk space
6. **Updates:** Pull latest Xibo images monthly: `docker compose pull`

---

**🎬 Your Xibo CMS is production-ready!**

Everything you need is committed to your repository and ready to deploy. Just clone, configure, and run the deployment script!

Good luck with your digital signage deployment! 🚀

