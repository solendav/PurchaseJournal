const userService = require("../services/user.service");
const tokenService = require("../services/token.service");
const emailService = require("../services/email.service");
const { signAccessToken, accessTokenPayload } = require("../utils/jwt");
const { ok } = require("../utils/response");
const { AuthenticationError, ValidationError } = require("../utils/errors");
const { env } = require("../config/env");
const { logger } = require("../utils/logger");

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

function withDevCode(payload, code) {
  if (!env.isProduction && code) {
    return { ...payload, devCode: code };
  }
  return payload;
}

async function register(req, res, next) {
  try {
    const { email, password, firstName, lastName } = req.body;
    const user = await userService.createUser({ email, password, firstName, lastName });

    const { code } = await tokenService.createOneTimeCode(user.id, "email_verify");
    try {
      await emailService.sendVerificationEmail(user.email, code);
    } catch (mailErr) {
      logger.error({ err: mailErr, email: user.email }, "Verification email failed");
    }

    const tokens = await issueTokenPair(user, req);
    return ok(
      res,
      withDevCode(
        {
          ...tokens,
          requiresEmailVerification: !user.emailVerified,
        },
        code
      ),
      201
    );
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

    if (env.requireEmailVerification && !user.emailVerified) {
      throw new AuthenticationError(
        "Please verify your email before signing in",
        "EMAIL_NOT_VERIFIED"
      );
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

async function verifyEmail(req, res, next) {
  try {
    const { email, code } = req.body;
    const userId = await tokenService.consumeOneTimeCodeByEmail(email, "email_verify", code);
    const user = await userService.markEmailVerified(userId);
    await tokenService.revokeAllRefreshTokens(userId);
    const tokens = await issueTokenPair(user, req);
    return ok(res, tokens);
  } catch (err) {
    return next(err);
  }
}

async function resendVerification(req, res, next) {
  try {
    const email = String(req.body.email || "")
      .toLowerCase()
      .trim();
    const row = await userService.findByEmail(email);
    if (!row) {
      return ok(res, { sent: true });
    }
    const user = userService.mapUser(row);
    if (user.emailVerified) {
      return ok(res, { sent: true, alreadyVerified: true });
    }

    const { code } = await tokenService.createOneTimeCode(user.id, "email_verify");
    try {
      await emailService.sendVerificationEmail(user.email, code);
    } catch (mailErr) {
      logger.error({ err: mailErr, email: user.email }, "Verification email delivery failed");
      return ok(res, withDevCode({ sent: false, error: "Email delivery failed" }, code));
    }
    return ok(res, withDevCode({ sent: true }, code));
  } catch (err) {
    return next(err);
  }
}

async function forgotPassword(req, res, next) {
  try {
    const email = String(req.body.email || "")
      .toLowerCase()
      .trim();
    const row = await userService.findByEmail(email);
    if (row?.password_hash) {
      const user = userService.mapUser(row);
      const { code } = await tokenService.createOneTimeCode(user.id, "password_reset");
      try {
        await emailService.sendPasswordResetEmail(user.email, code);
      } catch (mailErr) {
        logger.error({ err: mailErr, email: user.email }, "Password reset email failed");
        return ok(res, withDevCode({ sent: false, error: "Email delivery failed" }, code));
      }
      return ok(res, withDevCode({ sent: true }, code));
    }
    return ok(res, { sent: true });
  } catch (err) {
    return next(err);
  }
}

async function resetPassword(req, res, next) {
  try {
    const { email, code, password } = req.body;
    if (!password || String(password).length < 8) {
      throw new ValidationError("Password must be at least 8 characters");
    }
    const userId = await tokenService.consumeOneTimeCodeByEmail(email, "password_reset", code);
    await userService.setPassword(userId, password);
    await tokenService.revokeAllRefreshTokens(userId);
    return ok(res, { reset: true });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  register,
  login,
  refresh,
  logout,
  me,
  updateMe,
  verifyEmail,
  resendVerification,
  forgotPassword,
  resetPassword,
};
