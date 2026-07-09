const { pool } = require("../db/pool");
const { NotFoundError, ValidationError } = require("../utils/errors");

function mapSupplier(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    phone: row.phone,
    notes: row.notes,
    purchaseCount: Number(row.purchase_count || 0),
    totalSpent: Number(row.total_spent || 0),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    createdBy: row.created_by,
    updatedBy: row.updated_by,
    createdByName:
      row.created_by_first_name || row.created_by_last_name
        ? `${row.created_by_first_name || ""} ${row.created_by_last_name || ""}`.trim()
        : null,
    updatedByName:
      row.updated_by_first_name || row.updated_by_last_name
        ? `${row.updated_by_first_name || ""} ${row.updated_by_last_name || ""}`.trim()
        : null,
  };
}

async function listForUser(userId) {
  const result = await pool.query(
    `SELECT s.*,
            COUNT(p.id)::int AS purchase_count,
            COALESCE(SUM(p.amount_paid), 0) AS total_spent,
            cu.first_name AS created_by_first_name,
            cu.last_name AS created_by_last_name,
            uu.first_name AS updated_by_first_name,
            uu.last_name AS updated_by_last_name
     FROM suppliers s
     LEFT JOIN purchases p ON p.supplier_id = s.id
     LEFT JOIN users cu ON cu.id = s.created_by
     LEFT JOIN users uu ON uu.id = s.updated_by
     WHERE s.user_id = $1
     GROUP BY s.id, cu.first_name, cu.last_name, uu.first_name, uu.last_name
     ORDER BY s.name ASC`,
    [userId]
  );
  return result.rows.map(mapSupplier);
}

async function getById(userId, supplierId) {
  const result = await pool.query(
    `SELECT s.*,
            COUNT(p.id)::int AS purchase_count,
            COALESCE(SUM(p.amount_paid), 0) AS total_spent,
            cu.first_name AS created_by_first_name,
            cu.last_name AS created_by_last_name,
            uu.first_name AS updated_by_first_name,
            uu.last_name AS updated_by_last_name
     FROM suppliers s
     LEFT JOIN purchases p ON p.supplier_id = s.id
     LEFT JOIN users cu ON cu.id = s.created_by
     LEFT JOIN users uu ON uu.id = s.updated_by
     WHERE s.user_id = $1 AND s.id = $2
     GROUP BY s.id, cu.first_name, cu.last_name, uu.first_name, uu.last_name`,
    [userId, supplierId]
  );
  const row = result.rows[0];
  if (!row) throw new NotFoundError("Supplier not found");
  return mapSupplier(row);
}

async function create(userId, actorId, { name, phone, notes }) {
  const trimmed = String(name || "").trim();
  if (!trimmed) throw new ValidationError("Supplier name is required");

  const result = await pool.query(
    `INSERT INTO suppliers (user_id, name, phone, notes, created_by, updated_by)
     VALUES ($1, $2, $3, $4, $5, $5)
     RETURNING *`,
    [userId, trimmed, phone?.trim() || "", notes?.trim() || "", actorId]
  );
  return mapSupplier({ ...result.rows[0], purchase_count: 0, total_spent: 0 });
}

async function update(userId, actorId, supplierId, { name, phone, notes }) {
  const result = await pool.query(
    `UPDATE suppliers SET
       name = COALESCE($3, name),
       phone = COALESCE($4, phone),
       notes = COALESCE($5, notes),
       updated_by = $6,
       updated_at = NOW()
     WHERE user_id = $1 AND id = $2
     RETURNING *`,
    [
      userId,
      supplierId,
      name !== undefined ? String(name).trim() : null,
      phone !== undefined ? String(phone).trim() : null,
      notes !== undefined ? String(notes).trim() : null,
      actorId,
    ]
  );
  if (!result.rows[0]) throw new NotFoundError("Supplier not found");
  return getById(userId, supplierId);
}

async function remove(userId, supplierId) {
  const purchases = await pool.query(
    `SELECT id FROM purchases WHERE user_id = $1 AND supplier_id = $2 LIMIT 1`,
    [userId, supplierId]
  );
  if (purchases.rows.length > 0) {
    throw new ValidationError("Cannot delete supplier with existing purchases");
  }

  const result = await pool.query(
    `DELETE FROM suppliers WHERE user_id = $1 AND id = $2 RETURNING id`,
    [userId, supplierId]
  );
  if (!result.rows[0]) throw new NotFoundError("Supplier not found");
}

module.exports = { listForUser, getById, create, update, remove };
