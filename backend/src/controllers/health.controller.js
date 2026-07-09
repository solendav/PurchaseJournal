const { pool } = require("../db/pool");
const { ok } = require("../utils/response");

async function health(_req, res, next) {
  try {
    let db = "ok";
    try {
      await pool.query("SELECT 1");
    } catch {
      db = "error";
    }
    return ok(res, { status: "ok", db, timestamp: new Date().toISOString() });
  } catch (err) {
    return next(err);
  }
}

module.exports = { health };
