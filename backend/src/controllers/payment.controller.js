const paymentService = require("../services/payment.service");
const supplierStatementService = require("../services/supplier_statement.service");
const { ok } = require("../utils/response");

async function list(req, res, next) {
  try {
    const supplierId = req.query.supplierId || req.query.supplier_id;
    const payments = await paymentService.listForUser(req.accountId, { supplierId });
    return ok(res, { payments });
  } catch (err) {
    return next(err);
  }
}

async function getById(req, res, next) {
  try {
    const payment = await paymentService.findById(req.accountId, req.params.id);
    return ok(res, { payment });
  } catch (err) {
    return next(err);
  }
}

async function create(req, res, next) {
  try {
    const payment = await paymentService.create(req.accountId, req.actorId, req.body);
    return ok(res, { payment }, 201);
  } catch (err) {
    return next(err);
  }
}

async function update(req, res, next) {
  try {
    const payment = await paymentService.update(req.accountId, req.actorId, req.params.id, req.body);
    return ok(res, { payment });
  } catch (err) {
    return next(err);
  }
}

async function remove(req, res, next) {
  try {
    await paymentService.remove(req.accountId, req.params.id);
    return ok(res, { success: true });
  } catch (err) {
    return next(err);
  }
}

async function statement(req, res, next) {
  try {
    const data = await supplierStatementService.getStatement(req.accountId, req.params.id);
    return ok(res, data);
  } catch (err) {
    return next(err);
  }
}

module.exports = { list, getById, create, update, remove, statement };
