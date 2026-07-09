const { Router } = require("express");
const { authRouter } = require("./auth.routes");
const { supplierRouter } = require("./supplier.routes");
const { purchaseRouter } = require("./purchase.routes");
const { dashboardRouter } = require("./dashboard.routes");
const { uploadRouter } = require("./upload.routes");
const { paymentRouter } = require("./payment.routes");
const { memberRouter } = require("./member.routes");

const router = Router();

router.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

router.use("/auth", authRouter);
router.use("/suppliers", supplierRouter);
router.use("/purchases", purchaseRouter);
router.use("/dashboard", dashboardRouter);
router.use("/uploads", uploadRouter);
router.use("/payments", paymentRouter);
router.use("/members", memberRouter);

module.exports = { router };
