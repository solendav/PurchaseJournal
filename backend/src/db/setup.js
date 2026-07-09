const { Pool } = require("pg");
const fs = require("fs");
const path = require("path");
const { env } = require("../config/env");
const { logger } = require("../utils/logger");
const { runMigrations } = require("./migrate");

function parseSchema(sqlContent) {
  const withoutComments = sqlContent.replace(/--.*$/gm, "");
  return withoutComments
    .split(";")
    .map((stmt) => stmt.trim())
    .filter((stmt) => stmt.length > 0);
}

async function applySchema(pool) {
  const schemaPath = path.join(__dirname, "schema.sql");
  const statements = parseSchema(fs.readFileSync(schemaPath, "utf8"));

  for (let i = 0; i < statements.length; i++) {
    const statement = statements[i];
    try {
      await pool.query(statement);
      logger.info(`Schema statement ${i + 1}/${statements.length} executed`);
    } catch (error) {
      if (error.message.includes("already exists")) {
        logger.warn(`Schema statement ${i + 1} skipped: already exists`);
      } else {
        throw error;
      }
    }
  }
}

async function setupSchema(options = {}) {
  const { clean = false, force = false } = options;

  if (!env.database) {
    logger.error("Database not configured");
    process.exit(1);
  }

  const pool = new Pool({
    ...env.database,
    ssl: env.pgSsl ? { rejectUnauthorized: false } : false,
  });

  try {
    await pool.query("SELECT NOW()");
    logger.info("Database connection successful");

    if (clean) {
      if (!force) {
        logger.error("Use --force with --clean to confirm destructive reset");
        process.exit(1);
      }
      await pool.query("DROP SCHEMA public CASCADE; CREATE SCHEMA public;");
      logger.info("Database reset complete");
    }

    await applySchema(pool);
    await pool.end();
    await runMigrations();
    logger.info("Schema setup completed");
  } catch (error) {
    logger.error({ err: error }, "Schema setup failed");
    process.exit(1);
  }
}

if (require.main === module) {
  const args = process.argv.slice(2);
  setupSchema({ clean: args.includes("--clean"), force: args.includes("--force") })
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = { setupSchema };
