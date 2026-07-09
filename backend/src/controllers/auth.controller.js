const userService = require("../services/user.service");
const tokenService = require("../services/token.service");
const { signAccessToken, accessTokenPayload } = require("../utils/jwt");
const { ok } = require("../utils/response");
const { AuthenticationError } = require("../utils/errors");
const { env } = require("../config/env");

function requestMeta(req) {
  return {
    userAgent: String(req.get("user-agent") || "").slice(0, 500),
    ipAddress: String(req.ip || req.socket?.remoteAddress || "").slice(0, 64),
  };
}

async function issueTokenPair(user, req) {
  const accessToken = signAccessToken(accessTokenPayload(user));
  const refresh = await tokenService.issueRefreshToken(user.id, requestMeta(req));
  return {
    accessToken,
    refreshToken: refresh.refreshToken,
    refreshTokenExpiresAt: refresh.refreshTokenExpiresAt,
    tokenType: "Bearer",
    expiresIn: env.jwtExpiresIn,
    user,
  };
}

async function register(req, res, next) {
  try {
    const { email, password, firstName, lastName } = req.body;
    const user = await userService.createUser({ email, password, firstName, lastName });
    const tokens = await issueTokenPair(user, req);
    return ok(res, tokens, 201);
  } catch (err) {
    return next(err);
  }
}

async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    const user = await userService.verifyCredentials(email, password);
    if (!user) {
      throw new AuthenticationError("Invalid email or password");
    }
    const tokens = await issueTokenPair(user, req);
    return ok(res, tokens);
  } catch (err) {
    return next(err);
  }
}

async function refresh(req, res, next) {
  try {
    const { refreshToken } = req.body;
    const rotated = await tokenService.rotateRefreshToken(refreshToken, requestMeta(req));
    const user = await userService.findById(rotated.userId);
    if (!user) {
      throw new AuthenticationError("User not found");
    }
    const accessToken = signAccessToken(accessTokenPayload(user));
    return ok(res, {
      accessToken,
      refreshToken: rotated.refreshToken,
      refreshTokenExpiresAt: rotated.refreshTokenExpiresAt,
      tokenType: "Bearer",
      expiresIn: env.jwtExpiresIn,
      user,
    });
  } catch (err) {
    return next(err);
  }
}

async function logout(req, res, next) {
  try {
    await tokenService.revokeRefreshToken(req.body.refreshToken);
    return ok(res, { success: true });
  } catch (err) {
    return next(err);
  }
}

async function me(req, res, next) {
  try {
    const user = req.userProfile || (await userService.findById(req.userId));
    if (!user) {
      throw new AuthenticationError("User not found");
    }
    return ok(res, { user });
  } catch (err) {
    return next(err);
  }
}

async function updateMe(req, res, next) {
  try {
    const user = await userService.updateProfile(req.userId, {
      firstName: req.body.firstName,
      lastName: req.body.lastName,
    });
    return ok(res, { user });
  } catch (err) {
    return next(err);
  }
}

module.exports = { register, login, refresh, logout, me, updateMe };
