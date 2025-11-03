# Single Domain Setup Guide

How to use one domain for both your Vercel frontend and Oracle Cloud CMS.

## Overview

**Single domain purchase:** `yourdomain.com`

**Setup:**
- Frontend: `yourdomain.com` (Vercel)
- CMS Admin: `cms.yourdomain.com` (Oracle Cloud)
- API Endpoint: `cms.yourdomain.com/api` (Strapi API, also Oracle Cloud)

**No additional domain costs!** Subdomains are included with your domain purchase.

---

## DNS Configuration

### Option 1: Cloudflare (Recommended - Free DNS)

If you use Cloudflare for DNS (free):

1. Go to Cloudflare Dashboard → DNS → Records
2. Add these records:

| Type | Name | Content | Proxy Status | TTL |
|------|------|---------|--------------|-----|
| CNAME | @ | cname.vercel-dns.com | Proxied | Auto |
| A | cms | `<your-oracle-cloud-ip>` | Proxied | Auto |

**Benefits of Cloudflare:**
- Free SSL certificates for both
- DDoS protection
- Caching for better performance
- Analytics

### Option 2: Direct DNS (Your Domain Registrar)

If using your registrar's DNS (GoDaddy, Namecheap, etc.):

1. Go to DNS management
2. Add these records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | `<vercel-ip-from-vercel-dashboard>` | 600 |
| A | cms | `<your-oracle-cloud-ip>` | 600 |

**Get Vercel IP:**
- Go to Vercel dashboard → Your project → Settings → Domains
- Add your domain, Vercel will provide IP address

---

## Vercel Configuration

### Step 1: Add Domain to Vercel

1. Go to your Vercel project
2. Settings → Domains
3. Add domain: `yourdomain.com`
4. Add domain: `www.yourdomain.com` (optional redirect)
5. Vercel will provide DNS instructions

### Step 2: Configure Environment Variables

In Vercel, add these environment variables:

```env
NEXT_PUBLIC_API_URL=https://cms.yourdomain.com/api
# Or whatever your frontend framework uses
```

This tells your frontend where to fetch data from.

---

## Oracle Cloud / CMS Configuration

### Step 1: Update .env File

On your Oracle Cloud VM, update your `.env`:

```env
HOST=0.0.0.0
PORT=1337

# Use your subdomain
APP_URL=https://cms.yourdomain.com

# Your other secrets...
APP_KEYS="..."
API_TOKEN_SALT="..."
# etc.
```

### Step 2: Update Nginx Configuration

Edit `/etc/nginx/sites-available/strapi`:

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name cms.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

# Main HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    # Update with your subdomain
    server_name cms.yourdomain.com;

    # SSL certificates (Let's Encrypt will add these paths)
    ssl_certificate /etc/letsencrypt/live/cms.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/cms.yourdomain.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # CORS headers for API requests from your frontend
    add_header Access-Control-Allow-Origin "https://yourdomain.com" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
    add_header Access-Control-Allow-Credentials "true" always;

    # Logging
    access_log /var/log/nginx/strapi-access.log;
    error_log /var/log/nginx/strapi-error.log;

    # Client upload size
    client_max_body_size 100M;

    # Proxy to Strapi
    location / {
        proxy_pass http://127.0.0.1:1337;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Handle OPTIONS preflight requests
    location @cors {
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://yourdomain.com";
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, Authorization";
            add_header Access-Control-Max-Age 86400;
            add_header Content-Type "text/plain charset=UTF-8";
            add_header Content-Length 0;
            return 204;
        }
    }
}
```

### Step 3: Get SSL Certificate for Subdomain

```bash
# Stop nginx temporarily
sudo systemctl stop nginx

# Get certificate for subdomain
sudo certbot certonly --standalone -d cms.yourdomain.com

# Start nginx
sudo systemctl start nginx

# Or use nginx plugin (if nginx is already running)
sudo certbot --nginx -d cms.yourdomain.com
```

### Step 4: Configure Strapi CORS

Edit your Strapi middleware config if needed:

`config/middlewares.js` (or create if doesn't exist):

```javascript
module.exports = [
  'strapi::errors',
  {
    name: 'strapi::security',
    config: {
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'connect-src': ["'self'", 'https:'],
          'img-src': ["'self'", 'data:', 'blob:', 'https://yourdomain.com'],
          'media-src': ["'self'", 'data:', 'blob:', 'https://yourdomain.com'],
          upgradeInsecureRequests: null,
        },
      },
    },
  },
  {
    name: 'strapi::cors',
    config: {
      enabled: true,
      origin: ['https://yourdomain.com', 'https://www.yourdomain.com'],
      credentials: true,
    },
  },
  'strapi::poweredBy',
  'strapi::logger',
  'strapi::query',
  'strapi::body',
  'strapi::session',
  'strapi::favicon',
  'strapi::public',
];
```

---

## Testing the Setup

### 1. Test DNS Propagation

```bash
# Test main domain
nslookup yourdomain.com

# Test CMS subdomain
nslookup cms.yourdomain.com

# Or use online tools
# https://www.whatsmydns.net/
```

### 2. Test Frontend (Vercel)

Visit: `https://yourdomain.com`
- Should show your Vercel-deployed frontend
- Should have valid SSL

### 3. Test CMS Admin

Visit: `https://cms.yourdomain.com/admin`
- Should show Strapi admin login
- Should have valid SSL

### 4. Test API Endpoint

```bash
# Test from command line
curl https://cms.yourdomain.com/api

# Should return Strapi API response
```

### 5. Test Frontend → API Communication

1. Open your frontend (`yourdomain.com`)
2. Open browser DevTools → Network tab
3. Look for requests to `cms.yourdomain.com/api`
4. Verify they succeed (200 status)
5. Check for CORS errors (should be none)

---

## Common Issues & Solutions

### Issue: "DNS_PROBE_FINISHED_NXDOMAIN" for cms.yourdomain.com

**Solution:**
- DNS not propagated yet (wait 5-60 minutes)
- Check DNS records are correct
- Try flushing DNS cache: `ipconfig /flushdns` (Windows) or `sudo dscacheutil -flushcache` (Mac)

### Issue: SSL Certificate Error

**Solution:**
```bash
# Verify nginx config
sudo nginx -t

# Check certificate files exist
sudo ls -la /etc/letsencrypt/live/cms.yourdomain.com/

# Re-run certbot if needed
sudo certbot --nginx -d cms.yourdomain.com
```

### Issue: CORS Errors When Frontend Calls API

**Solution:**
- Verify CORS config in `config/middlewares.js`
- Check nginx headers for `Access-Control-Allow-Origin`
- Ensure origin matches exactly (https vs http, www vs non-www)
- Restart Strapi: `pm2 restart strapi-cms`

### Issue: 502 Bad Gateway

**Solution:**
```bash
# Check Strapi is running
pm2 status

# Check logs
pm2 logs strapi-cms

# Restart if needed
pm2 restart strapi-cms
```

### Issue: Admin Panel Redirects to Wrong URL

**Solution:**
- Update `APP_URL` in `.env` to `https://cms.yourdomain.com`
- Rebuild and restart:
```bash
cd ~/strapi-cms
npm run build
pm2 restart strapi-cms
```

---

## Frontend Integration Examples

### Next.js

```javascript
// .env.local or Vercel environment variables
NEXT_PUBLIC_STRAPI_API_URL=https://cms.yourdomain.com/api

// lib/strapi.js
export async function fetchAPI(endpoint) {
  const res = await fetch(
    `${process.env.NEXT_PUBLIC_STRAPI_API_URL}${endpoint}`
  )
  return res.json()
}

// Usage
const posts = await fetchAPI('/posts')
```

### React / Vite

```javascript
// .env
VITE_API_URL=https://cms.yourdomain.com/api

// api.js
const API_URL = import.meta.env.VITE_API_URL

export async function getPosts() {
  const response = await fetch(`${API_URL}/posts`)
  return response.json()
}
```

### Vanilla JavaScript

```javascript
const API_URL = 'https://cms.yourdomain.com/api'

async function fetchPosts() {
  const response = await fetch(`${API_URL}/posts`)
  const data = await response.json()
  return data
}
```

---

## Cost Breakdown

| Service | Cost | What For |
|---------|------|----------|
| **Domain** | $10-15/year | `yourdomain.com` (includes unlimited subdomains) |
| **Vercel** | $0/month | Frontend hosting (free tier) |
| **Oracle Cloud** | $0/month | CMS hosting (free tier) |
| **SSL Certs** | $0/month | Let's Encrypt (free) |
| **Total** | ~$1/month | Just the domain! |

**Optional upgrades:**
- Cloudflare (DNS + CDN): $0/month (free)
- Vercel Pro: $20/month (if you need more)
- Hetzner VPS instead of Oracle: +$4.50/month (more reliable)

---

## Architecture Diagram

```
User Browser
    │
    ├─────────────────────────┬─────────────────────────┐
    │                         │                         │
    ▼                         ▼                         ▼
yourdomain.com         cms.yourdomain.com     cms.yourdomain.com/api
    │                         │                         │
    │ (HTTPS)                 │ (HTTPS)                 │ (HTTPS)
    ▼                         ▼                         ▼
┌─────────┐             ┌─────────┐             ┌─────────┐
│ Vercel  │             │  Nginx  │             │  Nginx  │
│Frontend │             │ (proxy) │             │ (proxy) │
└─────────┘             └────┬────┘             └────┬────┘
                             │                       │
                             ▼                       ▼
                        ┌─────────────────────────────┐
                        │   Strapi CMS (Port 1337)   │
                        │   Oracle Cloud VM           │
                        │   - Admin Panel             │
                        │   - API Endpoints           │
                        └─────────────────────────────┘
```

---

## Security Best Practices

1. **Always use HTTPS** for both frontend and CMS
2. **Configure CORS properly** - only allow your frontend domain
3. **Use API tokens** in Strapi for frontend to authenticate API requests
4. **Keep admin panel restricted** - consider IP whitelisting for `/admin`
5. **Regular backups** - see MIGRATION.md for backup scripts

---

## Quick Reference

### Access Points

| What | URL | Where |
|------|-----|-------|
| **Frontend** | https://yourdomain.com | Vercel |
| **CMS Admin** | https://cms.yourdomain.com/admin | Oracle Cloud |
| **API** | https://cms.yourdomain.com/api | Oracle Cloud |
| **Media** | https://cms.yourdomain.com/uploads/* | Oracle Cloud |

### Configuration Files

| What | Location |
|------|----------|
| **Frontend API URL** | Vercel environment variables |
| **CMS URL Config** | `~/strapi-cms/.env` → `APP_URL` |
| **Nginx Config** | `/etc/nginx/sites-available/strapi` |
| **CORS Config** | `~/strapi-cms/config/middlewares.js` |

---

*Last updated: 2025-11-03*
