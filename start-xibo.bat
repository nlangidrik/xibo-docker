@echo off
REM Xibo Docker Startup Script for Windows
REM This script handles the XMR container issue and starts all Xibo services

echo 🚀 Starting Xibo Docker Setup...

REM Check if config.env exists
if not exist "config.env" (
    echo ❌ config.env not found! Please copy config.env.template to config.env and configure it.
    pause
    exit /b 1
)

REM Stop any existing containers
echo 🛑 Stopping existing containers...
docker compose down 2>nul
docker stop xibo-xmr-manual 2>nul
docker stop xibo-docker-cms-web-1 2>nul
docker rm xibo-xmr-manual 2>nul
docker rm xibo-docker-cms-web-1 2>nul

REM Start core services (everything except XMR)
echo 📦 Starting core services...
docker compose up -d cms-db cms-memcached cms-quickchart

REM Wait for database to be ready
echo ⏳ Waiting for database to be ready...
timeout /t 10 /nobreak >nul

REM Get current directory for absolute paths
set CURRENT_DIR=%CD%

REM Start XMR container manually (workaround for Docker API issue)
echo 🔄 Starting XMR container manually...
docker run -d --name xibo-xmr-manual --network xibo-docker_default -p 9505:9505 --restart always --env-file "%CURRENT_DIR%\config.env" ghcr.io/xibosignage/xibo-xmr:1.0

REM Wait for XMR to be ready
echo ⏳ Waiting for XMR to be ready...
timeout /t 5 /nobreak >nul

REM Start CMS with correct XMR host
echo 🌐 Starting CMS with XMR connection...
docker run -d --name xibo-docker-cms-web-1 --network xibo-docker_default -p 80:80 --restart always -e MYSQL_HOST=cms-db -e XMR_HOST=xibo-xmr-manual -e CMS_USE_MEMCACHED=true -e MEMCACHED_HOST=cms-memcached --env-file "%CURRENT_DIR%\config.env" -v "%CURRENT_DIR%\shared\cms\custom:/var/www/cms/custom:Z" -v "%CURRENT_DIR%\shared\backup:/var/www/backup:Z" -v "%CURRENT_DIR%\shared\cms\web\theme\custom:/var/www/cms/web/theme/custom:Z" -v "%CURRENT_DIR%\shared\cms\library:/var/www/cms/library:Z" -v "%CURRENT_DIR%\shared\cms\web\userscripts:/var/www/cms/web/userscripts:Z" -v "%CURRENT_DIR%\shared\cms\ca-certs:/var/www/cms/ca-certs:Z" ghcr.io/xibosignage/xibo-cms:release-4.3.0

REM Wait for CMS to be ready
echo ⏳ Waiting for CMS to be ready...
timeout /t 15 /nobreak >nul

REM Verify all services are running
echo ✅ Verifying services...
docker ps | findstr "xibo-docker-cms-web-1" >nul
if %errorlevel% equ 0 (
    docker ps | findstr "xibo-xmr-manual" >nul
    if %errorlevel% equ 0 (
        docker ps | findstr "xibo-docker-cms-db-1" >nul
        if %errorlevel% equ 0 (
            echo 🎉 Xibo is running successfully!
            echo 🌐 Access your Xibo CMS at: http://localhost
            echo 📊 XMR is running on port: 9505
            echo.
            echo 📋 Container Status:
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr xibo
        ) else (
            echo ❌ Database failed to start
        )
    ) else (
        echo ❌ XMR failed to start
    )
) else (
    echo ❌ CMS failed to start
    echo Check logs with: docker compose logs
)

pause
