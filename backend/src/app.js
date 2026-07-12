const express = require("express");
const cors = require("cors");
const pinoHttp = require("pino-http");

const { env } = require("./config/env");
const { logger } = require("./utils/logger");
const { router } = require("./routes");
const { notFoundHandler, errorHandler } = require("./middlewares/error.middleware");
const {
  helmetMiddleware,
  apiLimiter,
  compressionMiddleware,
} = require("./middlewares/security.middleware");
const { getReceiptDir } = require("./controllers/upload.controller");

const app = express();

app.set("trust proxy", 1);

app.use(helmetMiddleware);
app.use(compressionMiddleware);

app.use(
  cors({
    origin: (origin, cb) => {
      if (!origin) return cb(null, true);
      if (env.corsOrigins.includes(origin)) return cb(null, true);
      if (
        env.isDevelopment &&
        /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
      ) {
        return cb(null, true);
      }
      cb(new Error(`CORS: origin ${origin} not allowed`));
    },
    credentials: true,
  })
);

app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

app.use(
  pinoHttp({
    logger,
    customLogLevel: (_req, res, err) => {
      if (res.statusCode >= 400 && res.statusCode < 500) return "warn";
      if (res.statusCode >= 500 || err) return "error";
      return "info";
    },
    autoLogging: {
      ignore: (req) => req.url === "/health" || req.url === "/api/health",
    },
  })
);

const receiptDir = getReceiptDir();
if (receiptDir) {
  app.use("/uploads/receipts", express.static(receiptDir));
}

app.use("/api", apiLimiter);
app.use("/api", router);

app.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.get("/", (_req, res) => {
  res.json({
    name: "Purchase Journal API",
    status: "ok",
    health: "/health",
    api: "/api",
  });
});

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
module.exports.app = app;
