import fp from "fastify-plugin";
import { env } from "../../../shared/config/env.js";
const authPluginImpl = (app, _opts, done) => {
    app.decorate("authenticate", (request) => {
        const bearer = request.headers.authorization?.startsWith("Bearer ")
            ? request.headers.authorization.slice(7)
            : undefined;
        const token = request.cookies?.[env.ACCESS_TOKEN_COOKIE_NAME] ?? bearer;
        if (!token) {
            throw app.httpErrors.unauthorized("Missing access token");
        }
        request.user = app.jwt.verify(token);
        return Promise.resolve();
    });
    app.decorate("authorizeRoles", (roles) => {
        return async (request) => {
            await app.authenticate(request);
            const user = request.user;
            if (!user?.sub || !roles.includes(user.role)) {
                throw app.httpErrors.forbidden("Insufficient permissions");
            }
        };
    });
    done();
};
export const authPlugin = fp(authPluginImpl, {
    name: "auth-plugin"
});
