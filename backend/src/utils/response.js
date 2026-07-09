function ok(res, data, status = 200) {
  return res.status(status).json({ success: true, data });
}

function fail(res, status, message, extra = {}) {
  return res.status(status).json({ success: false, error: message, ...extra });
}

module.exports = { ok, fail };
