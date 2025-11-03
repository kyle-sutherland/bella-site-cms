#!/bin/bash
# Oracle Cloud VM Setup Script for Strapi CMS
# Run this script on your fresh Oracle Cloud Ubuntu VM

set -e  # Exit on error

echo "=================================="
echo "Strapi CMS - Oracle Cloud Setup"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
   echo "Please do not run this script as root. Run as a regular user with sudo privileges."
   exit 1
fi

# Update system
echo "[1/10] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "[2/10] Installing essential packages..."
sudo apt install -y curl git build-essential nginx certbot python3-certbot-nginx ufw

# Install Node.js 20 LTS
echo "[3/10] Installing Node.js 20 LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installations
echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"

# Install PM2 globally for process management
echo "[4/10] Installing PM2 process manager..."
sudo npm install -g pm2

# Install PostgreSQL
echo "[5/10] Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Setup database and user
echo "[6/10] Setting up PostgreSQL database..."
echo "You'll need to create a database and user. Run these commands manually:"
echo "  sudo -u postgres psql"
echo "  CREATE DATABASE strapi;"
echo "  CREATE USER strapi WITH ENCRYPTED PASSWORD 'your_secure_password';"
echo "  GRANT ALL PRIVILEGES ON DATABASE strapi TO strapi;"
echo "  \\q"
echo ""
read -p "Press Enter after you've created the database and user..."

# Configure firewall
echo "[7/10] Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# Create application directory
echo "[8/10] Creating application directory..."
APP_DIR="/home/$USER/strapi-cms"
mkdir -p $APP_DIR
cd $APP_DIR

# Clone repository (you'll need to update this with your repo URL)
echo "[9/10] Ready to clone repository..."
echo "Run this command to clone your repository:"
echo "  git clone <your-repo-url> ."
echo ""
echo "After cloning:"
echo "  1. Copy .env.example to .env"
echo "  2. Update .env with your production values"
echo "  3. Run: npm ci --only=production"
echo "  4. Run: npm run build"
echo "  5. Configure nginx (see deploy/nginx.conf)"
echo "  6. Start with PM2: pm2 start ecosystem.config.js"
echo ""

echo "[10/10] Server setup complete!"
echo ""
echo "Next steps:"
echo "1. Clone your repository to $APP_DIR"
echo "2. Configure environment variables (.env)"
echo "3. Generate secrets using: node deploy/generate-secrets.js"
echo "4. Build Strapi: npm run build"
echo "5. Configure nginx: sudo cp deploy/nginx.conf /etc/nginx/sites-available/strapi"
echo "6. Start application with PM2: pm2 start ecosystem.config.js"
echo "7. Setup SSL: sudo certbot --nginx -d yourdomain.com"
echo "8. Save PM2 config: pm2 save && pm2 startup"
echo ""
echo "For detailed instructions, see DEPLOYMENT.md"
