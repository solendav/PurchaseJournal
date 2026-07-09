const { pool } = require("../db/pool");
const { NotFoundError, ValidationError } = require("../utils/errors");

async function assertSupplierOwned(userId, supplierId) {
  const result = await pool.query(
    `SELECT id, name FROM suppliers WHERE user_id = $1 AND id = $2`,
    [userId, supplierId]
  );
  if (!result.rows[0]) throw new ValidationError("Invalid supplier");
  return result.rows[0];
}

async function getSupplierTotals(userId, supplierId) {
  const purchasedResult = await pool.query(
    `SELECT COALESCE(SUM(pi.line_total), 0) AS total
     FROM purchase_items pi
     JOIN purchases p ON p.id = pi.purchase_id
     WHERE p.user_id = $1 AND p.supplier_id = $2`,
    [userId, supplierId]
  );

  const purchasePaidResult = await pool.query(
    `SELECT COALESCE(SUM(amount_paid), 0) AS total
     FROM purchases
     WHERE user_id = $1 AND supplier_id = $2`,
    [userId, supplierId]
  );

  const extraPaidResult = await pool.query(
    `SELECT COALESCE(SUM(amount), 0) AS total
     FROM supplier_payments
     WHERE user_id = $1 AND supplier_id = $2`,
    [userId, supplierId]
  );

  const totalPurchased = Number(purchasedResult.rows[0].total);
  const totalPaid =
    Number(purchasePaidResult.rows[0].total) + Number(extraPaidResult.rows[0].total);
  const totalDebt = Math.max(0, totalPurchased - totalPaid);

  return { totalPurchased, totalPaid, totalDebt };
}

async function getStatement(userId, supplierId) {
  const supplier = await assertSupplierOwned(userId, supplierId);
  const totals = await getSupplierTotals(userId, supplierId);

  const purchasesResult = await pool.query(
    `SELECT p.id, p.purchase_date, p.amount_paid, p.notes, p.created_at,
            cu.first_name AS created_by_first_name,
            cu.last_name AS created_by_last_name
     FROM purchases p
     LEFT JOIN users cu ON cu.id = p.created_by
     WHERE p.user_id = $1 AND p.supplier_id = $2
     ORDER BY p.purchase_date ASC, p.created_at ASC`,
    [userId, supplierId]
  );

  const itemsResult = await pool.query(
    `SELECT pi.*, p.purchase_date, p.id AS purchase_id,
            p.created_at AS purchase_created_at, p.updated_at AS purchase_updated_at,
            cu.first_name AS created_by_first_name,
            cu.last_name AS created_by_last_name,
            uu.first_name AS updated_by_first_name,
            uu.last_name AS updated_by_last_name,
            icu.first_name AS item_created_first_name,
            icu.last_name AS item_created_last_name
     FROM purchase_items pi
     JOIN purchases p ON p.id = pi.purchase_id
     LEFT JOIN users cu ON cu.id = p.created_by
     LEFT JOIN users uu ON uu.id = p.updated_by
     LEFT JOIN users icu ON icu.id = pi.created_by
     WHERE p.user_id = $1 AND p.supplier_id = $2
     ORDER BY p.purchase_date ASC, pi.sort_order ASC, pi.created_at ASC`,
    [userId, supplierId]
  );

  const paymentsResult = await pool.query(
    `SELECT sp.id, sp.amount, sp.payment_date, sp.notes, sp.purchase_id, sp.created_at, sp.updated_at,
            cu.first_name AS created_by_first_name,
            cu.last_name AS created_by_last_name,
            uu.first_name AS updated_by_first_name,
            uu.last_name AS updated_by_last_name
     FROM supplier_payments sp
     LEFT JOIN users cu ON cu.id = sp.created_by
     LEFT JOIN users uu ON uu.id = sp.updated_by
     WHERE sp.user_id = $1 AND sp.supplier_id = $2
     ORDER BY sp.payment_date ASC, sp.created_at ASC`,
    [userId, supplierId]
  );

  const rows = [];

  function personName(first, last) {
    if (!first && !last) return null;
    return `${first || ""} ${last || ""}`.trim();
  }

  for (const item of itemsResult.rows) {
    const createdByName =
      personName(item.item_created_first_name, item.item_created_last_name) ||
      personName(item.created_by_first_name, item.created_by_last_name);
    const updatedByName = personName(item.updated_by_first_name, item.updated_by_last_name);

    rows.push({
      type: "purchase_item",
      date: item.purchase_date,
      purchaseId: item.purchase_id,
      description: item.description,
      quantity: Number(item.quantity),
      unitPrice: Number(item.unit_price),
      lineTotal: Number(item.line_total),
      paid: null,
      balance: 0,
      createdByName,
      updatedByName,
      createdAt: item.created_at || item.purchase_created_at,
      updatedAt: item.purchase_updated_at,
    });
  }

  for (const purchase of purchasesResult.rows) {
    const paid = Number(purchase.amount_paid);
    if (paid > 0) {
      rows.push({
        type: "payment",
        date: purchase.purchase_date,
        purchaseId: purchase.id,
        description: "Payment on purchase",
        quantity: null,
        unitPrice: null,
        lineTotal: null,
        paid,
        balance: 0,
        paymentId: null,
        notes: purchase.notes || "",
        createdByName: personName(purchase.created_by_first_name, purchase.created_by_last_name),
        createdAt: purchase.created_at,
      });
    }
  }

  for (const payment of paymentsResult.rows) {
    rows.push({
      type: "payment",
      date: payment.payment_date,
      purchaseId: payment.purchase_id,
      description: payment.notes?.trim() || "Payment",
      quantity: null,
      unitPrice: null,
      lineTotal: null,
      paid: Number(payment.amount),
      balance: 0,
      paymentId: payment.id,
      notes: payment.notes || "",
      createdByName: personName(payment.created_by_first_name, payment.created_by_last_name),
      updatedByName: personName(payment.updated_by_first_name, payment.updated_by_last_name),
      createdAt: payment.created_at,
      updatedAt: payment.updated_at,
    });
  }

  rows.sort((a, b) => {
    const dateDiff = new Date(a.date) - new Date(b.date);
    if (dateDiff !== 0) return dateDiff;
    if (a.type === b.type) return 0;
    return a.type === "purchase_item" ? -1 : 1;
  });

  let runningBalance = 0;
  for (const row of rows) {
    if (row.type === "purchase_item") {
      runningBalance += row.lineTotal;
      row.subtotal = row.lineTotal;
      row.balance = runningBalance;
    } else {
      row.subtotal = null;
      runningBalance = Math.max(0, runningBalance - row.paid);
      row.balance = runningBalance;
    }
  }

  return {
    supplier: {
      id: supplier.id,
      name: supplier.name,
    },
    summary: {
      totalPurchased: totals.totalPurchased,
      totalPaid: totals.totalPaid,
      totalDebt: totals.totalDebt,
      purchaseCount: purchasesResult.rows.length,
    },
    rows,
  };
}

module.exports = { getStatement, getSupplierTotals, assertSupplierOwned };
