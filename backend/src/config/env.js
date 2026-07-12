const dotenv = require("dotenv");

dotenv.config();

function getEnv(name, fallback) {
  const v = process.env[name];
  if (v === undefined || v === "") return fallback;
  return v;
}

function getDatabaseConfig() {
  const databaseUrl = getEnv("DATABASE_URL", "");
  if (databaseUrl) {
    return { connectionString: databaseUrl };
  }

  const dbName = getEnv("DB_NAME", "");
  if (!dbName) return null;

  return {
    host: getEnv("DB_HOST", "localhost"),
    port: Number(getEnv("DB_PORT", "5435")),
    database: dbName,
    user: getEnv("DB_USER", "postgres"),
    password: getEnv("DB_PASSWORD", "postgres"),
  };
}

function shouldUsePgSsl(database) {
  if (getEnv("PG_SSL", "") === "true") return true;
  const url = database?.connectionString || "";
  return /supabase\.com|neon\.tech|sslmode=require/i.test(url);
}

const nodeEnv = getEnv("NODE_ENV", "development");
const database = getDatabaseConfig();

const env = {
  nodeEnv,
  isProduction: nodeEnv === "production",
  isDevelopment: nodeEnv === "development",
  port: Number(getEnv("PORT", "5003")),
  corsOrigins: getEnv("CORS_ORIGINS", "http://localhost:3000")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean),
  database,
  pgSsl: shouldUsePgSsl(database),
  jwtSecret: getEnv("JWT_SECRET", "dev-secret-change-me"),
  jwtExpiresIn: getEnv("JWT_EXPIRES_IN", "15m"),
  uploadDir: getEnv("UPLOAD_DIR", "uploads"),
  logLevel: getEnv("LOG_LEVEL", "info"),
  appPublicUrl: getEnv("APP_PUBLIC_URL", "http://localhost:5003"),
  requireEmailVerification: getEnv("REQUIRE_EMAIL_VERIFICATION", "true") === "true",
  smtpHost: getEnv("SMTP_HOST", ""),
  smtpPort: Number(getEnv("SMTP_PORT", "587")),
  smtpSecure: getEnv("SMTP_SECURE", "false") === "true",
  smtpUser: getEnv("SMTP_USER", ""),
  smtpPass: getEnv("SMTP_PASS", ""),
  smtpFrom: getEnv("SMTP_FROM", "Purchase Journal <noreply@localhost>"),
  uploadDir: getEnv("UPLOAD_DIR", "uploads"),
  cloudinaryCloudName: getEnv("CLOUDINARY_CLOUD_NAME", ""),
  cloudinaryApiKey: getEnv("CLOUDINARY_API_KEY", ""),
  cloudinaryApiSecret: getEnv("CLOUDINARY_API_SECRET", ""),
  cloudinaryFolder: getEnv("CLOUDINARY_FOLDER", "purchase-journal"),
};

module.exports = { env };
