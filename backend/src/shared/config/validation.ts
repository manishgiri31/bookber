import { ZodError } from "zod";
import { env, envSchema, type Env } from "./env.js";

export interface ValidationResult {
  success: boolean;
  errors: string[];
  warnings: string[];
}

export function validateEnv(): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  try {
    // Parse environment variables
    envSchema.parse(process.env);
  } catch (error) {
    if (error instanceof ZodError) {
      for (const issue of error.issues) {
        errors.push(`${issue.path.join(".")}: ${issue.message}`);
      }
    } else {
      errors.push(`Unknown validation error: ${error}`);
    }
    return { success: false, errors, warnings };
  }

  // Additional validation checks
  const requiredInProduction: (keyof Env)[] = [
    "DATABASE_URL",
    "REDIS_URL",
    "JWT_ACCESS_SECRET",
    "JWT_REFRESH_SECRET",
    "CORS_ORIGIN",
  ];

  if (env.NODE_ENV === "production") {
    for (const key of requiredInProduction) {
      if (!env[key]) {
        errors.push(`${key} is required in production`);
      }
    }

    // Production-specific checks
    if (env.COOKIE_SECURE !== true) {
      warnings.push("COOKIE_SECURE should be true in production");
    }

    if (env.JWT_ACCESS_SECRET === "replace-with-long-random-secret-min-32-chars") {
      errors.push("JWT_ACCESS_SECRET must be changed from default value");
    }

    if (env.JWT_REFRESH_SECRET === "replace-with-long-random-secret-min-32-chars") {
      errors.push("JWT_REFRESH_SECRET must be changed from default value");
    }

    if (env.LOG_LEVEL === "debug" || env.LOG_LEVEL === "trace") {
      warnings.push("LOG_LEVEL should be info or higher in production");
    }

    if (env.LOG_PRETTY_PRINT === true) {
      warnings.push("LOG_PRETTY_PRINT should be false in production");
    }
  }

  // Optional service warnings
  if (env.FCM_PROJECT_ID && (!env.FCM_CLIENT_EMAIL || !env.FCM_PRIVATE_KEY)) {
    warnings.push("FCM_PROJECT_ID is set but FCM_CLIENT_EMAIL or FCM_PRIVATE_KEY is missing");
  }

  if (env.S3_BUCKET && (!env.AWS_ACCESS_KEY_ID || !env.AWS_SECRET_ACCESS_KEY)) {
    warnings.push("S3_BUCKET is set but AWS credentials are missing");
  }

  if (env.OTEL_ENABLED && !env.OTEL_EXPORTER_OTLP_ENDPOINT) {
    warnings.push("OTEL_ENABLED is true but OTEL_EXPORTER_OTLP_ENDPOINT is not set");
  }

  if (env.PROMETHEUS_ENABLED && env.PROMETHEUS_PORT === env.PORT) {
    errors.push("PROMETHEUS_PORT cannot be the same as PORT");
  }

  return {
    success: errors.length === 0,
    errors,
    warnings,
  };
}

export function printValidationResult(result: ValidationResult): void {
  if (result.errors.length > 0) {
    console.error("Environment Validation Failed:");
    for (const error of result.errors) {
      console.error(`  - ${error}`);
    }
  }

  if (result.warnings.length > 0) {
    console.warn("Environment Validation Warnings:");
    for (const warning of result.warnings) {
      console.warn(`  - ${warning}`);
    }
  }

  if (result.success) {
    console.log("Environment Validation Passed");
  }
}

export function validateEnvOnStartup(): void {
  const result = validateEnv();
  printValidationResult(result);

  if (!result.success) {
    throw new Error("Environment validation failed. Please fix the errors above.");
  }
}
