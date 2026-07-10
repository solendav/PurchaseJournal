const { pool } = require("../db/pool");
const {
  hashToken,
  generateRefreshToken,
  generateOtpCode,
} = require("../utils/crypto_tokens");
const { AuthenticationError, ValidationError } = require("../utils/errors");

const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;
const EMAIL_VERIFY_TTL_MS = 24 * 60 * 60 * 1000;
const PASSWORD_RESET_TTL_MS = 60 * 60 * 1000;

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

async function revokeAllRefreshTokens(userId) {
  await pool.query(
    `UPDATE refresh_tokens SET revoked_at = NOW()
     WHERE user_id = $1 AND revoked_at IS NULL`,
    [userId]
  );
}

async function createOneTimeCode(userId, purpose) {
  const ttl = purpose === "password_reset" ? PASSWORD_RESET_TTL_MS : EMAIL_VERIFY_TTL_MS;
  const code = generateOtpCode();
  const tokenHash = hashToken(code);
  const expiresAt = new Date(Date.now() + ttl);

  await pool.query(
    `UPDATE auth_one_time_tokens
     SET used_at = NOW()
     WHERE user_id = $1 AND purpose = $2 AND used_at IS NULL`,
    [userId, purpose]
  );

  await pool.query(
    `INSERT INTO auth_one_time_tokens (user_id, token_hash, purpose, expires_at)
     VALUES ($1, $2, $3, $4)`,
    [userId, tokenHash, purpose, expiresAt.toISOString()]
  );

  return { code, expiresAt: expiresAt.toISOString() };
}

async function consumeOneTimeCode(userId, purpose, code) {
  if (!code || String(code).trim().length < 4) {
    throw new ValidationError("Invalid code");
  }

  const tokenHash = hashToken(String(code).trim());
  const result = await pool.query(
    `UPDATE auth_one_time_tokens
     SET used_at = NOW()
     WHERE user_id = $1
       AND purpose = $2
       AND token_hash = $3
       AND used_at IS NULL
       AND expires_at > NOW()
     RETURNING id`,
    [userId, purpose, tokenHash]
  );

  if (result.rows.length === 0) {
    throw new ValidationError("Invalid or expired code");
  }
}

async function consumeOneTimeCodeByEmail(email, purpose, code) {
  const userResult = await pool.query(`SELECT id FROM users WHERE email = $1`, [
    email.toLowerCase().trim(),
  ]);
  const user = userResult.rows[0];
  if (!user) {
    throw new ValidationError("Invalid or expired code");
  }
  await consumeOneTimeCode(user.id, purpose, code);
  return user.id;
}

module.exports = {
  issueRefreshToken,
  rotateRefreshToken,
  revokeRefreshToken,
  revokeAllRefreshTokens,
  createOneTimeCode,
  consumeOneTimeCode,
  consumeOneTimeCodeByEmail,
};
