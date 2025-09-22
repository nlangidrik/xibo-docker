# Xibo Docker

[Docker](https://docker.com/) is an application to package and run any
application in a pre-configured container making it much easier to deploy a Xibo
CMS with recommended configuration.

This repository holds the docker container definitions for Xibo and the docker-compose
configuration, which is used to bootstrap, start, stop and destroy the installation.

## Quick Start (Recommended)

### Prerequisites
- Docker and Docker Compose installed
- Git (to clone this repository)

### Installation Steps

1. **Clone this repository:**
   ```bash
   git clone <your-repo-url>
   cd xibo-docker
   ```

2. **Configure the environment:**
   ```bash
   cp config.env.template config.env
   # Edit config.env with your settings (especially MYSQL_PASSWORD)
   ```

3. **Start Xibo (Choose your platform):**

   **For Linux/macOS:**
   ```bash
   chmod +x start-xibo.sh
   ./start-xibo.sh
   ```

   **For Windows:**
   ```cmd
   start-xibo.bat
   ```

4. **Access Xibo:**
   - Open your browser to `http://localhost`
   - Complete the Xibo setup wizard

### Optional: Nginx Reverse Proxy Setup

For production deployments with SSL and better security:

```bash
# Make the setup script executable (Linux/macOS)
chmod +x setup-nginx.sh

# Run the Nginx setup script
sudo ./setup-nginx.sh
```

This will:
- Install Nginx and Certbot
- Configure SSL with Let's Encrypt
- Set up proper security headers
- Configure WebSocket support for XMR
- Set up automatic SSL renewal

### Stopping Xibo

**For Linux/macOS:**
```bash
./stop-xibo.sh
```

**For Windows:**
```cmd
stop-xibo.bat
```

## Installing Xibo Players on Displays

To display content on screens, you need to install Xibo players on your display devices:

### Quick Player Setup

**For Raspberry Pi:**
```bash
# Download Xibo Pi OS (recommended)
wget https://github.com/xibosignage/xibo-pi-os/releases/latest/download/xibo-pi-os.img.xz
# Flash to SD card and boot
```

**For Windows/Linux:**
```bash
# Download player from Xibo website
# Install and configure to connect to your CMS
```

**For Thin Clients:**
- Use the appropriate player for your OS
- Configure auto-start and auto-login
- Connect to your CMS server

### Player Configuration
1. Set CMS address to your server IP/domain
2. Give display a descriptive name
3. Approve display in CMS admin panel
4. Assign display profile and schedule

📖 **Complete Player Installation Guide**: See `XIBO-PLAYER-INSTALLATION.md` for detailed instructions for all platforms.

## Manual Installation
Full installation instructions for supported use of these containers can be
found in the [Xibo
Manual](http://xibo.org.uk/manual-tempel/en/install_cms.html)

## Directory structure

This repository contains Docker configuration (Dockerfile) for the Xibo
containers. A normal installation *only* requires `docker-compose.yaml` and
a `config.env.template` file, suitably configured, saved as `config.env`.

#### /containers

web and xmr Dockerfiles and associated configuration. These are built by Docker
Hub and packaged into `xibosignage/xibo-cms` and `xibosignage/xibo-xmr`.

#### DATA_DIR/shared

Data folders for the Xibo installation.

 - The Library storage can be found in `/shared/cms/library`
 - The database storage can be found in `/shared/db`
 - Automated daily database backups can be found in `/shared/backup`
 - Custom themes should be placed in `/shared/cms/web/theme/custom`
 - Custom modules should be placed in `/shared/cms/custom`
 - Any user generated PHP or resources external to Xibo that you want hosted
   on the same webserver go in `/shared/cms/web/userscripts`. They will then
   be available to you at `http://localhost/userscripts/`

## Running without docker-compose
If you have your own docker environment you may want to run without the
automation provided by docker-compose. If this is the case you will be responsible
for pulling the docker containers, starting them and manually installing Xibo.


## File Structure
```
xibo-docker/
├── start-xibo.sh              # Linux startup script
├── start-xibo.bat             # Windows startup script
├── stop-xibo.sh               # Linux stop script
├── stop-xibo.bat              # Windows stop script
├── setup-nginx.sh             # Nginx reverse proxy setup script
├── nginx-xibo.conf.template   # Nginx configuration template
├── docker-compose.yml         # Docker Compose configuration
├── config.env.template        # Environment template
├── config.env                 # Your configuration (create this)
├── PRODUCTION-DEPLOYMENT.md   # Production deployment guide
├── DEBIAN-DEPLOYMENT.md       # Debian-specific deployment guide
├── XIBO-PLAYER-INSTALLATION.md # Player installation guide
└── shared/                    # Data directory
    ├── db/                    # Database files
    ├── backup/                # Database backups
    └── cms/                   # CMS files
        ├── library/           # Media library
        └── web/               # Web files
```

## Reporting problems

Support requests can be reported on the [Xibo Community
Forum](https://community.xibo.org.uk/). Verified, re-producable bugs with this
repository can be reported in the [Xibo parent
repository](https://github.com/xibosignage/xibo/issues).
