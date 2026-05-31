export class HttpError extends Error {
  statusCode: number;

  constructor(
    statusCode: number,
    message: string
  ) {
    super(message);

    this.statusCode = statusCode;

    Object.setPrototypeOf(this, HttpError.prototype);
  }

  static badRequest(message: string) {
    return new HttpError(400, message);
  }

  static unauthorized(message: string) {
    return new HttpError(401, message);
  }

  static forbidden(message: string) {
    return new HttpError(403, message);
  }

  static notFound(message: string) {
    return new HttpError(404, message);
  }

  static conflict(message: string) {
    return new HttpError(409, message);
  }

  static internal(message: string) {
    return new HttpError(500, message);
  }
}