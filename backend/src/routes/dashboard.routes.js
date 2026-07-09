const { Router } = require("express");
const dashboardController = require("../controllers/dashboard.controller");
const { requireAuth, attachUser } = require("../middlewares/auth.middleware");

const router = Router();

router.use(requireAuth, attachUser);
router.get("/summary", dashboardController.summary);

module.exports = { dashboardRouter: router };
