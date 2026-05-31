import { Errors } from "../../../shared/http/app-error.js";
export class GeolocationService {
    repository;
    constructor(repository) {
        this.repository = repository;
    }
    async findNearbyShops(request) {
        const params = {
            latitude: request.latitude,
            longitude: request.longitude,
            limit: request.limit || 20,
            offset: request.offset || 0
        };
        if (request.radius !== undefined) {
            params.radius = request.radius;
        }
        if (request.city !== undefined) {
            params.city = request.city;
        }
        if (request.premiumOnly !== undefined) {
            params.premiumOnly = request.premiumOnly;
        }
        if (request.maxWaitMinutes !== undefined) {
            params.maxWaitMinutes = request.maxWaitMinutes;
        }
        if (request.sortBy !== undefined) {
            params.sortBy = request.sortBy;
        }
        return this.repository.findNearbyShops(params);
    }
    async searchGeolocation(params) {
        return this.repository.findNearbyShops(params);
    }
    async getMapMarkers(latitude, longitude, radius, city) {
        return this.repository.getMapMarkers(latitude, longitude, radius, city);
    }
    async getTopRatedNearbyShops(latitude, longitude, radius, limit = 10) {
        return this.repository.getTopRatedNearbyShops(latitude, longitude, radius, limit);
    }
    async calculateETA(shopId, userLat, userLng, mode) {
        return this.repository.calculateETA(shopId, userLat, userLng, mode);
    }
    async createShopClusters(latitude, longitude, radius, clusterSize = 5) {
        return this.repository.createShopClusters(latitude, longitude, radius, clusterSize);
    }
    async getShopsByCity(city, limit = 20, offset = 0) {
        return this.repository.getShopsByCity(city, limit, offset);
    }
    // Helper method to validate coordinates
    validateCoordinates(latitude, longitude) {
        if (latitude < -90 || latitude > 90) {
            throw Errors.validation("Latitude must be between -90 and 90");
        }
        if (longitude < -180 || longitude > 180) {
            throw Errors.validation("Longitude must be between -180 and 180");
        }
    }
    // Helper method to validate radius
    validateRadius(radius) {
        if (radius < 0.1 || radius > 100) {
            throw Errors.validation("Radius must be between 0.1 and 100 kilometers");
        }
    }
}
