const logger = require('../utils/logger');

/**
 * Custom API Error class
 */
class APIError extends Error {
  constructor(statusCode, message, isOperational = true, stack = '') {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;

    if (stack) {
      this.stack = stack;
    } else {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}

/**
 * Error converter - converts non-APIError errors to APIError
 */
const errorConverter = (err, req, res, next) => {
  let error = err;

  if (!(error instanceof APIError)) {
    const statusCode = error.statusCode || 500;
    const message = error.message || 'Internal Server Error';
    error = new APIError(statusCode, message, false, err.stack);
  }

  next(error);
};

/**
 * Global error handler middleware
 */
const errorHandler = (err, req, res, next) => {
  let { statusCode, message } = err;

  // Set default status code and message for non-operational errors
  if (!err.isOperational) {
    statusCode = 500;
    message = 'Internal Server Error';
  }

  // Log error details
  const errorLog = {
    statusCode,
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip,
    userId: req.user?.id,
  };

  if (statusCode >= 500) {
    logger.error('Server Error:', errorLog);
  } else {
    logger.warn('Client Error:', errorLog);
  }

  // Send error response
  res.status(statusCode).json({
    success: false,
    error: {
      code: statusCode,
      message,
      ...(process.env.NODE_ENV === 'development' && {
        stack: err.stack,
      }),
    },
  });
};

/**
 * 404 Not Found handler
 */
const notFoundHandler = (req, res, next) => {
  const error = new APIError(404, `Route not found: ${req.originalUrl}`);
  next(error);
};

/**
 * Async handler wrapper - catches async errors and passes to error handler
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

/**
 * Validation error handler
 */
const validationErrorHandler = (errors) => {
  const messages = errors.map(error => ({
    field: error.path,
    message: error.msg,
  }));

  return new APIError(400, 'Validation Error', true, JSON.stringify(messages));
};

module.exports = {
  APIError,
  errorConverter,
  errorHandler,
  notFoundHandler,
  asyncHandler,
  validationErrorHandler,
};
