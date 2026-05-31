import fp from "fastify-plugin";
import { prisma } from "./prisma.js";
const prismaPluginImpl = (app, _opts, done) => {
    app.decorate("prisma", prisma);
    app.addHook("onClose", async () => {
        await prisma.$disconnect();
    });
    done();
};
export const prismaPlugin = fp(prismaPluginImpl, {
    name: "prisma-plugin"
});
