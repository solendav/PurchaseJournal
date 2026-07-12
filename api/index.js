const app = require("../backend/src/app");
const { validateProductionEnv, logStartupWarnings } = require("../backend/src/bootstrap");

validateProductionEnv();
logStartupWarnings();

module.exports = app;
