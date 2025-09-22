@echo off
REM Xibo Docker Stop Script for Windows
REM This script stops all Xibo services cleanly

echo 🛑 Stopping Xibo Docker Services...

REM Stop and remove all containers
docker stop xibo-docker-cms-web-1 2>nul
docker stop xibo-xmr-manual 2>nul
docker compose down 2>nul

REM Remove the manually created XMR container
docker rm xibo-xmr-manual 2>nul

echo ✅ All Xibo services stopped successfully!
echo 💡 To start again, run: start-xibo.bat
pause
