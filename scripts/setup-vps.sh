#!/bin/bash

# VPS Setup script
# Run this script on your VPS to set up the environment for deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

log "Setting up VPS for deployment..."

# Update system packages
log "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
log "Installing required packages..."
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
log "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
    log "Docker is already installed"
fi

# Install Docker Compose (standalone)
log "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    log "Docker Compose is already installed"
fi

# Start and enable Docker service
log "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Create deployment user (optional)
read -p "Do you want to create a dedicated deployment user? (y/n): " create_user
if [[ $create_user == "y" || $create_user == "Y" ]]; then
    read -p "Enter username for deployment user: " deploy_user
    if id "$deploy_user" &>/dev/null; then
        warning "User $deploy_user already exists"
    else
        log "Creating deployment user: $deploy_user"
        useradd -m -s /bin/bash "$deploy_user"
        usermod -aG docker "$deploy_user"
        usermod -aG sudo "$deploy_user"
        
        # Create SSH directory
        mkdir -p /home/"$deploy_user"/.ssh
        chown "$deploy_user":"$deploy_user" /home/"$deploy_user"/.ssh
        chmod 700 /home/"$deploy_user"/.ssh
        
        log "User $deploy_user created successfully"
        log "Don't forget to add SSH keys for this user"
    fi
fi

# Create project directory
PROJECT_DIR="/opt/turbo-ci-starter"
log "Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"

# Set up firewall (if ufw is available)
if command -v ufw &> /dev/null; then
    log "Configuring firewall..."
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 3000/tcp
    ufw allow 3001/tcp
    ufw --force enable
fi

# Install Nginx (optional, for reverse proxy)
read -p "Do you want to install Nginx for reverse proxy? (y/n): " install_nginx
if [[ $install_nginx == "y" || $install_nginx == "Y" ]]; then
    log "Installing Nginx..."
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Create basic nginx config
    cat > /etc/nginx/sites-available/turbo-ci-starter << EOF
server {
    listen 80;
    server_name your-domain.com;  # Replace with your domain
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api {
        proxy_pass http://localhost:3001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/turbo-ci-starter /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl reload nginx
    
    log "Nginx configured. Don't forget to update the server_name in the config"
fi

# Install Certbot for SSL (optional)
read -p "Do you want to install Certbot for SSL certificates? (y/n): " install_certbot
if [[ $install_certbot == "y" || $install_certbot == "Y" ]]; then
    log "Installing Certbot..."
    apt install -y certbot python3-certbot-nginx
    log "Certbot installed. Run 'certbot --nginx' to get SSL certificates"
fi

log "VPS setup completed successfully!"
log "Next steps:"
log "1. Add your SSH public key to the server"
log "2. Clone your repository to $PROJECT_DIR"
log "3. Configure GitHub Actions secrets in your repository"
log "4. Set up your domain DNS (if using Nginx)"
log "5. Run the deployment script"