const { Router } = require("express");
const uploadController = require("../controllers/upload.controller");
const { requireAuth } = require("../middlewares/auth.middleware");
const router = Router();

router.use(requireAuth);

router.post("/receipt", uploadController.uploadReceiptMiddleware, uploadController.uploadReceipt);

module.exports = { uploadRouter: router };
