import { z } from "zod";
import type { FastifyPluginAsync } from "fastify";
import { ShopController } from "./shop.controller.js";

export const shopRoutes: FastifyPluginAsync = async (app) => {
  const controller = new ShopController(app.shopDeps.service);

  app.post("/", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.createShop);
  app.patch("/:shopId", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.updateShop);
  app.get("/:shopId", { preHandler: app.authenticate }, controller.getShop);
  app.get("/", { preHandler: app.authenticate }, controller.searchShops);
  app.get("/my", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.getMyShop);
  app.post("/:shopId/services", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.createService);
  app.patch("/services/:serviceId", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.updateService);
  app.delete("/services/:serviceId", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.deleteService);
  app.get("/:shopId/services", { preHandler: app.authenticate }, controller.searchServices);
  app.post("/:shopId/chairs", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.addChair);
  app.patch("/chairs/:chairId", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.updateChair);

  // ── ShopStaff management (OWNER / ADMIN only) ────────────────────────────────

  // GET /shops/:shopId/staff
  app.get("/:shopId/staff", { preHandler: app.authorizeRoles(["OWNER", "ADMIN"]) }, async (request) => {
    const { shopId } = request.params as { shopId: string };
    if (request.user.role === "OWNER") {
      const shop = await app.prisma.shop.findUnique({ where: { id: shopId }, select: { ownerId: true } });
      if (!shop || shop.ownerId !== request.user.sub) throw app.httpErrors.forbidden("Not the shop owner");
    }
    const staff = await app.prisma.shopStaff.findMany({
      where: { shopId },
      include: { user: { select: { id: true, fullName: true, email: true, role: true } } },
      orderBy: { createdAt: "asc" }
    });
    return { staff };
  });

  // POST /shops/:shopId/staff — add a user as RECEPTION staff
  app.post("/:shopId/staff", { preHandler: app.authorizeRoles(["OWNER", "ADMIN"]) }, async (request, reply) => {
    const { shopId } = request.params as { shopId: string };
    if (request.user.role === "OWNER") {
      const shop = await app.prisma.shop.findUnique({ where: { id: shopId }, select: { ownerId: true } });
      if (!shop || shop.ownerId !== request.user.sub) throw app.httpErrors.forbidden("Not the shop owner");
    }
    const { userId } = z.object({ userId: z.string().cuid() }).parse(request.body);

    const targetUser = await app.prisma.user.findUnique({ where: { id: userId }, select: { id: true } });
    if (!targetUser) throw app.httpErrors.notFound("User not found");

    const staffRecord = await app.prisma.shopStaff.create({
      data: { shopId, userId },
      include: { user: { select: { id: true, fullName: true, email: true } } }
    });

    await app.prisma.user.update({ where: { id: userId }, data: { role: "RECEPTION" } });

    return reply.status(201).send({ staff: staffRecord });
  });

  // DELETE /shops/:shopId/staff/:staffId
  app.delete("/:shopId/staff/:staffId", { preHandler: app.authorizeRoles(["OWNER", "ADMIN"]) }, async (request, reply) => {
    const { shopId, staffId } = request.params as { shopId: string; staffId: string };
    if (request.user.role === "OWNER") {
      const shop = await app.prisma.shop.findUnique({ where: { id: shopId }, select: { ownerId: true } });
      if (!shop || shop.ownerId !== request.user.sub) throw app.httpErrors.forbidden("Not the shop owner");
    }
    const staffRecord = await app.prisma.shopStaff.findUnique({ where: { id: staffId }, select: { id: true, userId: true, shopId: true } });
    if (!staffRecord || staffRecord.shopId !== shopId) throw app.httpErrors.notFound("Staff record not found");

    await app.prisma.shopStaff.delete({ where: { id: staffId } });
    // Revert user role to CLIENT only if they have no other staff assignments
    const otherAssignments = await app.prisma.shopStaff.count({ where: { userId: staffRecord.userId } });
    if (otherAssignments === 0) {
      await app.prisma.user.update({ where: { id: staffRecord.userId }, data: { role: "CLIENT" } });
    }

    return reply.status(204).send();
  });
};
