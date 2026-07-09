const { pool } = require("./pool");
const { hashPassword } = require("../utils/password");
const { logger } = require("../utils/logger");

async function seed() {
  if (!pool) {
    logger.error("Database not configured");
    process.exit(1);
  }

  const email = "demo@purchasejournal.local";
  const existing = await pool.query("SELECT id FROM users WHERE email = $1", [email]);
  if (existing.rows.length > 0) {
    logger.info("Seed skipped: demo user already exists");
    await pool.end();
    return;
  }

  const passwordHash = await hashPassword("password123");
  const userResult = await pool.query(
    `INSERT INTO users (email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'Demo', 'User')
     RETURNING id`,
    [email, passwordHash]
  );
  const userId = userResult.rows[0].id;

  const supplierResult = await pool.query(
    `INSERT INTO suppliers (user_id, name, phone, notes, created_by)
     VALUES ($1, 'Corner Grocery', '+251911000000', 'Weekly restock', $1)
     RETURNING id`,
    [userId]
  );
  const supplierId = supplierResult.rows[0].id;

  const purchaseResult = await pool.query(
    `INSERT INTO purchases (user_id, supplier_id, purchase_date, amount_paid, notes, created_by, updated_by)
     VALUES ($1, $2, CURRENT_DATE, 0, 'Sample purchase', $1, $1)
     RETURNING id`,
    [userId, supplierId]
  );
  const purchaseId = purchaseResult.rows[0].id;

  await pool.query(
    `INSERT INTO purchase_items (purchase_id, description, quantity, unit_price, line_total, sort_order, created_by)
     VALUES
       ($1, 'Rice 25kg', 2, 150.00, 300.00, 0, $2),
       ($1, 'Cooking oil 5L', 1, 150.00, 150.00, 1, $2)`,
    [purchaseId, userId]
  );

  await pool.query(
    `INSERT INTO supplier_payments (user_id, supplier_id, amount, payment_date, notes, created_by)
     VALUES ($1, $2, 400.00, CURRENT_DATE, 'Partial settlement', $1)`,
    [userId, supplierId]
  );

  logger.info({ email, password: "password123" }, "Demo user seeded");
  await pool.end();
}

if (require.main === module) {
  seed()
    .then(() => process.exit(0))
    .catch((err) => {
      logger.error({ err }, "Seed failed");
      process.exit(1);
    });
}

module.exports = { seed };
