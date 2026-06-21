import type { FastifyReply, FastifyRequest } from "fastify";
import {
  nearbyShopsSchema,
  geolocationSearchSchema,
  mapMarkersSchema,
  etaEstimationSchema,
  shopClusteringSchema
} from "../application/geolocation.schemas.js";
import type { GeolocationService } from "../application/geolocation.service.js";

export class GeolocationController {
  constructor(private readonly service: GeolocationService) { }

  findNearbyShops = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = nearbyShopsSchema.parse(request.body);
    this.service.validateCoordinates(dto.latitude, dto.longitude);
    if (dto.radius) {
      this.service.validateRadius(dto.radius);
    }
    const requestParams: any = {
      latitude: dto.latitude,
      longitude: dto.longitude,
      limit: dto.limit || 20,
      offset: dto.offset || 0
    };
    if (dto.radius !== undefined) requestParams.radius = dto.radius;
    if (dto.city !== undefined) requestParams.city = dto.city;
    const result = await this.service.findNearbyShops(requestParams);
    return reply.send(result);
  };

  searchGeolocation = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = geolocationSearchSchema.parse(request.body);
    this.service.validateCoordinates(dto.latitude, dto.longitude);
    if (dto.radius) {
      this.service.validateRadius(dto.radius);
    }
    const params: any = {
      latitude: dto.latitude,
      longitude: dto.longitude,
      limit: dto.limit || 20,
      offset: dto.offset || 0
    };
    if (dto.radius !== undefined) params.radius = dto.radius;
    if (dto.city !== undefined) params.city = dto.city;
    if (dto.minRating !== undefined) params.minRating = dto.minRating;
    if (dto.acceptingBookings !== undefined) params.acceptingBookings = dto.acceptingBookings;
    if (dto.acceptingWalkIns !== undefined) params.acceptingWalkIns = dto.acceptingWalkIns;
    const result = await this.service.searchGeolocation(params);
    return reply.send(result);
  };

  getMapMarkers = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = mapMarkersSchema.parse(request.body);
    this.service.validateCoordinates(dto.latitude, dto.longitude);
    if (dto.radius) {
      this.service.validateRadius(dto.radius);
    }
    const markers = await this.service.getMapMarkers(dto.latitude, dto.longitude, dto.radius, dto.city);
    return reply.send({ markers });
  };

  getTopRatedNearbyShops = async (request: FastifyRequest, reply: FastifyReply) => {
    const { latitude, longitude, radius, limit } = request.query as { latitude?: string; longitude?: string; radius?: string; limit?: string };
    const lat = latitude ? parseFloat(latitude) : undefined;
    const lng = longitude ? parseFloat(longitude) : undefined;
    const rad = radius ? parseFloat(radius) : 50;
    const lim = limit ? parseInt(limit) : 10;
    if (lat !== undefined && lng !== undefined) {
      this.service.validateCoordinates(lat, lng);
    }
    const shops = await this.service.getTopRatedNearbyShops(lat, lng, rad, lim);
    return reply.send({ shops });
  };

  calculateETA = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = etaEstimationSchema.parse(request.body);
    this.service.validateCoordinates(dto.latitude, dto.longitude);
    const eta = await this.service.calculateETA(dto.shopId, dto.latitude, dto.longitude, dto.mode);
    return reply.send(eta);
  };

  createShopClusters = async (request: FastifyRequest, reply: FastifyReply) => {
    const dto = shopClusteringSchema.parse(request.body);
    this.service.validateCoordinates(dto.latitude, dto.longitude);
    if (dto.radius) {
      this.service.validateRadius(dto.radius);
    }
    const clusters = await this.service.createShopClusters(dto.latitude, dto.longitude, dto.radius || 50, dto.clusterSize || 5);
    return reply.send({ clusters });
  };

  getShopsByCity = async (request: FastifyRequest, reply: FastifyReply) => {
    const { city } = request.params as { city: string };
    const { limit, offset } = request.query as { limit?: string; offset?: string };
    const lim = limit ? parseInt(limit) : 20;
    const off = offset ? parseInt(offset) : 0;
    const result = await this.service.getShopsByCity(city, lim, off);
    return reply.send(result);
  };
}
