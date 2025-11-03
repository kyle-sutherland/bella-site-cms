# Strapi CMS - Oracle Cloud Deployment Guide

Complete guide for deploying this Strapi CMS to Oracle Cloud Free Tier.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Oracle Cloud Account Setup](#oracle-cloud-account-setup)
3. [Create and Configure VM](#create-and-configure-vm)
4. [Server Setup](#server-setup)
5. [Database Setup](#database-setup)
6. [Application Deployment](#application-deployment)
7. [Nginx Configuration](#nginx-configuration)
8. [SSL Setup](#ssl-setup)
9. [Monitoring and Maintenance](#monitoring-and-maintenance)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Git repository with this Strapi CMS code
- Domain name (optional, but recommended for SSL)
- SSH key pair for secure access
- Credit card for Oracle Cloud verification (not charged on free tier)

---

## Oracle Cloud Account Setup

### Step 1: Create Oracle Cloud Account

1. Go to [cloud.oracle.com](https://cloud.oracle.com/)
2. Click "Sign up for free"
3. Fill in your details (real information required)
4. Verify email address
5. Enter payment information (required but won't be charged)
6. Wait for account approval (can take 24-48 hours)

**Important:** If your account gets rejected, try:
- Using a different email provider
- Using a different credit card
- Waiting a few days and trying again
- Contacting Oracle support

### Step 2: Login to Console

1. Go to [cloud.oracle.com](https://cloud.oracle.com/)
2. Click "Sign In"
3. Enter your cloud account name
4. Login with your credentials

---

## Create and Configure VM

### Step 1: Create ARM-Based Compute Instance

1. In Oracle Cloud Console, click **Compute** → **Instances**
2. Click **Create Instance**

**Instance Configuration:**
- **Name:** `strapi-cms-vm` (or your choice)
- **Compartment:** Select your compartment (usually `root`)

**Placement:**
- **Availability Domain:** Select any available

**Image and Shape:**
- Click **Change Image**
- Select **Canonical Ubuntu** (22.04 or later)
- Click **Select Image**

- Click **Change Shape**
- Select **Ampere** (ARM-based)
- Shape: **VM.Standard.A1.Flex**
- OCPUs: **4** (max on free tier)
- Memory: **24 GB** (max on free tier)
- Click **Select Shape**

**Networking:**
- **VCN:** Create new or select existing
- **Subnet:** Create new or select existing (public subnet)
- **Assign public IPv4 address:** ✅ YES

**SSH Keys:**
- **Upload public key files (.pub)** or paste your SSH public key
- Save the private key securely if generating new keys

**Boot Volume:**
- Size: **100-200 GB** (max 200GB on free tier)

3. Click **Create**

**Note:** If you get "Out of capacity" error:
- Try different availability domains
- Try at different times of day
- Use automation scripts to retry (check Oracle forums for scripts)

### Step 2: Note Your Instance Details

After instance is created, note:
- **Public IP Address:** (e.g., 123.456.789.012)
- **Username:** `ubuntu` (for Ubuntu images)
- **SSH command:** `ssh -i /path/to/key ubuntu@your-public-ip`

### Step 3: Configure VCN Security Lists

1. Go to **Networking** → **Virtual Cloud Networks**
2. Click your VCN name
3. Click **Security Lists** → Your default security list
4. Click **Add Ingress Rules**

Add these rules:

**Rule 1: HTTP**
- Source CIDR: `0.0.0.0/0`
- IP Protocol: `TCP`
- Destination Port Range: `80`
- Description: `HTTP traffic`

**Rule 2: HTTPS**
- Source CIDR: `0.0.0.0/0`
- IP Protocol: `TCP`
- Destination Port Range: `443`
- Description: `HTTPS traffic`

**Rule 3: Strapi (optional, for testing)**
- Source CIDR: `0.0.0.0/0`
- IP Protocol: `TCP`
- Destination Port Range: `1337`
- Description: `Strapi direct access`

### Step 4: Configure OS-Level Firewall

SSH into your VM and run:

```bash
# Configure iptables for HTTP/HTTPS
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 1337 -j ACCEPT

# Save rules
sudo netfilter-persistent save

# Or install iptables-persistent if not available
sudo apt install -y iptables-persistent
```

---

## Server Setup

### Step 1: Connect to Your VM

```bash
ssh -i /path/to/your-key ubuntu@your-public-ip
```

### Step 2: Run Setup Script

On your VM:

```bash
# Update package lists
sudo apt update

# Clone your repository (replace with your actual repo URL)
cd ~
git clone https://github.com/yourusername/bella-site-cms.git strapi-cms
cd strapi-cms

# Run the automated setup script
./deploy/setup-server.sh
```

The script will:
- Install Node.js 20 LTS
- Install PostgreSQL
- Install PM2 process manager
- Install nginx web server
- Configure firewall
- Setup system dependencies

### Step 3: Manual Setup (if script fails)

If the automated script fails, follow these manual steps:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install build tools
sudo apt install -y build-essential git

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install nginx
sudo apt install -y nginx

# Install PM2
sudo npm install -g pm2

# Install certbot for SSL
sudo apt install -y certbot python3-certbot-nginx
```

---

## Database Setup

### Option 1: Automated Setup

```bash
cd ~/strapi-cms
./deploy/setup-database.sh
```

Follow the prompts to create your database and user.

### Option 2: Manual Setup

```bash
# Switch to postgres user
sudo -u postgres psql

# In PostgreSQL prompt:
CREATE DATABASE strapi;
CREATE USER strapi WITH ENCRYPTED PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE strapi TO strapi;

# Connect to the database
\c strapi

# Grant schema privileges
GRANT ALL ON SCHEMA public TO strapi;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO strapi;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO strapi;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO strapi;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO strapi;

# Exit PostgreSQL
\q
```

---

## Application Deployment

### Step 1: Generate Production Secrets

```bash
cd ~/strapi-cms
node deploy/generate-secrets.js
```

Copy the output - you'll need these values for your `.env` file.

### Step 2: Configure Environment Variables

```bash
cd ~/strapi-cms
cp .env.example .env
nano .env
```

Update with your production values:

```env
HOST=0.0.0.0
PORT=1337
APP_URL=https://yourdomain.com  # Or http://your-ip:1337 for testing

# Use the secrets you just generated
APP_KEYS="generated_key_1,generated_key_2,generated_key_3,generated_key_4"
API_TOKEN_SALT=generated_salt
ADMIN_JWT_SECRET=generated_secret
TRANSFER_TOKEN_SALT=generated_salt
JWT_SECRET=generated_secret

# Database configuration
DATABASE_CLIENT=postgres
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=strapi
DATABASE_USERNAME=strapi
DATABASE_PASSWORD=your_database_password_here
DATABASE_SSL=false

NODE_ENV=production
```

Save and exit (Ctrl+X, Y, Enter in nano).

### Step 3: Install Dependencies

```bash
cd ~/strapi-cms
npm ci --only=production
```

### Step 4: Build Strapi

```bash
npm run build
```

This will build the Strapi admin panel. It may take a few minutes.

### Step 5: Create Log Directory

```bash
mkdir -p ~/strapi-cms/logs
```

### Step 6: Update PM2 Configuration

Edit `ecosystem.config.js` to use the correct path:

```bash
nano ecosystem.config.js
```

Update the `cwd` path to match your installation:

```javascript
cwd: '/home/ubuntu/strapi-cms',
```

Also update the log file paths:

```javascript
error_file: '/home/ubuntu/strapi-cms/logs/pm2-error.log',
out_file: '/home/ubuntu/strapi-cms/logs/pm2-out.log',
```

### Step 7: Start with PM2

```bash
cd ~/strapi-cms
pm2 start ecosystem.config.js
```

Check status:

```bash
pm2 status
pm2 logs strapi-cms
```

### Step 8: Setup PM2 Auto-Start

```bash
pm2 save
pm2 startup
# Run the command that PM2 outputs (it will be specific to your system)
```

### Step 9: Test Application

```bash
# Test locally
curl http://localhost:1337

# Test from your computer (replace with your public IP)
curl http://your-public-ip:1337
```

You should see the Strapi welcome page.

---

## Nginx Configuration

### Step 1: Copy Nginx Configuration

```bash
cd ~/strapi-cms
sudo cp deploy/nginx.conf /etc/nginx/sites-available/strapi
```

### Step 2: Update Domain/IP

Edit the nginx config:

```bash
sudo nano /etc/nginx/sites-available/strapi
```

Update `server_name` with your domain or IP:

```nginx
server_name yourdomain.com www.yourdomain.com;
# OR for IP-only access:
server_name your-public-ip;
```

### Step 3: Enable Site

```bash
sudo ln -s /etc/nginx/sites-available/strapi /etc/nginx/sites-enabled/
```

### Step 4: Test and Reload Nginx

```bash
# Test configuration
sudo nginx -t

# If test passes, reload nginx
sudo systemctl reload nginx
```

### Step 5: Verify

Visit `http://yourdomain.com` or `http://your-public-ip` in your browser.

You should see your Strapi CMS!

---

## SSL Setup

### Prerequisites

- Domain name pointed to your Oracle Cloud VM's public IP
- DNS propagated (check with `nslookup yourdomain.com`)

### Step 1: Install Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### Step 2: Obtain SSL Certificate

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Follow the prompts:
- Enter email address
- Agree to terms
- Choose whether to redirect HTTP to HTTPS (recommended: Yes)

### Step 3: Test Auto-Renewal

```bash
sudo certbot renew --dry-run
```

If successful, certificates will auto-renew.

### Step 4: Update Strapi Configuration

Edit your `.env` file:

```bash
nano ~/strapi-cms/.env
```

Update `APP_URL`:

```env
APP_URL=https://yourdomain.com
```

Restart Strapi:

```bash
pm2 restart strapi-cms
```

### Step 5: Verify

Visit `https://yourdomain.com` - you should see a valid SSL certificate!

---

## Monitoring and Maintenance

### PM2 Commands

```bash
# View status
pm2 status

# View logs
pm2 logs strapi-cms

# View real-time monitoring
pm2 monit

# Restart application
pm2 restart strapi-cms

# Stop application
pm2 stop strapi-cms

# View detailed info
pm2 show strapi-cms
```

### Check System Resources

```bash
# Memory usage
free -h

# Disk usage
df -h

# CPU usage
top
# or
htop  # Install with: sudo apt install htop
```

### Database Backups

Create a backup script:

```bash
nano ~/backup-database.sh
```

Add:

```bash
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

pg_dump -U strapi -h localhost strapi > "$BACKUP_DIR/strapi_$DATE.sql"

# Keep only last 7 days of backups
find $BACKUP_DIR -name "strapi_*.sql" -mtime +7 -delete

echo "Backup completed: strapi_$DATE.sql"
```

Make executable and setup cron:

```bash
chmod +x ~/backup-database.sh

# Add to crontab (daily at 2 AM)
crontab -e
# Add this line:
0 2 * * * /home/ubuntu/backup-database.sh
```

### Application Updates

```bash
cd ~/strapi-cms

# Pull latest changes
git pull

# Install dependencies
npm ci --only=production

# Rebuild
npm run build

# Restart
pm2 restart strapi-cms
```

---

## Troubleshooting

### Application Won't Start

Check logs:
```bash
pm2 logs strapi-cms --lines 100
```

Common issues:
- Database connection failed: Check `.env` database credentials
- Port already in use: Check if another process is using port 1337
- Memory issues: Check `free -h` and consider reducing PM2 instances

### Can't Access via Browser

1. Check application is running:
```bash
pm2 status
curl http://localhost:1337
```

2. Check nginx:
```bash
sudo nginx -t
sudo systemctl status nginx
```

3. Check firewall:
```bash
sudo iptables -L -n
sudo ufw status
```

4. Check Oracle Cloud security lists (in web console)

### SSL Certificate Issues

Renew manually:
```bash
sudo certbot renew --force-renewal
```

Check certificate:
```bash
sudo certbot certificates
```

### Database Connection Issues

Test connection:
```bash
psql -U strapi -h localhost -d strapi
```

Check PostgreSQL is running:
```bash
sudo systemctl status postgresql
```

Restart PostgreSQL:
```bash
sudo systemctl restart postgresql
```

### Out of Memory

Check usage:
```bash
free -h
pm2 monit
```

Options:
- Reduce `max_memory_restart` in `ecosystem.config.js`
- Enable swap space
- Optimize PostgreSQL settings

Enable swap (if needed):
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## Post-Deployment Checklist

- [ ] Application accessible via domain/IP
- [ ] SSL certificate installed and working
- [ ] Admin panel accessible
- [ ] Database backups configured
- [ ] PM2 auto-start configured
- [ ] Monitoring setup
- [ ] Firewall rules configured
- [ ] Security headers in place
- [ ] Environment variables secured
- [ ] Documentation updated

---

## Useful Links

- [Oracle Cloud Documentation](https://docs.oracle.com/en-us/iaas/Content/home.htm)
- [Strapi Documentation](https://docs.strapi.io/)
- [PM2 Documentation](https://pm2.keymetrics.io/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

---

## Support

If you encounter issues:

1. Check the logs: `pm2 logs strapi-cms`
2. Review this troubleshooting section
3. Check Oracle Cloud forums
4. Check Strapi forums
5. Refer to MIGRATION.md if you need to move to a different host

---

## Security Recommendations

1. **Keep secrets secure** - Never commit `.env` to git
2. **Regular updates** - Keep system packages updated
3. **Strong passwords** - Use complex database passwords
4. **Firewall rules** - Only open necessary ports
5. **SSL/TLS** - Always use HTTPS in production
6. **Backups** - Regular database and file backups
7. **Monitoring** - Setup uptime monitoring (UptimeRobot, etc.)
8. **Rate limiting** - Consider adding rate limiting to nginx

---

*Last updated: 2025-11-03*
