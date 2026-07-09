const supplierService = require("../services/supplier.service");
const { ok } = require("../utils/response");

async function list(req, res, next) {
  try {
    const suppliers = await supplierService.listForUser(req.accountId);
    return ok(res, { suppliers });
  } catch (err) {
    return next(err);
  }
}

async function getOne(req, res, next) {
  try {
    const supplier = await supplierService.getById(req.accountId, req.params.id);
    return ok(res, { supplier });
  } catch (err) {
    return next(err);
  }
}

async function create(req, res, next) {
  try {
    const supplier = await supplierService.create(req.accountId, req.actorId, req.body);
    return ok(res, { supplier }, 201);
  } catch (err) {
    return next(err);
  }
}

async function update(req, res, next) {
  try {
    const supplier = await supplierService.update(req.accountId, req.actorId, req.params.id, req.body);
    return ok(res, { supplier });
  } catch (err) {
    return next(err);
  }
}

async function remove(req, res, next) {
  try {
    await supplierService.remove(req.accountId, req.params.id);
    return ok(res, { success: true });
  } catch (err) {
    return next(err);
  }
}

module.exports = { list, getOne, create, update, remove };
