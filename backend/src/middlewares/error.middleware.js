const { logger } = require("../utils/logger");
const { AppError } = require("../utils/errors");
const { env } = require("../config/env");

function notFoundHandler(_req, res) {
  return res.status(404).json({ success: false, error: "Not Found" });
}

function errorHandler(err, _req, res, _next) {
  if (err.isOperational !== false) {
    logger.warn({ err }, "Operational error");
  } else {
    logger.error({ err }, "Unexpected error");
  }

  if (err instanceof AppError) {
    const body = { success: false, error: err.message };
    if (err.code) body.code = err.code;
    if (err.errors?.length) body.errors = err.errors;
    if (!env.isProduction) body.stack = err.stack;
    return res.status(err.statusCode).json(body);
  }

  const body = {
    success: false,
    error: env.isProduction ? "Internal Server Error" : err.message,
  };
  if (!env.isProduction) body.stack = err.stack;
  return res.status(err.statusCode || 500).json(body);
}

module.exports = { notFoundHandler, errorHandler };
