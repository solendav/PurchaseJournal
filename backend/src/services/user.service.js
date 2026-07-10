const { pool } = require("../db/pool");
const { hashPassword, comparePassword } = require("../utils/password");
const { NotFoundError, ValidationError } = require("../utils/errors");

const USER_COLUMNS =
  "id, email, first_name, last_name, role, owner_id, email_verified_at, created_at, updated_at";

function mapUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    email: row.email,
    firstName: row.first_name,
    lastName: row.last_name,
    role: row.role || "owner",
    ownerId: row.owner_id || null,
    emailVerified: Boolean(row.email_verified_at),
    emailVerifiedAt: row.email_verified_at ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

async function findByEmail(email) {
  const result = await pool.query(
    `SELECT ${USER_COLUMNS}, password_hash FROM users WHERE email = $1`,
    [email.toLowerCase().trim()]
  );
  return result.rows[0] || null;
}

async function findById(id) {
  const result = await pool.query(`SELECT ${USER_COLUMNS} FROM users WHERE id = $1`, [id]);
  return mapUser(result.rows[0]);
}

async function createUser({ email, password, firstName, lastName }) {
  const normalizedEmail = email.toLowerCase().trim();
  const existing = await findByEmail(normalizedEmail);
  if (existing) {
    throw new ValidationError("Email already registered");
  }

  const passwordHash = await hashPassword(password);
  const result = await pool.query(
    `INSERT INTO users (email, password_hash, first_name, last_name)
     VALUES ($1, $2, $3, $4)
     RETURNING ${USER_COLUMNS}`,
    [normalizedEmail, passwordHash, firstName?.trim() || "", lastName?.trim() || ""]
  );

  return mapUser(result.rows[0]);
}

async function listMembers(ownerId) {
  const result = await pool.query(
    `SELECT ${USER_COLUMNS}
     FROM users
     WHERE owner_id = $1
     ORDER BY created_at DESC`,
    [ownerId]
  );
  return result.rows.map(mapUser);
}

async function createMember(ownerId, { email, password, firstName, lastName }) {
  const normalizedEmail = String(email || "").toLowerCase().trim();
  if (!normalizedEmail) throw new ValidationError("Email is required");
  if (!password || String(password).length < 8) {
    throw new ValidationError("Password must be at least 8 characters");
  }

  const existing = await findByEmail(normalizedEmail);
  if (existing) throw new ValidationError("Email already registered");

  const passwordHash = await hashPassword(password);
  const result = await pool.query(
    `INSERT INTO users (email, password_hash, first_name, last_name, role, owner_id, email_verified_at)
     VALUES ($1, $2, $3, $4, 'member', $5, NOW())
     RETURNING ${USER_COLUMNS}`,
    [normalizedEmail, passwordHash, firstName?.trim() || "", lastName?.trim() || "", ownerId]
  );
  return mapUser(result.rows[0]);
}

async function removeMember(ownerId, memberId) {
  const result = await pool.query(
    `DELETE FROM users WHERE id = $1 AND owner_id = $2 RETURNING id`,
    [memberId, ownerId]
  );
  if (!result.rows[0]) throw new NotFoundError("Member not found");
}

async function verifyCredentials(email, password) {
  const user = await findByEmail(email);
  if (!user || !user.password_hash) {
    return null;
  }

  const valid = await comparePassword(password, user.password_hash);
  if (!valid) {
    return null;
  }

  return mapUser(user);
}

async function updateProfile(userId, { firstName, lastName }) {
  const result = await pool.query(
    `UPDATE users SET
       first_name = COALESCE($2, first_name),
       last_name = COALESCE($3, last_name),
       updated_at = NOW()
     WHERE id = $1
     RETURNING ${USER_COLUMNS}`,
    [userId, firstName ?? null, lastName ?? null]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError("User not found");
  }

  return mapUser(result.rows[0]);
}

async function markEmailVerified(userId) {
  const result = await pool.query(
    `UPDATE users SET email_verified_at = COALESCE(email_verified_at, NOW()), updated_at = NOW()
     WHERE id = $1
     RETURNING ${USER_COLUMNS}`,
    [userId]
  );
  return mapUser(result.rows[0]);
}

async function setPassword(userId, password) {
  const passwordHash = await hashPassword(password);
  const result = await pool.query(
    `UPDATE users SET
       password_hash = $2,
       password_changed_at = NOW(),
       updated_at = NOW()
     WHERE id = $1
     RETURNING ${USER_COLUMNS}`,
    [userId, passwordHash]
  );
  if (!result.rows[0]) throw new NotFoundError("User not found");
  return mapUser(result.rows[0]);
}

module.exports = {
  mapUser,
  findByEmail,
  findById,
  createUser,
  verifyCredentials,
  updateProfile,
  listMembers,
  createMember,
  removeMember,
  markEmailVerified,
  setPassword,
};
