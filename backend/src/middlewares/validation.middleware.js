const { validationResult } = require("express-validator");
const { ValidationError } = require("../utils/errors");

function validateRequest(req, _res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return next(
      new ValidationError(
        "Validation failed",
        errors.array().map((e) => ({ field: e.path, message: e.msg }))
      )
    );
  }
  return next();
}

module.exports = { validateRequest };
