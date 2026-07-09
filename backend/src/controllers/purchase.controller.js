const purchaseService = require("../services/purchase.service");
const { ok } = require("../utils/response");

async function list(req, res, next) {
  try {
    const supplierId = req.query.supplierId || req.query.supplier_id;
    const purchases = await purchaseService.listForUser(req.accountId, { supplierId });
    return ok(res, { purchases });
  } catch (err) {
    return next(err);
  }
}

async function getOne(req, res, next) {
  try {
    const purchase = await purchaseService.getById(req.accountId, req.params.id);
    return ok(res, { purchase });
  } catch (err) {
    return next(err);
  }
}

async function create(req, res, next) {
  try {
    const purchase = await purchaseService.create(req.accountId, req.actorId, req.body);
    return ok(res, { purchase }, 201);
  } catch (err) {
    return next(err);
  }
}

async function update(req, res, next) {
  try {
    const purchase = await purchaseService.update(req.accountId, req.actorId, req.params.id, req.body);
    return ok(res, { purchase });
  } catch (err) {
    return next(err);
  }
}

async function remove(req, res, next) {
  try {
    await purchaseService.remove(req.accountId, req.params.id);
    return ok(res, { success: true });
  } catch (err) {
    return next(err);
  }
}

module.exports = { list, getOne, create, update, remove };
