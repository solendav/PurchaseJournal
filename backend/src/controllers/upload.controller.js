const path = require("path");
const fs = require("fs");
const multer = require("multer");
const crypto = require("crypto");
const { env } = require("../config/env");
const { ok } = require("../utils/response");
const { ValidationError, NotFoundError } = require("../utils/errors");
const cloudinaryService = require("../services/cloudinary.service");
const { isServerless } = require("../utils/serverless");

function getReceiptDir() {
  if (isServerless()) return null;

  const root = path.resolve(process.cwd(), env.uploadDir, "receipts");
  if (!fs.existsSync(root)) {
    fs.mkdirSync(root, { recursive: true });
  }
  return root;
}

const diskStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, getReceiptDir());
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname || "").toLowerCase() || ".jpg";
    const safeExt = [".jpg", ".jpeg", ".png", ".webp", ".heic"].includes(ext) ? ext : ".jpg";
    const name = `${Date.now()}-${crypto.randomBytes(8).toString("hex")}${safeExt}`;
    cb(null, name);
  },
});

const upload = multer({
  storage: isServerless() ? multer.memoryStorage() : diskStorage,
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (!file.mimetype.startsWith("image/")) {
      return cb(new ValidationError("Only image uploads are allowed"));
    }
    return cb(null, true);
  },
});

function uploadReceiptMiddleware(req, res, next) {
  upload.single("receipt")(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      return next(new ValidationError(err.message));
    }
    if (err) {
      return next(err);
    }
    return next();
  });
}

async function uploadReceipt(req, res, next) {
  try {
    if (!req.file) {
      throw new ValidationError("Receipt image is required");
    }

    if (isServerless() || env.cloudinaryCloudName) {
      const result = await cloudinaryService.uploadReceiptBuffer(req.file.buffer ?? fs.readFileSync(req.file.path), {
        userId: req.userId,
        originalname: req.file.originalname,
      });

      return ok(res, {
        path: result.secure_url,
        url: result.secure_url,
        filename: result.public_id,
        originalName: req.file.originalname,
        size: req.file.size,
        mimeType: req.file.mimetype,
      });
    }

    const relativePath = path.posix.join("receipts", req.file.filename);
    const url = `${env.appPublicUrl.replace(/\/$/, "")}/uploads/${relativePath}`;

    return ok(res, {
      path: relativePath,
      url,
      filename: req.file.filename,
      originalName: req.file.originalname,
      size: req.file.size,
      mimeType: req.file.mimetype,
    });
  } catch (err) {
    if (err.http_code) {
      return next(new ValidationError(err.message || "Cloudinary upload failed"));
    }
    return next(err);
  }
}

function serveUpload(req, res, next) {
  try {
    const receiptDir = getReceiptDir();
    if (!receiptDir) {
      return res.status(404).json({ success: false, error: "File not found" });
    }

    const filename = path.basename(req.params.filename);
    const filePath = path.join(receiptDir, filename);
    if (!fs.existsSync(filePath)) {
      throw new NotFoundError("File not found");
    }
    return res.sendFile(filePath);
  } catch (err) {
    return next(err);
  }
}

module.exports = { uploadReceiptMiddleware, uploadReceipt, serveUpload, getReceiptDir };
