const jwt = require("jsonwebtoken");
const { env } = require("../config/env");

function signAccessToken(payload) {
  return jwt.sign(payload, env.jwtSecret, { expiresIn: env.jwtExpiresIn });
}

function verifyAccessToken(token) {
  return jwt.verify(token, env.jwtSecret);
}

function accessTokenPayload(user) {
  return {
    sub: user.id,
    email: user.email,
  };
}

module.exports = { signAccessToken, verifyAccessToken, accessTokenPayload };
