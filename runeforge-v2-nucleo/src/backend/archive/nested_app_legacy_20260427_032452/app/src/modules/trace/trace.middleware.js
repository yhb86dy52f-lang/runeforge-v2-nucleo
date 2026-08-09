const logger = require('../../shared/logger');

function traceRequest(req, res, next) {
  const started = Date.now();

  res.on('finish', () => {
    logger.info('http_request', {
      method: req.method,
      path: req.originalUrl,
      statusCode: res.statusCode,
      durationMs: Date.now() - started,
      ip: req.ip
    });
  });

  next();
}

module.exports = { traceRequest };
