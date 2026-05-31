import { nearbyShopsSchema, geolocationSearchSchema, mapMarkersSchema, etaEstimationSchema, shopClusteringSchema } from "../application/geolocation.schemas.js";
export class GeolocationController {
    service;
    constructor(service) {
        this.service = service;
    }
    findNearbyShops = async (request, reply) => {
        const dto = nearbyShopsSchema.parse(request.body);
        this.service.validateCoordinates(dto.latitude, dto.longitude);
        if (dto.radius) {
            this.service.validateRadius(dto.radius);
        }
        const requestParams = {
            latitude: dto.latitude,
            longitude: dto.longitude,
            limit: dto.limit || 20,
            offset: dto.offset || 0
        };
        if (dto.radius !== undefined)
            requestParams.radius = dto.radius;
        if (dto.city !== undefined)
            requestParams.city = dto.city;
        const result = await this.service.findNearbyShops(requestParams);
        return reply.send(result);
    };
    searchGeolocation = async (request, reply) => {
        const dto = geolocationSearchSchema.parse(request.body);
        this.service.validateCoordinates(dto.latitude, dto.longitude);
        if (dto.radius) {
            this.service.validateRadius(dto.radius);
        }
        const params = {
            latitude: dto.latitude,
            longitude: dto.longitude,
            limit: dto.limit || 20,
            offset: dto.offset || 0
        };
        if (dto.radius !== undefined)
            params.radius = dto.radius;
        if (dto.city !== undefined)
            params.city = dto.city;
        if (dto.minRating !== undefined)
            params.minRating = dto.minRating;
        if (dto.acceptingBookings !== undefined)
            params.acceptingBookings = dto.acceptingBookings;
        if (dto.acceptingWalkIns !== undefined)
            params.acceptingWalkIns = dto.acceptingWalkIns;
        const result = await this.service.searchGeolocation(params);
        return reply.send(result);
    };
    getMapMarkers = async (request, reply) => {
        const dto = mapMarkersSchema.parse(request.body);
        this.service.validateCoordinates(dto.latitude, dto.longitude);
        if (dto.radius) {
            this.service.validateRadius(dto.radius);
        }
        const markers = await this.service.getMapMarkers(dto.latitude, dto.longitude, dto.radius, dto.city);
        return reply.send({ markers });
    };
    getTopRatedNearbyShops = async (request, reply) => {
        const { latitude, longitude, radius } = request.query;
        const lat = parseFloat(latitude);
        const lng = parseFloat(longitude);
        const rad = parseFloat(radius);
        this.service.validateCoordinates(lat, lng);
        this.service.validateRadius(rad);
        const shops = await this.service.getTopRatedNearbyShops(lat, lng, rad);
        return reply.send({ shops });
    };
    calculateETA = async (request, reply) => {
        const dto = etaEstimationSchema.parse(request.body);
        this.service.validateCoordinates(dto.latitude, dto.longitude);
        const eta = await this.service.calculateETA(dto.shopId, dto.latitude, dto.longitude, dto.mode);
        return reply.send(eta);
    };
    createShopClusters = async (request, reply) => {
        const dto = shopClusteringSchema.parse(request.body);
        this.service.validateCoordinates(dto.latitude, dto.longitude);
        if (dto.radius) {
            this.service.validateRadius(dto.radius);
        }
        const clusters = await this.service.createShopClusters(dto.latitude, dto.longitude, dto.radius || 50, dto.clusterSize || 5);
        return reply.send({ clusters });
    };
    getShopsByCity = async (request, reply) => {
        const { city } = request.params;
        const { limit, offset } = request.query;
        const lim = limit ? parseInt(limit) : 20;
        const off = offset ? parseInt(offset) : 0;
        const result = await this.service.getShopsByCity(city, lim, off);
        return reply.send(result);
    };
}
