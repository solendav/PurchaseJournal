const { env } = require("./config/env");
const { logger } = require("./utils/logger");
const { isServerless } = require("./utils/serverless");

function validateProductionEnv() {
  if (!env.isProduction) return;

  if (!env.jwtSecret || env.jwtSecret.length < 32) {
    throw new Error("JWT_SECRET must be at least 32 characters in production");
  }
  if (!env.database) {
    throw new Error(
      "Database configuration is required in production (set DATABASE_URL on Vercel)"
    );
  }
}

function logStartupWarnings() {
  if (!env.database && !env.isProduction) {
    logger.warn("Database not configured — some features may not work");
  }

  if (
    isServerless() &&
    (!env.cloudinaryCloudName || !env.cloudinaryApiKey || !env.cloudinaryApiSecret)
  ) {
    logger.warn(
      "Cloudinary not configured — receipt uploads will fail on Vercel until CLOUDINARY_* env vars are set"
    );
  }
}

module.exports = { validateProductionEnv, logStartupWarnings };
