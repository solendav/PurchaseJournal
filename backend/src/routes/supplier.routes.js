const { Router } = require("express");
const { body } = require("express-validator");
const supplierController = require("../controllers/supplier.controller");
const paymentController = require("../controllers/payment.controller");
const { requireAuth, attachUser, requireOwner } = require("../middlewares/auth.middleware");
const { validateRequest } = require("../middlewares/validation.middleware");

const router = Router();

router.use(requireAuth, attachUser);

router.get("/", supplierController.list);
router.get("/:id", supplierController.getOne);

router.post(
  "/",
  [
    body("name").trim().notEmpty().withMessage("Name is required"),
    body("phone").optional().isString(),
    body("address").optional().isString(),
    body("notes").optional().isString(),
    validateRequest,
  ],
  supplierController.create
);

router.put(
  "/:id",
  requireOwner,
  [
    body("name").optional().trim().notEmpty(),
    body("phone").optional().isString(),
    body("address").optional().isString(),
    body("notes").optional().isString(),
    validateRequest,
  ],
  supplierController.update
);

router.delete("/:id", requireOwner, supplierController.remove);
router.get("/:id/statement", paymentController.statement);

module.exports = { supplierRouter: router };
