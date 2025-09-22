#!/bin/bash

# Nginx Setup Script for Xibo
# This script helps you set up Nginx as a reverse proxy for Xibo

set -e

echo "🔧 Setting up Nginx reverse proxy for Xibo..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script as root (use sudo)"
    exit 1
fi

# Get domain name from user
read -p "Enter your domain name (e.g., cms.yourdomain.com): " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Domain name is required"
    exit 1
fi

echo "📦 Installing Nginx and Certbot..."

# Install Nginx and Certbot
if command -v apt &> /dev/null; then
    # Debian/Ubuntu
    apt update
    apt install -y nginx certbot python3-certbot-nginx
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    yum install -y nginx certbot python3-certbot-nginx
elif command -v dnf &> /dev/null; then
    # Fedora/newer CentOS
    dnf install -y nginx certbot python3-certbot-nginx
else
    echo "❌ Unsupported package manager. Please install Nginx and Certbot manually."
    exit 1
fi

echo "📝 Creating Nginx configuration..."

# Create Nginx configuration
cat > /etc/nginx/sites-available/xibo << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    # SSL Configuration (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
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
    
    # Main Xibo proxy
    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # WebSocket support (for real-time features)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
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
    
    # Handle large file uploads and static content
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|mp4|avi|mov|wmv|flv|webm)\$ {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Cache static files
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # XMR WebSocket proxy (for real-time communication)
    location /xmr {
        proxy_pass http://127.0.0.1:9505;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket specific timeouts
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/xibo /etc/nginx/sites-enabled/

# Remove default site if it exists
rm -f /etc/nginx/sites-enabled/default

echo "🔍 Testing Nginx configuration..."
nginx -t

echo "🔄 Starting Nginx..."
systemctl enable nginx
systemctl start nginx

echo "🔐 Obtaining SSL certificate..."
certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME

echo "⏰ Setting up SSL auto-renewal..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

echo "🔥 Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 'Nginx Full'
    ufw --force enable
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

echo "✅ Nginx setup complete!"
echo ""
echo "🌐 Your Xibo is now accessible at: https://$DOMAIN_NAME"
echo "📊 Make sure to update your config.env file:"
echo "   CMS_SERVER_NAME=$DOMAIN_NAME"
echo ""
echo "🔧 To restart Nginx: sudo systemctl restart nginx"
echo "📋 To check Nginx status: sudo systemctl status nginx"
echo "📝 To view logs: sudo tail -f /var/log/nginx/access.log"
