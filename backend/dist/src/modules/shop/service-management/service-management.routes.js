import { ServiceManagementController } from "./service-management.controller.js";
export const serviceManagementRoutes = async (app) => {
    const controller = new ServiceManagementController(app.serviceDeps.service);
    app.post("/shops/:shopId/services", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.addService);
    app.patch("/shops/services/:serviceId", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.updateService);
    app.delete("/shops/services/:serviceId", { preHandler: app.authorizeRoles(["BARBER", "ADMIN"]) }, controller.deleteService);
};
