import { Errors } from "../../../shared/http/app-error.js";
import type { PrismaGeolocationRepository } from "../infrastructure/geolocation.repository.js";
import type {
  NearbyShopsRequest,
  NearbyShop,
  MapMarker,
  ShopCluster,
  ETAEstimation,
  GeolocationSearchParams,
  PaginationResult
} from "../domain/geolocation.types.js";

export class GeolocationService {
  constructor(private readonly repository: PrismaGeolocationRepository) { }

  async findNearbyShops(request: NearbyShopsRequest): Promise<PaginationResult<NearbyShop>> {
    const params: GeolocationSearchParams = {
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

  async searchGeolocation(params: GeolocationSearchParams): Promise<PaginationResult<NearbyShop>> {
    return this.repository.findNearbyShops(params);
  }

  async getMapMarkers(latitude: number, longitude: number, radius?: number, city?: string): Promise<MapMarker[]> {
    return this.repository.getMapMarkers(latitude, longitude, radius, city);
  }

  async getTopRatedNearbyShops(latitude: number, longitude: number, radius: number, limit: number = 10): Promise<NearbyShop[]> {
    return this.repository.getTopRatedNearbyShops(latitude, longitude, radius, limit);
  }

  async calculateETA(shopId: string, userLat: number, userLng: number, mode: "walking" | "driving" | "transit"): Promise<ETAEstimation> {
    return this.repository.calculateETA(shopId, userLat, userLng, mode);
  }

  async createShopClusters(latitude: number, longitude: number, radius: number, clusterSize: number = 5): Promise<ShopCluster[]> {
    return this.repository.createShopClusters(latitude, longitude, radius, clusterSize);
  }

  async getShopsByCity(city: string, limit: number = 20, offset: number = 0): Promise<PaginationResult<NearbyShop>> {
    return this.repository.getShopsByCity(city, limit, offset);
  }

  // Helper method to validate coordinates
  validateCoordinates(latitude: number, longitude: number): void {
    if (latitude < -90 || latitude > 90) {
      throw Errors.validation("Latitude must be between -90 and 90");
    }
    if (longitude < -180 || longitude > 180) {
      throw Errors.validation("Longitude must be between -180 and 180");
    }
  }

  // Helper method to validate radius
  validateRadius(radius: number): void {
    if (radius < 0.1 || radius > 100) {
      throw Errors.validation("Radius must be between 0.1 and 100 kilometers");
    }
  }
}
