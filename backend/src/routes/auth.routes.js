const { Router } = require("express");
const { body } = require("express-validator");
const authController = require("../controllers/auth.controller");
const { requireAuth, attachUser } = require("../middlewares/auth.middleware");
const { validateRequest } = require("../middlewares/validation.middleware");
const { authLimiter } = require("../middlewares/security.middleware");

const router = Router();

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
