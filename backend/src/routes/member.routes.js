const { Router } = require("express");
const { body } = require("express-validator");
const memberController = require("../controllers/member.controller");
const { requireAuth, attachUser, requireOwner } = require("../middlewares/auth.middleware");
const { validateRequest } = require("../middlewares/validation.middleware");

const router = Router();
router.use(requireAuth, attachUser, requireOwner);

router.get("/", memberController.list);

router.post(
  "/",
  [
    body("email").trim().notEmpty().withMessage("Email is required"),
    body("password").isLength({ min: 8 }).withMessage("Password must be at least 8 characters"),
    body("firstName").optional().isString(),
    body("lastName").optional().isString(),
    validateRequest,
  ],
  memberController.create
);

router.delete("/:id", memberController.remove);

module.exports = { memberRouter: router };

