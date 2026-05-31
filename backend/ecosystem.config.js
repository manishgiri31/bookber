module.exports = {
  apps: [
    {
      name: "bookber-backend",
      script: "./dist/index.js",
      instances: process.env.NODE_ENV === "production" ? "max" : 1,
      exec_mode: process.env.NODE_ENV === "production" ? "cluster" : "fork",
      autorestart: true,
      watch: process.env.NODE_ENV !== "production",
      max_memory_restart: "1G",
      env: {
        NODE_ENV: "development",
        PORT: 3000
      },
      env_production: {
        NODE_ENV: "production",
        PORT: 3000
      },
      error_file: "./logs/pm2-error.log",
      out_file: "./logs/pm2-out.log",
      log_date_format: "YYYY-MM-DD HH:mm:ss Z",
      merge_logs: true,
      time: true,
      min_uptime: "10s",
      max_restarts: 10,
      restart_delay: 4000,
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000,
      shutdown_with_message: true,
      graceful_shutdown: {
        signals: ["SIGINT", "SIGTERM"],
        timeout: 30000
      }
    }
  ]
};
