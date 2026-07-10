const { Router } = require("express");
const { body } = require("express-validator");
const rateLimit = require("express-rate-limit");
const authController = require("../controllers/auth.controller");
const { requireAuth, attachUser } = require("../middlewares/auth.middleware");
const { validateRequest } = require("../middlewares/validation.middleware");
const { authLimiter } = require("../middlewares/security.middleware");
const { env } = require("../config/env");

const router = Router();

const sensitiveLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: env.isDevelopment ? 100 : 5,
  message: { success: false, error: "Too many requests. Try again later." },
  standardHeaders: true,
  legacyHeaders: false,
});

router.post(
  "/register",
  authLimiter,
  [
    body("email")
      .trim()
      .notEmpty()
      .withMessage("Email is required")
      .matches(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
      .withMessage("Enter a valid email"),
    body("password").isLength({ min: 8 }).withMessage("Password must be at least 8 characters"),
    body("firstName").optional().isString(),
    body("lastName").optional().isString(),
    validateRequest,
  ],
  authController.register
);

router.post(
  "/login",
  authLimiter,
  [
    body("email")
      .trim()
      .notEmpty()
      .withMessage("Email is required")
      .matches(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
      .withMessage("Enter a valid email"),
    body("password").notEmpty().withMessage("Password is required"),
    validateRequest,
  ],
  authController.login
);

router.post(
  "/refresh",
  authLimiter,
  [body("refreshToken").notEmpty().withMessage("Refresh token is required"), validateRequest],
  authController.refresh
);

router.post("/logout", authController.logout);

router.post(
  "/verify-email",
  authLimiter,
  [
    body("email")
      .trim()
      .notEmpty()
      .withMessage("Email is required")
      .matches(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
      .withMessage("Enter a valid email"),
    body("code").isString().isLength({ min: 4, max: 12 }),
    validateRequest,
  ],
  authController.verifyEmail
);

router.post(
  "/resend-verification",
  sensitiveLimiter,
  [
    body("email")
      .trim()
      .notEmpty()
      .withMessage("Email is required")
      .matches(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
      .withMessage("Enter a valid email"),
    validateRequest,
  ],
  authController.resendVerification
);

router.post(
  "/forgot-password",
  sensitiveLimiter,
  [
    body("email")
      .trim()
      .notEmpty()
      .withMessage("Email is required")
      .matches(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
      .withMessage("Enter a valid email"),
    validateRequest,
  ],
  authController.forgotPassword
);

router.post(
  "/reset-password",
  authLimiter,
  [
    body("email")
      .trim()
      .notEmpty()
      .withMessage("Email is required")
      .matches(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
      .withMessage("Enter a valid email"),
    body("code").isString().isLength({ min: 4, max: 12 }),
    body("password").isLength({ min: 8 }).withMessage("Password must be at least 8 characters"),
    validateRequest,
  ],
  authController.resetPassword
);

router.get("/me", requireAuth, attachUser, authController.me);

router.patch(
  "/me",
  requireAuth,
  attachUser,
  [
    body("firstName").optional().isString(),
    body("lastName").optional().isString(),
    validateRequest,
  ],
  authController.updateMe
);

module.exports = { authRouter: router };
