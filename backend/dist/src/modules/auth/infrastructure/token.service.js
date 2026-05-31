import { env } from "../../../shared/config/env.js";
export class TokenService {
    app;
    constructor(app) {
        this.app = app;
    }
    signAccessToken(payload) {
        return this.app.jwt.sign(payload, {
            expiresIn: env.JWT_ACCESS_TTL
        });
    }
    signRefreshToken(payload) {
        return this.app.jwt.sign(payload, {
            expiresIn: env.JWT_REFRESH_TTL
        });
    }
}
