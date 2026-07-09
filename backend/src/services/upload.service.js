const fs = require("fs");
const path = require("path");
const multer = require("multer");
const { env } = require("../config/env");
const { ValidationError } = require("../utils/errors");

const uploadRoot = path.resolve(process.cwd(), env.uploadDir);

if (!fs.existsSync(uploadRoot)) {
  fs.mkdirSync(uploadRoot, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, uploadRoot);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || ".jpg";
    const safeExt = [".jpg", ".jpeg", ".png", ".webp", ".gif"].includes(ext) ? ext : ".jpg";
    const name = `receipt-${Date.now()}-${Math.round(Math.random() * 1e9)}${safeExt}`;
    cb(null, name);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (!file.mimetype.startsWith("image/")) {
      return cb(new ValidationError("Only image files are allowed"));
    }
    cb(null, true);
  },
});

function publicUrl(filename) {
  return `/uploads/${filename}`;
}

function receiptUploadMiddleware() {
  return upload.single("image");
}

module.exports = {
  uploadRoot,
  publicUrl,
  receiptUploadMiddleware,
};
