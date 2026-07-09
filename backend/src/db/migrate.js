const { Pool } = require("pg");
const fs = require("fs");
const path = require("path");
const { env } = require("../config/env");
const { logger } = require("../utils/logger");

async function runMigrations() {
  if (!env.database) {
    logger.error("Database not configured");
    process.exit(1);
  }

  const pool = new Pool({
    ...env.database,
    ssl: env.pgSsl ? { rejectUnauthorized: false } : false,
  });

  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) UNIQUE NOT NULL,
        applied_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    const migrationsDir = path.join(__dirname, "migrations");
    if (!fs.existsSync(migrationsDir)) {
      logger.info("No migrations directory");
      return;
    }

    const files = fs.readdirSync(migrationsDir).filter((f) => f.endsWith(".sql")).sort();

    for (const file of files) {
      const existing = await pool.query("SELECT id FROM migrations WHERE filename = $1", [file]);
      if (existing.rows.length > 0) {
        logger.info(`Migration already applied: ${file}`);
        continue;
      }

      const sql = fs.readFileSync(path.join(migrationsDir, file), "utf8");
      await pool.query(sql);
      await pool.query("INSERT INTO migrations (filename) VALUES ($1)", [file]);
      logger.info(`Applied migration: ${file}`);
    }
  } catch (err) {
    logger.error({ err }, "Migration failed");
    if (require.main === module) {
      process.exit(1);
    }
    throw err;
  } finally {
    await pool.end();
  }
}

if (require.main === module) {
  runMigrations().then(() => process.exit(0));
}

module.exports = { runMigrations };
