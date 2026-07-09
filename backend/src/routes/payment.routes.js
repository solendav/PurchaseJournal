const { Router } = require("express");
const { body } = require("express-validator");
const paymentController = require("../controllers/payment.controller");
const { requireAuth, attachUser, requireOwner } = require("../middlewares/auth.middleware");
const { validateRequest } = require("../middlewares/validation.middleware");

const paymentRouter = Router();
paymentRouter.use(requireAuth, attachUser);

paymentRouter.get("/", paymentController.list);

paymentRouter.get("/:id", paymentController.getById);

paymentRouter.post(
  "/",
  [
    body("supplierId").isUUID().withMessage("Valid supplier ID is required"),
    body("amount").isNumeric().withMessage("Amount is required"),
    body("paymentDate").optional().isISO8601().toDate(),
    body("notes").optional().isString(),
    body("purchaseId").optional().isUUID(),
    validateRequest,
  ],
  paymentController.create
);

paymentRouter.put(
  "/:id",
  requireOwner,
  [
    body("amount").optional().isNumeric(),
    body("paymentDate").optional().isISO8601().toDate(),
    body("notes").optional().isString(),
    validateRequest,
  ],
  paymentController.update
);

paymentRouter.delete("/:id", requireOwner, paymentController.remove);

module.exports = { paymentRouter };
