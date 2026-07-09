const { verifyAccessToken } = require("../utils/jwt");
const { AuthenticationError } = require("../utils/errors");
const userService = require("../services/user.service");

function requireAuth(req, _res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    return next(new AuthenticationError("Missing Authorization Bearer token"));
  }

  const token = header.slice("Bearer ".length).trim();
  if (!token) {
    return next(new AuthenticationError("Token is required"));
  }

  try {
    const payload = verifyAccessToken(token);
    req.userId = payload.sub;
    req.user = { id: payload.sub, email: payload.email };
    return next();
  } catch {
    return next(new AuthenticationError("Invalid or expired token"));
  }
}

async function attachUser(req, _res, next) {
  try {
    if (!req.userId) {
      return next(new AuthenticationError("Authentication required"));
    }
    const profile = await userService.findById(req.userId);
    if (!profile) {
      return next(new AuthenticationError("User not found"));
    }
    req.userProfile = profile;
    req.actorId = req.userId;
    req.accountId = profile.ownerId || profile.id;
    req.isOwner = !profile.ownerId && (profile.role || "owner") === "owner";
    return next();
  } catch (err) {
    return next(err);
  }
}

function requireOwner(req, _res, next) {
  if (req.isOwner) return next();
  return next(new AuthenticationError("Owner permissions required"));
}

module.exports = { requireAuth, attachUser, requireOwner };
