export class HttpError extends Error {
    statusCode;
    constructor(statusCode, message) {
        super(message);
        this.statusCode = statusCode;
        Object.setPrototypeOf(this, HttpError.prototype);
    }
    static badRequest(message) {
        return new HttpError(400, message);
    }
    static unauthorized(message) {
        return new HttpError(401, message);
    }
    static forbidden(message) {
        return new HttpError(403, message);
    }
    static notFound(message) {
        return new HttpError(404, message);
    }
    static conflict(message) {
        return new HttpError(409, message);
    }
    static internal(message) {
        return new HttpError(500, message);
    }
}
