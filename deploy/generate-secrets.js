#!/usr/bin/env node
/**
 * Generate secure secrets for Strapi production deployment
 * Run with: node deploy/generate-secrets.js
 */

const crypto = require('crypto');

console.log('================================');
console.log('Strapi Production Secrets');
console.log('================================\n');

// Generate random base64 string
function generateSecret(bytes = 32) {
  return crypto.randomBytes(bytes).toString('base64');
}

// Generate 4 app keys
function generateAppKeys() {
  return [
    generateSecret(),
    generateSecret(),
    generateSecret(),
    generateSecret()
  ].join(',');
}

console.log('Copy these values to your .env file:\n');
console.log('# Security Keys - Generated on ' + new Date().toISOString());
console.log(`APP_KEYS="${generateAppKeys()}"`);
console.log(`API_TOKEN_SALT=${generateSecret()}`);
console.log(`ADMIN_JWT_SECRET=${generateSecret()}`);
console.log(`TRANSFER_TOKEN_SALT=${generateSecret()}`);
console.log(`JWT_SECRET=${generateSecret()}`);
console.log('\n');

console.log('⚠️  IMPORTANT SECURITY NOTES:');
console.log('1. Store these secrets securely (use a password manager)');
console.log('2. Never commit these to version control');
console.log('3. Use different secrets for each environment');
console.log('4. Rotate secrets periodically for enhanced security');
console.log('5. Keep backups of these secrets in a secure location\n');

// Generate a sample database password
const dbPassword = crypto.randomBytes(24).toString('base64').replace(/[/+=]/g, '');
console.log('Suggested PostgreSQL password:');
console.log(`DATABASE_PASSWORD=${dbPassword}`);
console.log('\n');

console.log('Full .env template for production:');
console.log('-----------------------------------');
console.log(`HOST=0.0.0.0
PORT=1337
APP_URL=https://yourdomain.com

APP_KEYS="${generateAppKeys()}"
API_TOKEN_SALT=${generateSecret()}
ADMIN_JWT_SECRET=${generateSecret()}
TRANSFER_TOKEN_SALT=${generateSecret()}
JWT_SECRET=${generateSecret()}

DATABASE_CLIENT=postgres
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=strapi
DATABASE_USERNAME=strapi
DATABASE_PASSWORD=${dbPassword}
DATABASE_SSL=false

NODE_ENV=production
`);
