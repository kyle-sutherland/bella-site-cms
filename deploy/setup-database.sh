#!/bin/bash
# PostgreSQL Database Setup Script
# Run this on your Oracle Cloud VM after PostgreSQL is installed

set -e

echo "=================================="
echo "PostgreSQL Database Setup"
echo "=================================="
echo ""

# Prompt for database details
read -p "Enter database name [strapi]: " DB_NAME
DB_NAME=${DB_NAME:-strapi}

read -p "Enter database user [strapi]: " DB_USER
DB_USER=${DB_USER:-strapi}

read -sp "Enter database password: " DB_PASSWORD
echo ""

if [ -z "$DB_PASSWORD" ]; then
    echo "Error: Password cannot be empty"
    exit 1
fi

# Create database and user
echo "Creating database and user..."
sudo -u postgres psql <<EOF
-- Create database
CREATE DATABASE $DB_NAME;

-- Create user with encrypted password
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

-- Grant schema privileges (PostgreSQL 15+)
\c $DB_NAME
GRANT ALL ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;

\q
EOF

echo ""
echo "✅ Database setup complete!"
echo ""
echo "Database credentials:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: $DB_NAME"
echo "  Username: $DB_USER"
echo "  Password: ********"
echo ""
echo "Add these to your .env file:"
echo "DATABASE_CLIENT=postgres"
echo "DATABASE_HOST=localhost"
echo "DATABASE_PORT=5432"
echo "DATABASE_NAME=$DB_NAME"
echo "DATABASE_USERNAME=$DB_USER"
echo "DATABASE_PASSWORD=$DB_PASSWORD"
echo ""

# Optional: Configure PostgreSQL for better performance
read -p "Do you want to optimize PostgreSQL settings for Strapi? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Optimizing PostgreSQL configuration..."

    # Backup original config
    sudo cp /etc/postgresql/*/main/postgresql.conf /etc/postgresql/*/main/postgresql.conf.backup

    # Basic optimizations for a small VPS
    sudo -u postgres psql -c "ALTER SYSTEM SET shared_buffers = '256MB';"
    sudo -u postgres psql -c "ALTER SYSTEM SET effective_cache_size = '1GB';"
    sudo -u postgres psql -c "ALTER SYSTEM SET maintenance_work_mem = '64MB';"
    sudo -u postgres psql -c "ALTER SYSTEM SET checkpoint_completion_target = 0.9;"
    sudo -u postgres psql -c "ALTER SYSTEM SET wal_buffers = '16MB';"
    sudo -u postgres psql -c "ALTER SYSTEM SET default_statistics_target = 100;"
    sudo -u postgres psql -c "ALTER SYSTEM SET random_page_cost = 1.1;"
    sudo -u postgres psql -c "ALTER SYSTEM SET effective_io_concurrency = 200;"
    sudo -u postgres psql -c "ALTER SYSTEM SET work_mem = '4MB';"
    sudo -u postgres psql -c "ALTER SYSTEM SET min_wal_size = '1GB';"
    sudo -u postgres psql -c "ALTER SYSTEM SET max_wal_size = '4GB';"

    # Restart PostgreSQL
    sudo systemctl restart postgresql

    echo "✅ PostgreSQL optimized!"
fi

echo ""
echo "Setup complete! You can now configure Strapi to use this database."
