/**
 * PM2 Ecosystem Configuration for Strapi CMS
 *
 * Start: pm2 start ecosystem.config.js
 * Stop: pm2 stop strapi-cms
 * Restart: pm2 restart strapi-cms
 * Logs: pm2 logs strapi-cms
 * Monitor: pm2 monit
 *
 * Save configuration: pm2 save
 * Setup startup script: pm2 startup (then run the command it outputs)
 */

module.exports = {
  apps: [
    {
      name: 'strapi-cms',
      script: 'npm',
      args: 'start',
      cwd: '/home/strapi/strapi-cms', // Update this path to your actual installation directory
      instances: 1,
      exec_mode: 'fork',

      // Environment variables (can also use .env file)
      env: {
        NODE_ENV: 'production',
        PORT: 1337,
        HOST: '0.0.0.0',
      },

      // Auto-restart settings
      autorestart: true,
      watch: false, // Don't watch files in production
      max_memory_restart: '1G', // Restart if memory exceeds 1GB

      // Restart strategy
      min_uptime: '10s', // Minimum uptime before considering app as stable
      max_restarts: 10, // Max number of restarts within 1 minute

      // Logging
      error_file: '/home/strapi/strapi-cms/logs/pm2-error.log',
      out_file: '/home/strapi/strapi-cms/logs/pm2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,

      // Advanced settings
      listen_timeout: 10000, // Time to wait before considering app as online
      kill_timeout: 5000, // Time to wait before force killing the app

      // Graceful shutdown
      shutdown_with_message: true,
    },
  ],
};
