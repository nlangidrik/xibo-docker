#!/bin/bash

# Xibo Docker Startup Script
# This script handles the XMR container issue and starts all Xibo services
# Compatible with Debian, Ubuntu, and other Linux distributions

set -e

echo "🚀 Starting Xibo Docker Setup..."

# Check if config.env exists
if [ ! -f "config.env" ]; then
    echo "❌ config.env not found! Please copy config.env.template to config.env and configure it."
    exit 1
fi

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker compose down 2>/dev/null || true
docker stop xibo-xmr-manual 2>/dev/null || true
docker stop xibo-docker-cms-web-1 2>/dev/null || true
docker rm xibo-xmr-manual 2>/dev/null || true
docker rm xibo-docker-cms-web-1 2>/dev/null || true

# Start core services (everything except XMR)
echo "📦 Starting core services..."
docker compose up -d cms-db cms-memcached cms-quickchart

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

# Start XMR container manually (workaround for Docker API issue)
echo "🔄 Starting XMR container manually..."
docker run -d \
    --name xibo-xmr-manual \
    --network xibo-docker_default \
    -p 9505:9505 \
    --restart always \
    --env-file config.env \
    ghcr.io/xibosignage/xibo-xmr:1.0

# Wait for XMR to be ready
echo "⏳ Waiting for XMR to be ready..."
sleep 5

# Start CMS with correct XMR host
echo "🌐 Starting CMS with XMR connection..."
docker run -d \
    --name xibo-docker-cms-web-1 \
    --network xibo-docker_default \
    -p 80:80 \
    --restart always \
    -e MYSQL_HOST=cms-db \
    -e XMR_HOST=xibo-xmr-manual \
    -e CMS_USE_MEMCACHED=true \
    -e MEMCACHED_HOST=cms-memcached \
    --env-file config.env \
    -v "./shared/cms/custom:/var/www/cms/custom:Z" \
    -v "./shared/backup:/var/www/backup:Z" \
    -v "./shared/cms/web/theme/custom:/var/www/cms/web/theme/custom:Z" \
    -v "./shared/cms/library:/var/www/cms/library:Z" \
    -v "./shared/cms/web/userscripts:/var/www/cms/web/userscripts:Z" \
    -v "./shared/cms/ca-certs:/var/www/cms/ca-certs:Z" \
    ghcr.io/xibosignage/xibo-cms:release-4.3.0

# Wait for CMS to be ready
echo "⏳ Waiting for CMS to be ready..."
sleep 15

# Verify all services are running
echo "✅ Verifying services..."
if docker ps | grep -q "xibo-docker-cms-web-1" && \
   docker ps | grep -q "xibo-xmr-manual" && \
   docker ps | grep -q "xibo-docker-cms-db-1"; then
    echo "🎉 Xibo is running successfully!"
    echo "🌐 Access your Xibo CMS at: http://localhost"
    echo "📊 XMR is running on port: 9505"
    echo ""
    echo "📋 Container Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep xibo
else
    echo "❌ Some services failed to start. Check logs:"
    docker compose logs
    exit 1
fi
