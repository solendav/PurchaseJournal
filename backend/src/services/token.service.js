const { pool } = require("../db/pool");
const { hashToken, generateRefreshToken } = require("../utils/crypto_tokens");
const { AuthenticationError } = require("../utils/errors");

const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;

async function issueRefreshToken(userId, { userAgent = "", ipAddress = "" } = {}) {
  const token = generateRefreshToken();
  const tokenHash = hashToken(token);
  const expiresAt = new Date(Date.now() + REFRESH_TTL_MS);

  await pool.query(
    `INSERT INTO refresh_tokens (user_id, token_hash, expires_at, user_agent, ip_address)
     VALUES ($1, $2, $3, $4, $5)`,
    [userId, tokenHash, expiresAt.toISOString(), userAgent, ipAddress]
  );

  return { refreshToken: token, refreshTokenExpiresAt: expiresAt.toISOString() };
}

async function rotateRefreshToken(rawToken, meta = {}) {
  if (!rawToken) {
    throw new AuthenticationError("Refresh token is required");
  }

  const tokenHash = hashToken(rawToken);
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const existing = await client.query(
      `SELECT id, user_id, expires_at, revoked_at
       FROM refresh_tokens
       WHERE token_hash = $1
       FOR UPDATE`,
      [tokenHash]
    );
    const row = existing.rows[0];
    if (!row || row.revoked_at || new Date(row.expires_at) <= new Date()) {
      await client.query("ROLLBACK");
      throw new AuthenticationError("Invalid or expired refresh token");
    }

    await client.query(`UPDATE refresh_tokens SET revoked_at = NOW() WHERE id = $1`, [row.id]);

    const token = generateRefreshToken();
    const newHash = hashToken(token);
    const expiresAt = new Date(Date.now() + REFRESH_TTL_MS);
    await client.query(
      `INSERT INTO refresh_tokens (user_id, token_hash, expires_at, user_agent, ip_address)
       VALUES ($1, $2, $3, $4, $5)`,
      [row.user_id, newHash, expiresAt.toISOString(), meta.userAgent || "", meta.ipAddress || ""]
    );
    await client.query("COMMIT");
    return {
      userId: row.user_id,
      refreshToken: token,
      refreshTokenExpiresAt: expiresAt.toISOString(),
    };
  } catch (err) {
    try {
      await client.query("ROLLBACK");
    } catch {
      // ignore
    }
    throw err;
  } finally {
    client.release();
  }
}

async function revokeRefreshToken(rawToken) {
  if (!rawToken) return;
  await pool.query(
    `UPDATE refresh_tokens SET revoked_at = NOW()
     WHERE token_hash = $1 AND revoked_at IS NULL`,
    [hashToken(rawToken)]
  );
}

module.exports = { issueRefreshToken, rotateRefreshToken, revokeRefreshToken };
