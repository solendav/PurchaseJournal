const userService = require("../services/user.service");
const { ok } = require("../utils/response");

async function list(req, res, next) {
  try {
    const members = await userService.listMembers(req.accountId);
    return ok(res, { members });
  } catch (err) {
    return next(err);
  }
}

async function create(req, res, next) {
  try {
    const member = await userService.createMember(req.accountId, req.body);
    return ok(res, { member }, 201);
  } catch (err) {
    return next(err);
  }
}

async function remove(req, res, next) {
  try {
    await userService.removeMember(req.accountId, req.params.id);
    return ok(res, { success: true });
  } catch (err) {
    return next(err);
  }
}

module.exports = { list, create, remove };

