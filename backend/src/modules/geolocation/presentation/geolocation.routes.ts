import type { FastifyPluginAsync } from "fastify";
import { GeolocationController } from "./geolocation.controller.js";

export const geolocationRoutes: FastifyPluginAsync = async (app) => {
  const controller = new GeolocationController(app.geoDeps.service);

  app.post("/geolocation/nearby", controller.findNearbyShops);
  app.post("/geolocation/search", controller.searchGeolocation);
  app.post("/geolocation/markers", controller.getMapMarkers);
  app.get("/geolocation/top-rated", controller.getTopRatedNearbyShops);
  app.post("/geolocation/eta", controller.calculateETA);
  app.post("/geolocation/clusters", controller.createShopClusters);
  app.get("/geolocation/city/:city", controller.getShopsByCity);
};
