const dns = require("node:dns");
const { Pool } = require("pg");
const { env } = require("../config/env");
const { logger } = require("../utils/logger");

if (typeof dns.setDefaultResultOrder === "function") {
  dns.setDefaultResultOrder("ipv4first");
}

let pool = null;

if (env.database) {
  pool = new Pool({
    ...env.database,
    ssl: env.pgSsl ? { rejectUnauthorized: false } : false,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  });

  pool.on("error", (err) => {
    logger.error({ err }, "Unexpected error on idle client");
  });
} else {
  logger.warn("Database not configured");
}

module.exports = { pool };
