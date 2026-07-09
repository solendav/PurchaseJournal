const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const compression = require("compression");
const { env } = require("../config/env");

const helmetMiddleware = helmet({
  contentSecurityPolicy: env.isProduction ? undefined : false,
  crossOriginEmbedderPolicy: false,
});

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: env.isDevelopment ? 2000 : 300,
  message: { success: false, error: "Too many requests" },
  standardHeaders: true,
  legacyHeaders: false,
  skip: () => env.isDevelopment,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: env.isDevelopment ? 200 : 20,
  message: { success: false, error: "Too many authentication attempts. Try again later." },
  standardHeaders: true,
  legacyHeaders: false,
});

const compressionMiddleware = compression();

module.exports = { helmetMiddleware, apiLimiter, authLimiter, compressionMiddleware };
