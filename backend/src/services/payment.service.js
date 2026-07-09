const { pool } = require("../db/pool");
const { NotFoundError, ValidationError } = require("../utils/errors");
const { assertSupplierOwned } = require("./supplier_statement.service");

function mapPayment(row) {
  const createdByName =
    row.first_name || row.last_name
      ? `${row.first_name || ""} ${row.last_name || ""}`.trim()
      : null;
  const updatedByName =
    row.updated_first_name || row.updated_last_name
      ? `${row.updated_first_name || ""} ${row.updated_last_name || ""}`.trim()
      : null;

  return {
    id: row.id,
    supplierId: row.supplier_id,
    supplierName: row.supplier_name || "",
    purchaseId: row.purchase_id,
    amount: Number(row.amount),
    paymentDate: row.payment_date,
    notes: row.notes || "",
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    createdBy: row.created_by,
    createdByName,
    updatedBy: row.updated_by,
    updatedByName,
  };
}

const PAYMENT_SELECT = `
  SELECT sp.*,
         s.name AS supplier_name,
         u.first_name,
         u.last_name,
         u2.first_name AS updated_first_name,
         u2.last_name AS updated_last_name
  FROM supplier_payments sp
  JOIN suppliers s ON s.id = sp.supplier_id
  LEFT JOIN users u ON u.id = sp.created_by
  LEFT JOIN users u2 ON u2.id = sp.updated_by
`;

async function listForUser(userId, { supplierId } = {}) {
  const params = [userId];
  let filter = "";
  if (supplierId) {
    params.push(supplierId);
    filter = ` AND sp.supplier_id = $${params.length}`;
  }

  const result = await pool.query(
    `${PAYMENT_SELECT}
     WHERE sp.user_id = $1${filter}
     ORDER BY sp.payment_date DESC, sp.created_at DESC`,
    params
  );
  return result.rows.map(mapPayment);
}

async function findById(accountId, paymentId) {
  const result = await pool.query(
    `${PAYMENT_SELECT}
     WHERE sp.user_id = $1 AND sp.id = $2`,
    [accountId, paymentId]
  );
  if (!result.rows[0]) throw new NotFoundError("Payment not found");
  return mapPayment(result.rows[0]);
}

async function create(accountId, actorId, body) {
  const supplierId = body.supplierId || body.supplier_id;
  await assertSupplierOwned(accountId, supplierId);

  const amount = Number(body.amount);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new ValidationError("amount must be a positive number");
  }

  const paymentDate = body.paymentDate || body.payment_date || new Date().toISOString().slice(0, 10);
  const notes = body.notes?.trim() || "";
  const purchaseId = body.purchaseId || body.purchase_id || null;

  const result = await pool.query(
    `INSERT INTO supplier_payments (user_id, supplier_id, purchase_id, amount, payment_date, notes, created_by)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING id`,
    [accountId, supplierId, purchaseId, amount, paymentDate, notes, actorId]
  );
  return findById(accountId, result.rows[0].id);
}

async function update(accountId, actorId, paymentId, body) {
  const existing = await findById(accountId, paymentId);

  const amount = body.amount != null ? Number(body.amount) : existing.amount;
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new ValidationError("amount must be a positive number");
  }

  const paymentDate = body.paymentDate || body.payment_date || existing.paymentDate;
  const notes = body.notes != null ? String(body.notes).trim() : existing.notes;

  await pool.query(
    `UPDATE supplier_payments
     SET amount = $3,
         payment_date = $4,
         notes = $5,
         updated_by = $6,
         updated_at = NOW()
     WHERE user_id = $1 AND id = $2`,
    [accountId, paymentId, amount, paymentDate, notes, actorId]
  );

  return findById(accountId, paymentId);
}

async function remove(userId, paymentId) {
  const result = await pool.query(
    `DELETE FROM supplier_payments WHERE user_id = $1 AND id = $2 RETURNING id`,
    [userId, paymentId]
  );
  if (!result.rows[0]) throw new NotFoundError("Payment not found");
}

module.exports = { listForUser, findById, create, update, remove };
