const crypto = require("crypto");

function hashToken(token) {
  return crypto.createHash("sha256").update(String(token)).digest("hex");
}

function generateRefreshToken() {
  return crypto.randomBytes(48).toString("base64url");
}

module.exports = { hashToken, generateRefreshToken };
