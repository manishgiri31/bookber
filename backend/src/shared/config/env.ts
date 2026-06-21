import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  // App Configuration
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  HOST: z.string().default("0.0.0.0"),
  PORT: z.coerce.number().int().positive().default(3000),
  APP_NAME: z.string().default("BookBer"),
  APP_URL: z.string().default("http://localhost:3000"),

  // Database Configuration
  DATABASE_URL: z.string().min(1),
  DATABASE_POOL_SIZE: z.coerce.number().int().positive().default(10),
  DATABASE_SSL: z.coerce.boolean().default(false),

  // Redis Configuration
  REDIS_URL: z.string().min(1),
  REDIS_HOST: z.string().default("localhost"),
  REDIS_PORT: z.coerce.number().int().positive().default(6379),
  REDIS_USERNAME: z.string().optional(),
  REDIS_PASSWORD: z.string().optional(),
  REDIS_DB: z.coerce.number().int().min(0).default(0),

  // JWT Configuration
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_ACCESS_TTL: z.string().default("15m"),
  JWT_REFRESH_TTL: z.string().default("30d"),

  // Cookie Configuration
  COOKIE_DOMAIN: z.string().optional(),
  COOKIE_SECURE: z.coerce.boolean().default(true),
  COOKIE_SAME_SITE: z.enum(["lax", "strict", "none"]).default("lax"),
  ACCESS_TOKEN_COOKIE_NAME: z.string().default("bookber_at"),
  REFRESH_TOKEN_COOKIE_NAME: z.string().default("bookber_rt"),

  // CORS Configuration
  CORS_ORIGIN: z.string().min(1),

  // Socket.io Configuration
  SOCKET_CORS_ORIGIN: z.string().default("http://localhost:3000"),
  SOCKET_NAMESPACE: z.string().default("/realtime"),
  SOCKET_HEARTBEAT_MS: z.coerce.number().int().positive().default(25000),
  SOCKET_STALE_MS: z.coerce.number().int().positive().default(90000),
  SOCKET_STALE_SWEEP_MS: z.coerce.number().int().positive().default(30000),
  SOCKET_EVENT_LOG_MAX: z.coerce.number().int().positive().default(500),
  SOCKET_SYNC_DEFAULT_LIMIT: z.coerce.number().int().positive().default(100),

  // Firebase/FCM Configuration
  FCM_PROJECT_ID: z.string().optional(),
  FCM_CLIENT_EMAIL: z.string().optional(),
  FCM_PRIVATE_KEY: z.string().optional(),
  FCM_SERVER_KEY: z.string().optional(),

  // Maps Configuration
  MAPBOX_ACCESS_TOKEN: z.string().optional(),
  GOOGLE_MAPS_API_KEY: z.string().optional(),
  GEOCODING_PROVIDER: z.string().default("openstreetmaps"),

  // Uploads Configuration
  MAX_FILE_SIZE: z.coerce.number().int().positive().default(5242880),
  UPLOAD_PATH: z.string().default("./uploads"),
  ALLOWED_IMAGE_TYPES: z.string().default("image/jpeg,image/png,image/webp"),

  // AWS S3 Configuration
  S3_BUCKET: z.string().optional(),
  AWS_REGION: z.string().default("us-east-1"),
  AWS_ACCESS_KEY_ID: z.string().optional(),
  AWS_SECRET_ACCESS_KEY: z.string().optional(),

  // Rate Limiting Configuration
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(60000),
  RATE_LIMIT_MAX_REQUESTS: z.coerce.number().int().positive().default(100),

  // Queue Engine Configuration
  QUEUE_LOCK_TTL_MS: z.coerce.number().int().positive().default(30000),
  QUEUE_ASSIGNMENT_TIMEOUT_MS: z.coerce.number().int().positive().default(30000),
  QUEUE_RECOVERY_INTERVAL_MS: z.coerce.number().int().positive().default(60000),
  RECOVERY_WORKERS_ENABLED: z.coerce.boolean().default(true),
  QUEUE_MAX_SIZE: z.coerce.number().int().positive().default(1000),

  // Wait Time Engine Configuration
  WAIT_TIME_RECALC_INTERVAL_MS: z.coerce.number().int().positive().default(300000),
  DEFAULT_SERVICE_DURATION: z.coerce.number().int().positive().default(30),
  QUEUE_REBALANCE_THRESHOLD: z.coerce.number().int().positive().default(5),

  // Recovery Workers Configuration
  STALE_SERVICE_TIMEOUT_MINUTES: z.coerce.number().int().positive().default(30),
  ORPHANED_CHAIR_TIMEOUT_MINUTES: z.coerce.number().int().positive().default(60),
  REDIS_REPAIR_INTERVAL_MS: z.coerce.number().int().positive().default(300000),
  DEAD_SOCKET_CLEANUP_INTERVAL_MS: z.coerce.number().int().positive().default(300000),
  CHAIR_RECOVERY_INTERVAL_MS: z.coerce.number().int().positive().default(300000),

  // OTP Configuration
  OTP_TTL_SECONDS: z.coerce.number().int().positive().default(300),

  // Password Configuration
  PASSWORD_BCRYPT_ROUNDS: z.coerce.number().int().min(10).max(15).default(12),

  // Logging Configuration
  LOG_LEVEL: z.enum(["fatal", "error", "warn", "info", "debug", "trace", "silent"]).default("info"),
  LOG_PRETTY_PRINT: z.coerce.boolean().default(true),

  // Monitoring Configuration
  PROMETHEUS_ENABLED: z.coerce.boolean().default(false),
  PROMETHEUS_PORT: z.coerce.number().int().positive().default(9090),
  OTEL_ENABLED: z.coerce.boolean().default(false),
  OTEL_SERVICE_NAME: z.string().default("bookber-backend"),
  OTEL_SERVICE_VERSION: z.string().default("1.0.0"),
  OTEL_DEPLOYMENT_ENVIRONMENT: z.string().default("production"),
  OTEL_EXPORTER_OTLP_ENDPOINT: z.string().default("http://localhost:4317"),
  OTEL_EXPORTER_OTLP_PROTOCOL: z.string().default("grpc"),

  // Scaling Configuration
  SCALING_STRATEGY: z.enum(["horizontal", "vertical"]).default("horizontal"),

  // Graceful Shutdown Configuration
  SHUTDOWN_TIMEOUT_MS: z.coerce.number().int().positive().default(30000),
  SHUTDOWN_DRAIN_TIMEOUT_MS: z.coerce.number().int().positive().default(10000),

  // Redis Pool Configuration
  REDIS_POOL_MIN_CONNECTIONS: z.coerce.number().int().positive().default(5),
  REDIS_POOL_MAX_CONNECTIONS: z.coerce.number().int().positive().default(50),
  REDIS_CONNECTION_TIMEOUT_MS: z.coerce.number().int().positive().default(5000),
  REDIS_IDLE_TIMEOUT_MS: z.coerce.number().int().positive().default(30000),
  REDIS_MAX_LIFETIME_MS: z.coerce.number().int().positive().default(3600000),
  REDIS_HEALTH_CHECK_INTERVAL_MS: z.coerce.number().int().positive().default(5000),

  // Redis Health Check Configuration
  REDIS_MEMORY_CHECK_INTERVAL_MS: z.coerce.number().int().positive().default(30000),
  REDIS_LATENCY_CHECK_INTERVAL_MS: z.coerce.number().int().positive().default(5000),
  REDIS_REPLICATION_CHECK_INTERVAL_MS: z.coerce.number().int().positive().default(10000),
  REDIS_MEMORY_THRESHOLD: z.coerce.number().int().positive().default(80),
  REDIS_LATENCY_THRESHOLD_MS: z.coerce.number().int().positive().default(1000),
  REDIS_REPLICATION_LAG_THRESHOLD_MS: z.coerce.number().int().positive().default(30000),

  // Redis Failover Configuration
  REDIS_FAILOVER_DETECTION_INTERVAL_MS: z.coerce.number().int().positive().default(10000),
  REDIS_NODE_UNRESPONSIVE_THRESHOLD_MS: z.coerce.number().int().positive().default(30000),
  REDIS_AUTO_RECONNECT: z.coerce.boolean().default(true),
  REDIS_RECONNECT_DELAY_MS: z.coerce.number().int().positive().default(5000),
  REDIS_MAX_RECONNECT_ATTEMPTS: z.coerce.number().int().positive().default(10),

  // Redis Cache Rebuild Configuration
  REDIS_REBUILD_ON_HIT_RATE_THRESHOLD: z.coerce.number().min(0).max(1).default(0.8),
  REDIS_REBUILD_ON_MEMORY_PRESSURE: z.coerce.number().min(0).max(1).default(0.8),
  REDIS_REBUILD_ENABLE_AUTO: z.coerce.boolean().default(true),
  REDIS_REBUILD_INTERVAL_MS: z.coerce.number().int().positive().default(300000),
  REDIS_REBUILD_BATCH_SIZE: z.coerce.number().int().positive().default(100),
  REDIS_REBUILD_MAX_TIME_MS: z.coerce.number().int().positive().default(60000),

  // Redis PubSub Optimizer Configuration
  REDIS_PUBSUB_ENABLE_BATCHING: z.coerce.boolean().default(true),
  REDIS_PUBSUB_BATCH_SIZE: z.coerce.number().int().positive().default(100),
  REDIS_PUBSUB_BATCH_TIMEOUT_MS: z.coerce.number().int().positive().default(100),
  REDIS_PUBSUB_ENABLE_COMPRESSION: z.coerce.boolean().default(true),
  REDIS_PUBSUB_COMPRESSION_THRESHOLD: z.coerce.number().int().positive().default(1024),
  REDIS_PUBSUB_ENABLE_DEDUPLICATION: z.coerce.boolean().default(true),
  REDIS_PUBSUB_DEDUPLICATION_TTL_MS: z.coerce.number().int().positive().default(60000),

  // External Monitoring Services (Optional)
  SENTRY_DSN: z.string().optional(),
  DATADOG_API_KEY: z.string().optional(),
  NEW_RELIC_LICENSE_KEY: z.string().optional(),
});

export const env = envSchema.parse(process.env);
export type Env = z.infer<typeof envSchema>;
export { envSchema };
