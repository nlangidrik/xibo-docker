#!/bin/bash

# Xibo Docker Stop Script
# This script stops all Xibo services cleanly

echo "🛑 Stopping Xibo Docker Services..."

# Stop and remove all containers
docker stop xibo-docker-cms-web-1 2>/dev/null || true
docker stop xibo-xmr-manual 2>/dev/null || true
docker compose down 2>/dev/null || true

# Remove the manually created XMR container
docker rm xibo-xmr-manual 2>/dev/null || true

echo "✅ All Xibo services stopped successfully!"
echo "💡 To start again, run: ./start-xibo.sh"
