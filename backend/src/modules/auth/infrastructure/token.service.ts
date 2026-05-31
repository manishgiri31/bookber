import type { FastifyInstance } from "fastify";
import { env } from "../../../shared/config/env.js";
import type { AccessTokenClaims, RefreshTokenClaims } from "../domain/auth.types.js";

export class TokenService {
  constructor(private readonly app: FastifyInstance) { }

  signAccessToken(payload: AccessTokenClaims) {
    return this.app.jwt.sign(payload, {
      expiresIn: env.JWT_ACCESS_TTL
    });
  }

  signRefreshToken(payload: RefreshTokenClaims) {
    return this.app.jwt.sign(payload, {
      expiresIn: env.JWT_REFRESH_TTL
    });
  }
}
