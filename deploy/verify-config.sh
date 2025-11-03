#!/bin/bash
# Configuration Verification Script
# Run this before deployment to verify all configuration files

set -e

echo "=================================="
echo "Configuration Verification"
echo "=================================="
echo ""

ERRORS=0
WARNINGS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check 1: Verify required files exist
echo "[1/8] Checking required files..."

if [ -f "package.json" ]; then
    print_success "package.json exists"
else
    print_error "package.json not found"
fi

if [ -f ".env.example" ]; then
    print_success ".env.example exists"
else
    print_error ".env.example not found"
fi

if [ -f "Dockerfile" ]; then
    print_success "Dockerfile exists"
else
    print_warning "Dockerfile not found (optional)"
fi

if [ -f "ecosystem.config.js" ]; then
    print_success "ecosystem.config.js exists"
else
    print_error "ecosystem.config.js not found"
fi

echo ""

# Check 2: Verify deployment scripts
echo "[2/8] Checking deployment scripts..."

if [ -f "deploy/setup-server.sh" ]; then
    print_success "setup-server.sh exists"
    if [ -x "deploy/setup-server.sh" ]; then
        print_success "setup-server.sh is executable"
    else
        print_warning "setup-server.sh is not executable (run: chmod +x deploy/setup-server.sh)"
    fi
else
    print_error "deploy/setup-server.sh not found"
fi

if [ -f "deploy/setup-database.sh" ]; then
    print_success "setup-database.sh exists"
else
    print_error "deploy/setup-database.sh not found"
fi

if [ -f "deploy/generate-secrets.js" ]; then
    print_success "generate-secrets.js exists"
else
    print_error "deploy/generate-secrets.js not found"
fi

if [ -f "deploy/nginx.conf" ]; then
    print_success "nginx.conf exists"
else
    print_error "deploy/nginx.conf not found"
fi

echo ""

# Check 3: Verify Node.js version
echo "[3/8] Checking Node.js version..."

if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    print_success "Node.js installed: $NODE_VERSION"

    # Check if version is >= 18
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_MAJOR" -ge 18 ]; then
        print_success "Node.js version is compatible (>=18)"
    else
        print_error "Node.js version is too old (need >=18, have $NODE_VERSION)"
    fi
else
    print_warning "Node.js not installed (required for deployment)"
fi

echo ""

# Check 4: Verify npm packages
echo "[4/8] Checking package.json configuration..."

if [ -f "package.json" ]; then
    # Check for required scripts
    if grep -q '"build"' package.json; then
        print_success "Build script defined"
    else
        print_error "Build script not found in package.json"
    fi

    if grep -q '"start"' package.json; then
        print_success "Start script defined"
    else
        print_error "Start script not found in package.json"
    fi

    # Check for Strapi
    if grep -q '@strapi/strapi' package.json; then
        print_success "Strapi dependency found"
    else
        print_error "Strapi dependency not found"
    fi
fi

echo ""

# Check 5: Verify .env.example
echo "[5/8] Checking .env.example..."

if [ -f ".env.example" ]; then
    # Check for required variables
    required_vars=("HOST" "PORT" "APP_KEYS" "API_TOKEN_SALT" "ADMIN_JWT_SECRET" "JWT_SECRET")

    for var in "${required_vars[@]}"; do
        if grep -q "^$var=" .env.example; then
            print_success "$var defined"
        elif grep -q "^# $var=" .env.example; then
            print_warning "$var is commented out"
        else
            print_error "$var not found"
        fi
    done
fi

echo ""

# Check 6: Verify ecosystem.config.js
echo "[6/8] Checking PM2 configuration..."

if [ -f "ecosystem.config.js" ]; then
    if grep -q "module.exports" ecosystem.config.js; then
        print_success "Valid JavaScript module"
    else
        print_error "ecosystem.config.js doesn't export a module"
    fi

    if grep -q "apps:" ecosystem.config.js; then
        print_success "Apps array defined"
    else
        print_error "Apps array not found"
    fi

    if grep -q "name:" ecosystem.config.js; then
        print_success "App name defined"
    else
        print_error "App name not found"
    fi
fi

echo ""

# Check 7: Verify nginx config
echo "[7/8] Checking nginx configuration..."

if [ -f "deploy/nginx.conf" ]; then
    if grep -q "server {" deploy/nginx.conf; then
        print_success "Server block found"
    else
        print_error "Server block not found in nginx.conf"
    fi

    if grep -q "proxy_pass" deploy/nginx.conf; then
        print_success "Proxy configuration found"
    else
        print_error "Proxy configuration not found"
    fi

    if grep -q "yourdomain.com" deploy/nginx.conf; then
        print_warning "Domain placeholder still present (replace 'yourdomain.com' with your actual domain)"
    fi
fi

echo ""

# Check 8: Verify Dockerfile (if exists)
echo "[8/8] Checking Dockerfile..."

if [ -f "Dockerfile" ]; then
    if grep -q "FROM" Dockerfile; then
        print_success "Base image defined"
    else
        print_error "No base image found in Dockerfile"
    fi

    if grep -q "npm" Dockerfile; then
        print_success "npm commands found"
    else
        print_warning "No npm commands found in Dockerfile"
    fi

    if grep -q "EXPOSE" Dockerfile; then
        print_success "Port exposed"
    else
        print_warning "No port exposed in Dockerfile"
    fi
else
    print_warning "Dockerfile not found (optional)"
fi

echo ""
echo "=================================="
echo "Verification Complete"
echo "=================================="
echo ""
echo "Summary:"
echo "  Errors: $ERRORS"
echo "  Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Configuration looks good!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review DEPLOYMENT.md for deployment instructions"
    echo "  2. Generate production secrets: node deploy/generate-secrets.js"
    echo "  3. Deploy to your chosen platform"
    exit 0
else
    echo -e "${RED}✗ Configuration has errors that need to be fixed${NC}"
    echo ""
    echo "Please fix the errors above before deploying."
    exit 1
fi
