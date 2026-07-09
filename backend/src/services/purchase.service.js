const { pool } = require("../db/pool");
const { NotFoundError, ValidationError } = require("../utils/errors");

function mapItem(row) {
  return {
    id: row.id,
    description: row.description,
    quantity: Number(row.quantity),
    unitPrice: Number(row.unit_price),
    lineTotal: Number(row.line_total),
    sortOrder: row.sort_order,
  };
}

function mapPurchase(row, items = []) {
  return {
    id: row.id,
    supplierId: row.supplier_id,
    supplierName: row.supplier_name || null,
    purchaseDate: row.purchase_date,
    amountPaid: Number(row.amount_paid),
    receiptImagePath: row.receipt_image_path || "",
    notes: row.notes || "",
    items,
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

function normalizeItems(items) {
  if (!Array.isArray(items) || items.length === 0) {
    throw new ValidationError("At least one line item is required");
  }

  return items.map((item, index) => {
    const description = String(item.description || item.name || "").trim();
    if (!description) throw new ValidationError("Item description is required");

    const quantity = Number(item.quantity ?? 1);
    const unitPrice = Number(item.unitPrice ?? item.unit_price ?? 0);
    if (!Number.isFinite(quantity) || quantity <= 0) {
      throw new ValidationError("Item quantity must be positive");
    }
    if (!Number.isFinite(unitPrice) || unitPrice < 0) {
      throw new ValidationError("Item unit price must be zero or greater");
    }

    const lineTotal =
      item.lineTotal !== undefined
        ? Number(item.lineTotal)
        : item.line_total !== undefined
          ? Number(item.line_total)
          : quantity * unitPrice;

    return {
      description,
      quantity,
      unitPrice,
      lineTotal: Number.isFinite(lineTotal) ? lineTotal : quantity * unitPrice,
      sortOrder: item.sortOrder ?? item.sort_order ?? index,
    };
  });
}

async function loadItems(purchaseId) {
  const result = await pool.query(
    `SELECT * FROM purchase_items WHERE purchase_id = $1 ORDER BY sort_order ASC, created_at ASC`,
    [purchaseId]
  );
  return result.rows.map(mapItem);
}

async function listForUser(userId, { supplierId } = {}) {
  const params = [userId];
  let filter = "";
  if (supplierId) {
    params.push(supplierId);
    filter = ` AND p.supplier_id = $${params.length}`;
  }

  const result = await pool.query(
    `SELECT
        p.*,
        s.name AS supplier_name,
        cu.first_name AS created_by_first_name,
        cu.last_name AS created_by_last_name,
        uu.first_name AS updated_by_first_name,
        uu.last_name AS updated_by_last_name
     FROM purchases p
     JOIN suppliers s ON s.id = p.supplier_id
     LEFT JOIN users cu ON cu.id = p.created_by
     LEFT JOIN users uu ON uu.id = p.updated_by
     WHERE p.user_id = $1${filter}
     ORDER BY p.purchase_date DESC, p.created_at DESC`,
    params
  );

  const purchases = [];
  for (const row of result.rows) {
    const items = await loadItems(row.id);
    purchases.push(mapPurchase(row, items));
  }
  return purchases;
}

async function getById(userId, purchaseId) {
  const result = await pool.query(
    `SELECT
        p.*,
        s.name AS supplier_name,
        cu.first_name AS created_by_first_name,
        cu.last_name AS created_by_last_name,
        uu.first_name AS updated_by_first_name,
        uu.last_name AS updated_by_last_name
     FROM purchases p
     JOIN suppliers s ON s.id = p.supplier_id
     LEFT JOIN users cu ON cu.id = p.created_by
     LEFT JOIN users uu ON uu.id = p.updated_by
     WHERE p.user_id = $1 AND p.id = $2`,
    [userId, purchaseId]
  );
  const row = result.rows[0];
  if (!row) throw new NotFoundError("Purchase not found");
  const items = await loadItems(purchaseId);
  return mapPurchase(row, items);
}

async function assertSupplierOwned(userId, supplierId) {
  const result = await pool.query(
    `SELECT id FROM suppliers WHERE user_id = $1 AND id = $2`,
    [userId, supplierId]
  );
  if (!result.rows[0]) throw new ValidationError("Invalid supplier");
}

async function create(accountId, actorId, body) {
  const supplierId = body.supplierId || body.supplier_id;
  await assertSupplierOwned(accountId, supplierId);

  const items = normalizeItems(body.items);
  const rawPaid = body.amountPaid ?? body.amount_paid;
  const amountPaid = rawPaid === undefined || rawPaid === null || rawPaid === ''
    ? 0
    : Number(rawPaid);
  if (!Number.isFinite(amountPaid) || amountPaid < 0) {
    throw new ValidationError("amountPaid must be a non-negative number");
  }

  const purchaseDate = body.purchaseDate || body.purchase_date || new Date().toISOString().slice(0, 10);
  const receiptImagePath = body.receiptImagePath || body.receipt_image_path || "";
  const notes = body.notes?.trim() || "";

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const purchaseResult = await client.query(
      `INSERT INTO purchases (user_id, supplier_id, purchase_date, amount_paid, receipt_image_path, notes, created_by, updated_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $7)
       RETURNING *`,
      [accountId, supplierId, purchaseDate, amountPaid, receiptImagePath, notes, actorId]
    );
    const purchase = purchaseResult.rows[0];

    for (const item of items) {
      await client.query(
        `INSERT INTO purchase_items (purchase_id, description, quantity, unit_price, line_total, sort_order, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [purchase.id, item.description, item.quantity, item.unitPrice, item.lineTotal, item.sortOrder, actorId]
      );
    }

    await client.query("COMMIT");
    return getById(accountId, purchase.id);
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

async function update(accountId, actorId, purchaseId, body) {
  await getById(accountId, purchaseId);

  const supplierId = body.supplierId || body.supplier_id;
  if (supplierId) await assertSupplierOwned(accountId, supplierId);

  const items = body.items ? normalizeItems(body.items) : null;
  const amountPaid =
    body.amountPaid !== undefined || body.amount_paid !== undefined
      ? Number(body.amountPaid ?? body.amount_paid)
      : null;
  if (amountPaid !== null && (!Number.isFinite(amountPaid) || amountPaid < 0)) {
    throw new ValidationError("amountPaid must be a non-negative number");
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query(
      `UPDATE purchases SET
         supplier_id = COALESCE($3, supplier_id),
         purchase_date = COALESCE($4, purchase_date),
         amount_paid = COALESCE($5, amount_paid),
         receipt_image_path = COALESCE($6, receipt_image_path),
         notes = COALESCE($7, notes),
         updated_by = $8,
         updated_at = NOW()
       WHERE user_id = $1 AND id = $2`,
      [
        accountId,
        purchaseId,
        supplierId || null,
        body.purchaseDate || body.purchase_date || null,
        amountPaid,
        body.receiptImagePath !== undefined || body.receipt_image_path !== undefined
          ? body.receiptImagePath || body.receipt_image_path || ""
          : null,
        body.notes !== undefined ? String(body.notes).trim() : null,
        actorId,
      ]
    );

    if (items) {
      await client.query(`DELETE FROM purchase_items WHERE purchase_id = $1`, [purchaseId]);
      for (const item of items) {
        await client.query(
          `INSERT INTO purchase_items (purchase_id, description, quantity, unit_price, line_total, sort_order, created_by)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [purchaseId, item.description, item.quantity, item.unitPrice, item.lineTotal, item.sortOrder, actorId]
        );
      }
    }

    await client.query("COMMIT");
    return getById(accountId, purchaseId);
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

async function remove(userId, purchaseId) {
  const result = await pool.query(
    `DELETE FROM purchases WHERE user_id = $1 AND id = $2 RETURNING id`,
    [userId, purchaseId]
  );
  if (!result.rows[0]) throw new NotFoundError("Purchase not found");
}

module.exports = { listForUser, getById, create, update, remove };
