const crypto = require("crypto");

function hashToken(token) {
  return crypto.createHash("sha256").update(String(token)).digest("hex");
}

function generateRefreshToken() {
  return crypto.randomBytes(48).toString("base64url");
}

function generateOtpCode(length = 6) {
  const max = 10 ** length;
  const value = crypto.randomInt(0, max);
  return String(value).padStart(length, "0");
}

module.exports = { hashToken, generateRefreshToken, generateOtpCode };
