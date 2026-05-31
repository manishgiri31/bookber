export class AppError extends Error {
    code;
    statusCode;
    details;
    constructor(code, statusCode, message, details) {
        super(message);
        this.code = code;
        this.statusCode = statusCode;
        this.details = details;
    }
}
export const Errors = {
    unauthenticated: () => new AppError("UNAUTHENTICATED", 401, "Authentication required"),
    forbidden: () => new AppError("FORBIDDEN", 403, "Forbidden"),
    notFound: (message = "Resource not found") => new AppError("NOT_FOUND", 404, message),
    conflict: (message, details) => new AppError("CONFLICT", 409, message, details),
    validation: (message, details) => new AppError("VALIDATION_ERROR", 400, message, details)
};
