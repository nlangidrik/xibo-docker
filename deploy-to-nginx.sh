#!/bin/bash
#
# Xibo Nginx Deployment Script
# This script automates the deployment of Nginx configuration for Xibo
#
# Usage: sudo ./deploy-to-nginx.sh your-domain.com your-email@example.com
#

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run as root or with sudo${NC}"
    exit 1
fi

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${YELLOW}Usage: $0 <domain> <email>${NC}"
    echo "Example: $0 xibo.example.com admin@example.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2
WWW_DOMAIN="www.$DOMAIN"

echo -e "${GREEN}🚀 Xibo Nginx Deployment Script${NC}"
echo "=================================="
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Check if Nginx is installed
echo -e "${YELLOW}[1/10] Checking Nginx installation...${NC}"
if ! command_exists nginx; then
    echo "Nginx not found. Installing..."
    apt update
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo -e "${GREEN}✅ Nginx installed${NC}"
else
    echo -e "${GREEN}✅ Nginx already installed${NC}"
fi

# Step 2: Check if Certbot is installed
echo -e "${YELLOW}[2/10] Checking Certbot installation...${NC}"
if ! command_exists certbot; then
    echo "Certbot not found. Installing..."
    apt install -y certbot python3-certbot-nginx
    echo -e "${GREEN}✅ Certbot installed${NC}"
else
    echo -e "${GREEN}✅ Certbot already installed${NC}"
fi

# Step 3: Check if Xibo is running
echo -e "${YELLOW}[3/10] Checking if Xibo containers are running...${NC}"
if ! docker ps | grep -q xibo-docker-cms-web-1; then
    echo -e "${RED}❌ Xibo containers are not running!${NC}"
    echo "Please start Xibo first: ./start-xibo.sh"
    exit 1
fi
echo -e "${GREEN}✅ Xibo is running${NC}"

# Step 4: Backup existing Nginx configuration
echo -e "${YELLOW}[4/10] Backing up existing Nginx configuration...${NC}"
if [ -f /etc/nginx/sites-available/xibo ]; then
    cp /etc/nginx/sites-available/xibo /etc/nginx/sites-available/xibo.backup.$(date +%Y%m%d-%H%M%S)
    echo -e "${GREEN}✅ Backup created${NC}"
else
    echo "No existing configuration found"
fi

# Step 5: Create Nginx configuration
echo -e "${YELLOW}[5/10] Creating Nginx configuration...${NC}"
cp nginx-xibo-config.conf /etc/nginx/sites-available/xibo

# Replace domain placeholders
sed -i "s/YOUR-DOMAIN.COM/$DOMAIN/g" /etc/nginx/sites-available/xibo
sed -i "s/YOUR-EMAIL@EXAMPLE.COM/$EMAIL/g" /etc/nginx/sites-available/xibo

echo -e "${GREEN}✅ Configuration created${NC}"

# Step 6: Enable the site
echo -e "${YELLOW}[6/10] Enabling Xibo site...${NC}"
ln -sf /etc/nginx/sites-available/xibo /etc/nginx/sites-enabled/xibo

# Disable default site if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "Disabling default Nginx site..."
    rm /etc/nginx/sites-enabled/default
fi

echo -e "${GREEN}✅ Site enabled${NC}"

# Step 7: Test Nginx configuration
echo -e "${YELLOW}[7/10] Testing Nginx configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✅ Configuration is valid${NC}"
else
    echo -e "${RED}❌ Configuration test failed!${NC}"
    echo "Rolling back..."
    rm /etc/nginx/sites-enabled/xibo
    exit 1
fi

# Step 8: Reload Nginx
echo -e "${YELLOW}[8/10] Reloading Nginx...${NC}"
systemctl reload nginx
echo -e "${GREEN}✅ Nginx reloaded${NC}"

# Step 9: Configure firewall
echo -e "${YELLOW}[9/10] Configuring firewall...${NC}"
if command_exists ufw; then
    ufw allow 'Nginx Full' 2>/dev/null || true
    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 443/tcp 2>/dev/null || true
    echo -e "${GREEN}✅ Firewall configured${NC}"
else
    echo -e "${YELLOW}⚠️  UFW not found. Please configure firewall manually.${NC}"
fi

# Step 10: Obtain SSL certificate
echo -e "${YELLOW}[10/10] Obtaining SSL certificate...${NC}"
echo "This will obtain a Let's Encrypt SSL certificate for $DOMAIN"
echo ""

# Check if DNS is pointing to this server
SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)

echo "Server IP: $SERVER_IP"
echo "Domain IP: $DOMAIN_IP"
echo ""

if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    echo -e "${YELLOW}⚠️  Warning: Domain IP does not match server IP${NC}"
    echo "Please ensure your DNS records are pointing to this server before continuing."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping SSL certificate. You can run it later with:"
        echo "  sudo certbot --nginx -d $DOMAIN -d $WWW_DOMAIN"
        exit 0
    fi
fi

# Obtain certificate
certbot --nginx -d $DOMAIN -d $WWW_DOMAIN --email $EMAIL --agree-tos --non-interactive --redirect

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL certificate obtained!${NC}"
    
    # Set up auto-renewal
    echo -e "${YELLOW}Setting up automatic SSL renewal...${NC}"
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    # Test renewal
    certbot renew --dry-run
    
    echo -e "${GREEN}✅ Auto-renewal configured${NC}"
else
    echo -e "${YELLOW}⚠️  SSL certificate could not be obtained automatically${NC}"
    echo "You can try manually with:"
    echo "  sudo certbot --nginx -d $DOMAIN -d $WWW_DOMAIN"
fi

# Final summary
echo ""
echo -e "${GREEN}=================================="
echo "🎉 Deployment Complete!"
echo "==================================${NC}"
echo ""
echo "✅ Nginx is configured and running"
echo "✅ Xibo is accessible via HTTPS"
echo ""
echo "🌐 Access your Xibo CMS at:"
echo "   https://$DOMAIN"
echo ""
echo "📊 Check your configuration:"
echo "   - Test SSL: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
echo "   - View logs: sudo tail -f /var/log/nginx/xibo-error.log"
echo "   - Status: sudo systemctl status nginx"
echo ""
echo "🔧 Useful commands:"
echo "   - Reload Nginx: sudo systemctl reload nginx"
echo "   - Test config: sudo nginx -t"
echo "   - View certificates: sudo certbot certificates"
echo "   - Renew SSL: sudo certbot renew"
echo ""
echo -e "${GREEN}Happy signage! 🎬${NC}"

