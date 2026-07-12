const { Readable } = require("stream");
const crypto = require("crypto");
const cloudinary = require("cloudinary").v2;
const { env } = require("../config/env");
const { ValidationError } = require("../utils/errors");

let configured = false;

function ensureConfigured() {
  if (configured) return;
  if (!env.cloudinaryCloudName || !env.cloudinaryApiKey || !env.cloudinaryApiSecret) {
    throw new ValidationError(
      "Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET."
    );
  }

  cloudinary.config({
    cloud_name: env.cloudinaryCloudName,
    api_key: env.cloudinaryApiKey,
    api_secret: env.cloudinaryApiSecret,
    secure: true,
  });
  configured = true;
}

function uploadReceiptBuffer(buffer, { userId, originalname } = {}) {
  ensureConfigured();

  const owner = userId || "anonymous";
  const suffix = crypto.randomBytes(6).toString("hex");
  const publicId = `${env.cloudinaryFolder}/receipts/${owner}/receipt_${Date.now()}_${suffix}`;

  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        public_id: publicId,
        folder: undefined,
        resource_type: "image",
        context: originalname ? { alt: originalname } : undefined,
      },
      (error, result) => {
        if (error) return reject(error);
        return resolve(result);
      }
    );

    Readable.from(buffer).pipe(uploadStream);
  });
}

module.exports = { uploadReceiptBuffer, ensureConfigured };
