# Migration Guide - Moving Away from Oracle Cloud

This guide helps you backup and migrate your Strapi CMS from Oracle Cloud to alternative hosting platforms if needed.

## Table of Contents

1. [When to Migrate](#when-to-migrate)
2. [Pre-Migration Checklist](#pre-migration-checklist)
3. [Backup Procedures](#backup-procedures)
4. [Migration to Hetzner VPS](#migration-to-hetzner-vps)
5. [Migration to Railway](#migration-to-railway)
6. [Migration to Render](#migration-to-render)
7. [Migration to Any VPS](#migration-to-any-vps)
8. [Post-Migration Tasks](#post-migration-tasks)
9. [Emergency Quick Migration](#emergency-quick-migration)

---

## When to Migrate

Consider migrating if:

- ❌ Oracle Cloud account suspended or terminated
- ❌ Consistent performance issues or downtime
- ❌ Difficulty provisioning or scaling resources
- ❌ Support issues that can't be resolved
- ✅ Better pricing or features elsewhere
- ✅ Need for managed services
- ✅ Compliance or regional requirements

---

## Pre-Migration Checklist

Before starting migration:

- [ ] Full database backup
- [ ] Backup all uploaded files/media
- [ ] Copy environment variables (`.env` file)
- [ ] Export PM2 configuration
- [ ] Document current nginx configuration
- [ ] Note all installed packages and versions
- [ ] Export SSL certificates (if needed)
- [ ] Test backup restoration locally
- [ ] Plan for DNS changeover (if using domain)
- [ ] Notify users of potential downtime (if applicable)

---

## Backup Procedures

### 1. Database Backup

On your Oracle Cloud VM:

```bash
# Create backup directory
mkdir -p ~/backups

# Backup database
pg_dump -U strapi -h localhost strapi > ~/backups/strapi_$(date +%Y%m%d).sql

# Compress backup
gzip ~/backups/strapi_$(date +%Y%m%d).sql

# Download to local machine (run from your computer)
scp -i /path/to/key ubuntu@oracle-ip:~/backups/strapi_*.sql.gz ~/Desktop/
```

### 2. Application Files Backup

```bash
# Create tarball of application
cd ~/strapi-cms
tar -czf ~/backups/strapi-app_$(date +%Y%m%d).tar.gz \
  --exclude='node_modules' \
  --exclude='.tmp' \
  --exclude='logs' \
  --exclude='.env' \
  .

# Download to local machine
scp -i /path/to/key ubuntu@oracle-ip:~/backups/strapi-app_*.tar.gz ~/Desktop/
```

### 3. Uploaded Files/Media Backup

```bash
# If you have uploads directory
cd ~/strapi-cms
tar -czf ~/backups/uploads_$(date +%Y%m%d).tar.gz public/uploads

# Download to local machine
scp -i /path/to/key ubuntu@oracle-ip:~/backups/uploads_*.tar.gz ~/Desktop/
```

### 4. Environment Variables Backup

```bash
# Copy .env file
cp ~/strapi-cms/.env ~/backups/.env.backup

# Download to local machine
scp -i /path/to/key ubuntu@oracle-ip:~/backups/.env.backup ~/Desktop/
```

### 5. SSL Certificates Backup (if needed)

```bash
# Backup Let's Encrypt certificates
sudo tar -czf ~/backups/letsencrypt_$(date +%Y%m%d).tar.gz /etc/letsencrypt

# Download to local machine (may need sudo)
sudo chown ubuntu:ubuntu ~/backups/letsencrypt_*.tar.gz
scp -i /path/to/key ubuntu@oracle-ip:~/backups/letsencrypt_*.tar.gz ~/Desktop/
```

---

## Migration to Hetzner VPS

**Cost:** ~€4.15/month (~$4.50)
**Best for:** Full control, great value

### Step 1: Create Hetzner Account and VPS

1. Go to [hetzner.com](https://www.hetzner.com/)
2. Create account
3. Order Cloud Server (CX21 or larger)
   - Location: Choose closest to your users
   - Image: Ubuntu 22.04
   - Add SSH key

### Step 2: Setup Server

SSH into new server:

```bash
ssh root@hetzner-ip
```

Clone your repository and run setup:

```bash
apt update
cd /root
git clone https://github.com/yourusername/bella-site-cms.git strapi-cms
cd strapi-cms
./deploy/setup-server.sh
```

### Step 3: Restore Database

```bash
# Copy backup to new server (from your computer)
scp ~/Desktop/strapi_*.sql.gz root@hetzner-ip:/root/

# On Hetzner server, restore database
gunzip /root/strapi_*.sql.gz
sudo -u postgres psql -d strapi < /root/strapi_*.sql
```

### Step 4: Restore Application Files

```bash
# Copy uploads (if any)
scp ~/Desktop/uploads_*.tar.gz root@hetzner-ip:/root/strapi-cms/

# Extract
cd /root/strapi-cms
tar -xzf /root/strapi-cms/uploads_*.tar.gz
```

### Step 5: Configure and Start

```bash
cd /root/strapi-cms

# Copy environment variables
nano .env  # Paste your backed-up .env content

# Install dependencies
npm ci --only=production

# Build
npm run build

# Start with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### Step 6: Configure Nginx and SSL

```bash
# Setup nginx
sudo cp deploy/nginx.conf /etc/nginx/sites-available/strapi
sudo ln -s /etc/nginx/sites-available/strapi /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Setup SSL
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### Step 7: Update DNS

Point your domain to new Hetzner IP:
- Update A record to Hetzner IP
- Wait for DNS propagation (5-60 minutes)
- Test: `nslookup yourdomain.com`

---

## Migration to Railway

**Cost:** ~$5-10/month
**Best for:** Simplicity, managed services

### Step 1: Install Railway CLI

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login
```

### Step 2: Initialize Project

```bash
cd bella-site-cms
railway init
```

### Step 3: Add PostgreSQL

```bash
railway add --plugin postgresql
```

### Step 4: Configure Environment Variables

```bash
# Set environment variables
railway variables set NODE_ENV=production
railway variables set APP_KEYS="your_app_keys"
railway variables set API_TOKEN_SALT="your_salt"
railway variables set ADMIN_JWT_SECRET="your_secret"
railway variables set TRANSFER_TOKEN_SALT="your_salt"
railway variables set JWT_SECRET="your_secret"

# Database will be auto-configured
```

### Step 5: Deploy

```bash
railway up
```

### Step 6: Restore Database

```bash
# Get PostgreSQL connection string
railway variables

# Restore from local machine
psql "postgresql://user:pass@host:port/db" < ~/Desktop/strapi_*.sql
```

### Step 7: Configure Domain

In Railway dashboard:
1. Go to Settings → Domains
2. Add your custom domain
3. Update DNS with provided CNAME

---

## Migration to Render

**Cost:** Free (with limitations) or $14/month
**Best for:** Free tier, easy setup

### Step 1: Create Render Account

1. Go to [render.com](https://render.com/)
2. Sign up with GitHub
3. Connect your repository

### Step 2: Create PostgreSQL Database

1. Click **New** → **PostgreSQL**
2. Name: `strapi-db`
3. Choose free or paid tier
4. Click **Create Database**
5. Note connection string

### Step 3: Create Web Service

1. Click **New** → **Web Service**
2. Connect your repository
3. Configure:
   - **Name:** `strapi-cms`
   - **Environment:** `Node`
   - **Build Command:** `npm ci && npm run build`
   - **Start Command:** `npm start`
   - **Plan:** Free or Starter

### Step 4: Add Environment Variables

In web service settings, add:

```
NODE_ENV=production
DATABASE_URL=<your-render-postgres-url>
APP_KEYS=your_app_keys
API_TOKEN_SALT=your_salt
ADMIN_JWT_SECRET=your_secret
TRANSFER_TOKEN_SALT=your_salt
JWT_SECRET=your_secret
```

### Step 5: Restore Database

```bash
# Use Render's PostgreSQL connection string
psql "postgresql://user:pass@host/db" < ~/Desktop/strapi_*.sql
```

### Step 6: Deploy

Render auto-deploys on git push. Or manually trigger deployment in dashboard.

---

## Migration to Any VPS

General steps for migrating to any VPS (DigitalOcean, Vultr, Linode, AWS EC2, etc.):

### 1. Provision Server

- Create Ubuntu 22.04 server
- Add SSH key
- Note public IP

### 2. Transfer Files

```bash
# From your local machine
scp -r bella-site-cms user@new-ip:~/
scp ~/Desktop/strapi_*.sql.gz user@new-ip:~/
scp ~/Desktop/uploads_*.tar.gz user@new-ip:~/
```

### 3. Setup Environment

```bash
ssh user@new-ip
cd ~/bella-site-cms
./deploy/setup-server.sh
```

### 4. Restore Everything

```bash
# Database
./deploy/setup-database.sh
gunzip ~/strapi_*.sql.gz
sudo -u postgres psql -d strapi < ~/strapi_*.sql

# Uploads
tar -xzf ~/uploads_*.tar.gz -C ~/bella-site-cms/public/

# Environment
cp ~/backup/.env.backup ~/bella-site-cms/.env
```

### 5. Deploy Application

```bash
cd ~/bella-site-cms
npm ci --only=production
npm run build
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### 6. Configure Web Server

```bash
sudo cp deploy/nginx.conf /etc/nginx/sites-available/strapi
sudo ln -s /etc/nginx/sites-available/strapi /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d yourdomain.com
```

---

## Post-Migration Tasks

### 1. Verify Everything Works

```bash
# Test database connection
psql -U strapi -d strapi -c "SELECT COUNT(*) FROM strapi_users;"

# Test application
curl http://localhost:1337
curl https://yourdomain.com

# Check logs
pm2 logs strapi-cms
```

### 2. Update DNS (if changed)

- Update A record to new IP
- Wait for propagation
- Test from multiple locations

### 3. Test All Functionality

- [ ] Admin panel login
- [ ] Content creation/editing
- [ ] File uploads
- [ ] API endpoints
- [ ] User authentication
- [ ] All custom features

### 4. Setup Monitoring

Consider:
- UptimeRobot for uptime monitoring
- LogTail for log aggregation
- Sentry for error tracking

### 5. Update Documentation

- Update DEPLOYMENT.md with new host details
- Update team/documentation with new URLs
- Update CI/CD if applicable

### 6. Decommission Old Server

**Wait at least 7 days** before destroying old infrastructure:

1. Stop application: `pm2 stop all`
2. Keep backups for 30 days
3. If on Oracle Cloud: Delete compute instance
4. Cancel old hosting (if paid)

---

## Emergency Quick Migration

If Oracle Cloud suspends your account unexpectedly:

### Fastest Option: Railway (15 minutes)

```bash
# From your local machine
cd bella-site-cms
npm install -g @railway/cli
railway login
railway init
railway add postgresql

# Set environment variables (use backed up .env)
railway variables set NODE_ENV=production
# ... set all other variables

# Deploy
railway up

# Get database URL and restore
railway variables | grep DATABASE_URL
psql "<database-url>" < ~/Desktop/strapi_backup.sql
```

### Second Fastest: Render (30 minutes)

1. Push code to GitHub (if not already)
2. Create Render account
3. Connect repository
4. Add PostgreSQL database
5. Create web service with environment variables
6. Deploy
7. Restore database

### DIY VPS: Hetzner (45-60 minutes)

1. Create Hetzner account
2. Provision CX21 server
3. Run setup script
4. Restore database and files
5. Configure nginx and SSL

---

## Cost Comparison After Migration

| Platform | Setup Time | Monthly Cost | Complexity |
|----------|-----------|--------------|------------|
| **Hetzner VPS** | 45-60 min | $4.50 | Medium |
| **Railway** | 15-30 min | $5-10 | Low |
| **Render (Free)** | 20-30 min | $0 | Low |
| **Render (Paid)** | 20-30 min | $14 | Low |
| **DigitalOcean** | 45-60 min | $12 | Medium |
| **Fly.io** | 20-30 min | $12-15 | Low-Medium |

---

## Migration Support

If you need help during migration:

1. Check platform documentation
2. Use platform support channels
3. Review Strapi migration docs
4. Check community forums

---

## Prevention Tips

To avoid future migrations:

1. **Regular backups** - Automate daily backups
2. **Monitor account status** - Check Oracle Cloud console weekly
3. **Diversify** - Consider multi-cloud for critical applications
4. **Document everything** - Keep this guide updated
5. **Test restores** - Verify backups work monthly
6. **Budget buffer** - Have $5-10/month budget for paid hosting if needed

---

## Backup Automation Script

Save this to automate backups:

```bash
#!/bin/bash
# backup-all.sh - Complete backup script

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/backups/$DATE"
mkdir -p $BACKUP_DIR

# Database
pg_dump -U strapi strapi | gzip > "$BACKUP_DIR/database.sql.gz"

# Application files
tar -czf "$BACKUP_DIR/app.tar.gz" \
  --exclude='node_modules' \
  --exclude='.tmp' \
  --exclude='logs' \
  ~/strapi-cms/

# Uploads
tar -czf "$BACKUP_DIR/uploads.tar.gz" ~/strapi-cms/public/uploads

# Environment
cp ~/strapi-cms/.env "$BACKUP_DIR/.env"

# Sync to S3 or other storage (optional)
# aws s3 sync $BACKUP_DIR s3://your-bucket/backups/$DATE/

echo "Backup completed: $BACKUP_DIR"

# Keep only last 7 backups
ls -t $HOME/backups/ | tail -n +8 | xargs -I {} rm -rf "$HOME/backups/{}"
```

Make executable and schedule:

```bash
chmod +x ~/backup-all.sh
crontab -e
# Add: 0 2 * * * /home/ubuntu/backup-all.sh
```

---

*Last updated: 2025-11-03*
