const app = require("../src/app");
const { validateProductionEnv, logStartupWarnings } = require("../src/bootstrap");

validateProductionEnv();
logStartupWarnings();

module.exports = app;
