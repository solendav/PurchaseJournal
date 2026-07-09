const pino = require("pino");
const { env } = require("../config/env");

const LOG_LEVELS = ["trace", "debug", "info", "warn", "error", "fatal", "silent"];

function normalizeLogLevel(level) {
  const value = String(level || "info").toLowerCase();
  return LOG_LEVELS.includes(value) ? value : "info";
}

const activeLevel = normalizeLogLevel(env.logLevel);

const logger = pino({
  level: activeLevel,
  transport:
    env.isDevelopment && activeLevel !== "silent"
      ? { target: "pino-pretty", options: { colorize: true, translateTime: "HH:MM:ss" } }
      : undefined,
});

module.exports = { logger, activeLevel };
