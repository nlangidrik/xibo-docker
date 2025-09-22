# Xibo Production Deployment Guide

This guide will help you deploy Xibo to your production server with full functionality.

## Prerequisites

### Server Requirements
- **OS**: Linux (Ubuntu 20.04+ recommended) or Windows Server
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Storage**: Minimum 20GB free space
- **CPU**: 2+ cores recommended

### Software Requirements
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

## Quick Deployment

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd xibo-docker
```

### 2. Configure Environment
```bash
# Copy the template
cp config.env.template config.env

# Edit the configuration
nano config.env  # or use your preferred editor
```

**Important settings to configure:**
- `MYSQL_PASSWORD`: Set a strong password (16+ characters, alphanumeric only)
- `CMS_SERVER_NAME`: Set to your domain name (e.g., `cms.yourdomain.com`)
- `CMS_SMTP_*`: Configure email settings for notifications

### 3. Start Xibo

**For Linux:**
```bash
chmod +x start-xibo.sh
./start-xibo.sh
```

**For Windows:**
```cmd
start-xibo.bat
```

### 4. Access and Setup
1. Open your browser to `http://your-server-ip` or your domain
2. Complete the Xibo setup wizard
3. Create your admin account

## Nginx Reverse Proxy Setup

For production environments, it's recommended to use Nginx as a reverse proxy in front of Xibo. This provides better security, SSL termination, and performance.

### Install Nginx

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y nginx
```

**On CentOS/RHEL:**
```bash
sudo yum install -y nginx
# or for newer versions:
sudo dnf install -y nginx
```

### Configure Nginx for Xibo

1. **Create Xibo configuration:**
```bash
sudo nano /etc/nginx/sites-available/xibo
```

2. **Add the following configuration:**
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    # SSL Configuration (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Client max body size (for file uploads)
    client_max_body_size 2G;
    
    # Proxy settings
    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # WebSocket support (for real-time features)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }
    
    # Handle large file uploads
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|mp4|avi|mov|wmv|flv|webm)$ {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Cache static files
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # XMR WebSocket proxy (for real-time communication)
    location /xmr {
        proxy_pass http://127.0.0.1:9505;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket specific timeouts
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}
```

3. **Enable the site:**
```bash
sudo ln -s /etc/nginx/sites-available/xibo /etc/nginx/sites-enabled/
sudo nginx -t  # Test configuration
sudo systemctl reload nginx
```

### SSL Certificate with Let's Encrypt

1. **Install Certbot:**
```bash
# Ubuntu/Debian
sudo apt install -y certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install -y certbot python3-certbot-nginx
```

2. **Obtain SSL certificate:**
```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

3. **Auto-renewal:**
```bash
sudo crontab -e
# Add this line:
0 12 * * * /usr/bin/certbot renew --quiet
```

### Update Xibo Configuration

Update your `config.env` file to work with the proxy:

```bash
# Set your domain name
CMS_SERVER_NAME=your-domain.com

# Optional: Set trusted proxies (if using multiple proxy layers)
# CMS_TRUSTED_PROXIES=127.0.0.1,::1
```

### Nginx Optimization

Add these optimizations to your main nginx.conf:

```nginx
# In /etc/nginx/nginx.conf
http {
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    
    # Connection limits
    limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
}
```

Add rate limiting to your Xibo configuration:

```nginx
# In your Xibo site configuration
location /login {
    limit_req zone=login burst=3 nodelay;
    proxy_pass http://127.0.0.1:80;
    # ... other proxy settings
}

location /api {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://127.0.0.1:80;
    # ... other proxy settings
}
```

### Monitoring Nginx

1. **Check Nginx status:**
```bash
sudo systemctl status nginx
sudo nginx -t
```

2. **View access logs:**
```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

3. **Monitor performance:**
```bash
# Install nginx monitoring tools
sudo apt install -y nginx-module-njs  # For advanced monitoring
```

### Firewall Configuration

Update your firewall to only allow Nginx ports:

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'  # Remove if you only want HTTPS

# Or manually:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Troubleshooting Nginx + Xibo

**Common Issues:**

1. **502 Bad Gateway:**
   - Check if Xibo is running: `docker ps | grep xibo`
   - Verify Xibo is listening on port 80: `netstat -tlnp | grep :80`

2. **WebSocket connection issues:**
   - Ensure XMR proxy configuration is correct
   - Check XMR container logs: `docker logs xibo-xmr-manual`

3. **SSL certificate issues:**
   - Verify certificate is valid: `sudo certbot certificates`
   - Check certificate renewal: `sudo certbot renew --dry-run`

4. **File upload issues:**
   - Increase `client_max_body_size` in Nginx config
   - Check Xibo PHP upload limits in `config.env`

### Performance Tuning

For high-traffic Xibo installations:

```nginx
# Add to your Xibo server block
location / {
    # ... existing proxy settings ...
    
    # Connection pooling
    proxy_set_header Connection "";
    proxy_http_version 1.1;
    
    # Caching for static content
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        proxy_pass http://127.0.0.1:80;
        # ... proxy headers ...
    }
}
```

## Production Considerations

### Security
- **Firewall**: Only open ports 80 (HTTP) and 443 (HTTPS if using SSL)
- **SSL Certificate**: Use Let's Encrypt or your preferred SSL provider
- **Database Security**: The MySQL password is stored in `config.env` - keep this file secure

### Performance
- **Memory**: Increase Docker memory limits if needed
- **Storage**: Monitor disk usage in the `./shared/` directory
- **Backups**: Regular backups are stored in `./shared/backup/`

### Monitoring
- Check container status: `docker ps`
- View logs: `docker compose logs`
- Monitor disk usage: `du -sh ./shared/`

## Troubleshooting

### Common Issues

**XMR Container Won't Start:**
- This is handled automatically by the startup scripts
- If issues persist, check Docker API compatibility

**Database Connection Issues:**
- Ensure `MYSQL_PASSWORD` is set correctly
- Check if database container is running: `docker ps | grep db`

**Web Interface Not Accessible:**
- Verify port 80 is open in firewall
- Check if CMS container is running: `docker ps | grep web`

### Logs and Debugging
```bash
# View all logs
docker compose logs

# View specific service logs
docker compose logs cms-web
docker compose logs cms-db

# View XMR logs
docker logs xibo-xmr-manual
```

## Maintenance

### Stopping Xibo
```bash
# Linux
./stop-xibo.sh

# Windows
stop-xibo.bat
```

### Updating Xibo
1. Stop the services
2. Pull latest images: `docker compose pull`
3. Start services again

### Backups
- Database backups are automatically created in `./shared/backup/`
- Library files are stored in `./shared/cms/library/`
- Custom themes in `./shared/cms/web/theme/custom/`

## Support

- **Xibo Community Forum**: https://community.xibo.org.uk/
- **Documentation**: http://xibo.org.uk/manual-tempel/en/
- **GitHub Issues**: Report bugs in the main Xibo repository

## File Structure
```
xibo-docker/
├── start-xibo.sh          # Linux startup script
├── start-xibo.bat         # Windows startup script
├── stop-xibo.sh           # Linux stop script
├── stop-xibo.bat          # Windows stop script
├── docker-compose.yml     # Docker Compose configuration
├── config.env.template    # Environment template
├── config.env             # Your configuration (create this)
└── shared/                # Data directory
    ├── db/                # Database files
    ├── backup/            # Database backups
    └── cms/               # CMS files
        ├── library/       # Media library
        └── web/           # Web files
```
