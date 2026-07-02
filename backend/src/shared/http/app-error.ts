export class AppError extends Error {
  constructor(
    public readonly code: string,
    public readonly statusCode: number,
    message: string,
    public readonly details?: unknown
  ) {
    super(message);
  }
}

export const Errors = {
  unauthenticated: (message = "Authentication required") => new AppError("UNAUTHENTICATED", 401, message),
  forbidden: (message = "Forbidden") => new AppError("FORBIDDEN", 403, message),
  notFound: (message = "Resource not found") => new AppError("NOT_FOUND", 404, message),
  conflict: (message: string, details?: unknown) => new AppError("CONFLICT", 409, message, details),
  validation: (message: string, details?: unknown) => new AppError("VALIDATION_ERROR", 400, message, details)
};
