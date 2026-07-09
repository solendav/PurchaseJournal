const dashboardService = require("../services/dashboard.service");
const { ok } = require("../utils/response");

async function summary(req, res, next) {
  try {
    const summaryData = await dashboardService.getSummary(req.accountId);
    return ok(res, summaryData);
  } catch (err) {
    return next(err);
  }
}

module.exports = { summary };
