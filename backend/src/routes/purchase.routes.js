const { Router } = require("express");
const { body } = require("express-validator");
const purchaseController = require("../controllers/purchase.controller");
const { requireAuth, attachUser, requireOwner } = require("../middlewares/auth.middleware");
const { validateRequest } = require("../middlewares/validation.middleware");

const router = Router();

router.use(requireAuth, attachUser);

router.get("/", purchaseController.list);

router.get("/:id", purchaseController.getOne);

router.post(
  "/",
  [
    body("supplierId").isUUID().withMessage("Valid supplier ID is required"),
    body("purchaseDate").optional().isISO8601().toDate(),
    body("amountPaid").optional().isNumeric(),
    body("notes").optional().isString(),
    body("receiptImagePath").optional().isString(),
    body("items").isArray({ min: 1 }).withMessage("At least one item is required"),
    body("items.*.description").trim().notEmpty().withMessage("Item description is required"),
    body("items.*.quantity").optional().isNumeric(),
    body("items.*.unitPrice").optional().isNumeric(),
    body("items.*.lineTotal").optional().isNumeric(),
    validateRequest,
  ],
  purchaseController.create
);

router.put(
  "/:id",
  requireOwner,
  [
    body("supplierId").optional().isUUID(),
    body("purchaseDate").optional().isISO8601().toDate(),
    body("amountPaid").optional().isNumeric(),
    body("notes").optional().isString(),
    body("receiptImagePath").optional().isString(),
    body("items").optional().isArray({ min: 1 }),
    validateRequest,
  ],
  purchaseController.update
);

router.delete("/:id", requireOwner, purchaseController.remove);

module.exports = { purchaseRouter: router };
