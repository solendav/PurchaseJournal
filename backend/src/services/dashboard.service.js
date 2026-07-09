const { pool } = require("../db/pool");

async function getSummary(userId) {
  const overallPurchased = await pool.query(
    `SELECT COALESCE(SUM(pi.line_total), 0) AS total
     FROM purchase_items pi
     JOIN purchases p ON p.id = pi.purchase_id
     WHERE p.user_id = $1`,
    [userId]
  );

  const overallPurchasePaid = await pool.query(
    `SELECT COALESCE(SUM(amount_paid), 0) AS total
     FROM purchases WHERE user_id = $1`,
    [userId]
  );

  const overallExtraPaid = await pool.query(
    `SELECT COALESCE(SUM(amount), 0) AS total
     FROM supplier_payments WHERE user_id = $1`,
    [userId]
  );

  const purchaseCount = await pool.query(
    `SELECT COUNT(*)::int AS count FROM purchases WHERE user_id = $1`,
    [userId]
  );

  const totalPurchased = Number(overallPurchased.rows[0].total);
  const totalPaid =
    Number(overallPurchasePaid.rows[0].total) + Number(overallExtraPaid.rows[0].total);
  const totalDebt = Math.max(0, totalPurchased - totalPaid);

  const bySupplier = await pool.query(
    `SELECT
       s.id AS supplier_id,
       s.name AS supplier_name,
       COUNT(DISTINCT p.id)::int AS purchase_count,
       COALESCE(SUM(pi.line_total), 0) AS total_purchased,
       COALESCE(SUM(DISTINCT p.amount_paid), 0) AS purchase_paid
     FROM suppliers s
     LEFT JOIN purchases p ON p.supplier_id = s.id AND p.user_id = s.user_id
     LEFT JOIN purchase_items pi ON pi.purchase_id = p.id
     WHERE s.user_id = $1
     GROUP BY s.id, s.name
     ORDER BY s.name ASC`,
    [userId]
  );

  const extraBySupplier = await pool.query(
    `SELECT supplier_id, COALESCE(SUM(amount), 0) AS extra_paid
     FROM supplier_payments
     WHERE user_id = $1
     GROUP BY supplier_id`,
    [userId]
  );

  const extraMap = Object.fromEntries(
    extraBySupplier.rows.map((r) => [r.supplier_id, Number(r.extra_paid)])
  );

  // Recompute per-supplier with accurate purchase_paid (sum not distinct)
  const supplierPaid = await pool.query(
    `SELECT supplier_id, COALESCE(SUM(amount_paid), 0) AS paid
     FROM purchases WHERE user_id = $1 GROUP BY supplier_id`,
    [userId]
  );
  const paidMap = Object.fromEntries(
    supplierPaid.rows.map((r) => [r.supplier_id, Number(r.paid)])
  );

  const supplierPurchased = await pool.query(
    `SELECT p.supplier_id, COALESCE(SUM(pi.line_total), 0) AS purchased
     FROM purchases p
     JOIN purchase_items pi ON pi.purchase_id = p.id
     WHERE p.user_id = $1
     GROUP BY p.supplier_id`,
    [userId]
  );
  const purchasedMap = Object.fromEntries(
    supplierPurchased.rows.map((r) => [r.supplier_id, Number(r.purchased)])
  );

  const suppliers = await pool.query(
    `SELECT id, name FROM suppliers WHERE user_id = $1 ORDER BY name ASC`,
    [userId]
  );

  const bySupplierOut = suppliers.rows.map((s) => {
    const purchased = purchasedMap[s.id] || 0;
    const paid = (paidMap[s.id] || 0) + (extraMap[s.id] || 0);
    const debt = Math.max(0, purchased - paid);
    const purchaseCountRow = bySupplier.rows.find((r) => r.supplier_id === s.id);
    return {
      supplierId: s.id,
      supplierName: s.name,
      purchaseCount: purchaseCountRow ? Number(purchaseCountRow.purchase_count) : 0,
      totalPurchased: purchased,
      totalPaid: paid,
      totalDebt: debt,
    };
  });

  bySupplierOut.sort((a, b) => b.totalDebt - a.totalDebt || a.supplierName.localeCompare(b.supplierName));

  return {
    overall: {
      purchaseCount: Number(purchaseCount.rows[0].count),
      totalPurchased,
      totalPaid,
      totalDebt,
    },
    bySupplier: bySupplierOut,
  };
}

module.exports = { getSummary };
