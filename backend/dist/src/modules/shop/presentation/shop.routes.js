import { ShopController } from "./shop.controller.js";
export const shopRoutes = async (app) => {
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
};
