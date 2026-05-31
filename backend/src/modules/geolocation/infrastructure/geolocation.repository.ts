import { prisma } from "../../../shared/prisma/client.js";
import { Prisma } from "@prisma/client";
import type {
  NearbyShop,
  MapMarker,
  ShopCluster,
  ETAEstimation,
  GeolocationSearchParams,
  PaginationResult
} from "../domain/geolocation.types.js";

export class PrismaGeolocationRepository {
  // Find nearby shops using PostGIS ST_DWithin and ST_Distance with optimized queries
  async findNearbyShops(params: GeolocationSearchParams): Promise<PaginationResult<NearbyShop>> {
    const {
      latitude,
      longitude,
      radius = 10, // default 10km
      city,
      minRating,
      acceptingBookings,
      acceptingWalkIns,
      premiumOnly,
      maxWaitMinutes,
      sortBy = 'distance', // default sort by distance
      limit = 20,
      offset = 0
    } = params;

    // Build dynamic WHERE clauses as a single SQL template
    let whereClause = Prisma.sql`s.isActive = true
      AND ST_DWithin(
        s.location,
        ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography,
        ${radius * 1000}
      )`;

    if (city) {
      whereClause = Prisma.sql`${whereClause} AND s.city ILIKE ${city}`;
    }

    if (acceptingBookings !== undefined) {
      whereClause = Prisma.sql`${whereClause} AND s."isAcceptingBookings" = ${acceptingBookings}`;
    }

    if (acceptingWalkIns !== undefined) {
      whereClause = Prisma.sql`${whereClause} AND s."isAcceptingWalkIns" = ${acceptingWalkIns}`;
    }

    if (premiumOnly) {
      whereClause = Prisma.sql`${whereClause} AND s."bookBerReservedChairCount" > 0`;
    }

    // Build dynamic ORDER BY clause based on sortBy
    let orderByClause: Prisma.Sql;
    switch (sortBy) {
      case 'wait':
        orderByClause = Prisma.sql`COALESCE(AVG(q."estimatedWaitMinutes"), 0) ASC, ST_Distance(s.location, ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography) ASC`;
        break;
      case 'rating':
        orderByClause = Prisma.sql`COALESCE(AVG(r.rating), 0) DESC, COUNT(r.id) DESC, ST_Distance(s.location, ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography) ASC`;
        break;
      case 'premium':
        orderByClause = Prisma.sql`s."bookBerReservedChairCount" DESC, COALESCE(AVG(q."estimatedWaitMinutes"), 0) ASC, ST_Distance(s.location, ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography) ASC`;
        break;
      case 'distance':
      default:
        orderByClause = Prisma.sql`ST_Distance(s.location, ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography) ASC`;
        break;
    }

    // Optimized single query with CTE for better performance
    const shops = await prisma.$queryRaw<Array<{
      id: string;
      name: string;
      slug: string;
      description: string | null;
      address: string;
      city: string;
      state: string;
      country: string;
      latitude: number;
      longitude: number;
      distance: number;
      averageRating: number;
      reviewCount: number;
      isActive: boolean;
      isAcceptingBookings: boolean;
      isAcceptingWalkIns: boolean;
      profileImage: string | null;
      estimatedWaitMinutes: number;
      availableChairs: number;
      bookBerReservedChairCount: number;
    }>>`
      WITH nearby_shops AS (
        SELECT
          s.id,
          s.name,
          s.slug,
          s.description,
          s.address,
          s.city,
          s.state,
          s.country,
          s.latitude,
          s.longitude,
          ST_Distance(s.location, ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography) / 1000 as distance,
          s.isActive,
          s."isAcceptingBookings",
          s."isAcceptingWalkIns",
          s.profileImage,
          s."bookBerReservedChairCount"
        FROM "Shop" s
        WHERE ${whereClause}
      ),
      shop_ratings AS (
        SELECT
          ns.id,
          COALESCE(AVG(r.rating), 0) as averageRating,
          COUNT(r.id) as reviewCount
        FROM nearby_shops ns
        LEFT JOIN "Review" r ON r.shopId = ns.id
        GROUP BY ns.id
        HAVING COALESCE(AVG(r.rating), 0) >= ${minRating || 0}
      ),
      shop_queue_info AS (
        SELECT
          ns.id,
          COALESCE(AVG(q."estimatedWaitMinutes"), 0) as estimatedWaitMinutes,
          COUNT(DISTINCT CASE WHEN c.status = 'AVAILABLE' THEN c.id END) as availableChairs
        FROM nearby_shops ns
        LEFT JOIN "ActiveQueue" q ON q."shopId" = ns.id AND q."queueStatus" IN ('WAITING', 'READY', 'CALLED')
        LEFT JOIN "Chair" c ON c."shopId" = ns.id
        GROUP BY ns.id
      )
      SELECT
        ns.id,
        ns.name,
        ns.slug,
        ns.description,
        ns.address,
        ns.city,
        ns.state,
        ns.country,
        ns.latitude,
        ns.longitude,
        ns.distance,
        sr.averageRating,
        sr.reviewCount,
        ns.isActive,
        ns."isAcceptingBookings",
        ns."isAcceptingWalkIns",
        ns.profileImage,
        sq.estimatedWaitMinutes,
        sq.availableChairs,
        ns."bookBerReservedChairCount"
      FROM nearby_shops ns
      INNER JOIN shop_ratings sr ON sr.id = ns.id
      LEFT JOIN shop_queue_info sq ON sq.id = ns.id
      ${maxWaitMinutes ? Prisma.sql`WHERE sq.estimatedWaitMinutes <= ${maxWaitMinutes} OR sq.estimatedWaitMinutes IS NULL` : Prisma.empty}
      ORDER BY ${orderByClause}
      LIMIT ${limit}
      OFFSET ${offset}
    `;

    // Get total count with same filters
    const totalCount = await prisma.$queryRaw<Array<{ count: bigint }>>`
      SELECT COUNT(*) as count
      FROM "Shop" s
      WHERE ${whereClause}
    `;

    const nearbyShops: NearbyShop[] = shops.map(shop => ({
      id: shop.id,
      name: shop.name,
      slug: shop.slug,
      description: shop.description,
      address: shop.address,
      city: shop.city,
      state: shop.state,
      country: shop.country,
      latitude: shop.latitude,
      longitude: shop.longitude,
      distance: Number(shop.distance),
      averageRating: Number(shop.averageRating),
      reviewCount: Number(shop.reviewCount),
      isActive: shop.isActive,
      isAcceptingBookings: shop.isAcceptingBookings,
      isAcceptingWalkIns: shop.isAcceptingWalkIns,
      profileImage: shop.profileImage,
      estimatedWaitMinutes: shop.estimatedWaitMinutes ? Number(shop.estimatedWaitMinutes) : null,
      availableChairs: Number(shop.availableChairs)
    }));

    return {
      data: nearbyShops,
      total: Number(totalCount[0]?.count || 0),
      limit,
      offset,
      hasMore: (offset + limit) < Number(totalCount[0]?.count || 0)
    };
  }

  // Get map markers for FlutterMap using geography column
  async getMapMarkers(latitude: number, longitude: number, radius?: number, city?: string): Promise<MapMarker[]> {
    const radiusInKm = radius || 50; // default 50km

    const markers = await prisma.$queryRaw<Array<{
      id: string;
      name: string;
      latitude: number;
      longitude: number;
      averageRating: number;
      isActive: boolean;
    }>>`
      SELECT
        s.id,
        s.name,
        s.latitude,
        s.longitude,
        COALESCE(AVG(r.rating), 0) as averageRating,
        s.isActive
      FROM "Shop" s
      LEFT JOIN "Review" r ON r.shopId = s.id
      WHERE s.isActive = true
        AND ST_DWithin(
          s.location,
          ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography,
          ${radiusInKm * 1000}
        )
        ${city ? Prisma.sql`AND s.city ILIKE ${city}` : Prisma.empty}
      GROUP BY s.id, s.name, s.latitude, s.longitude, s.isActive
      ORDER BY s.id
    `;

    return markers.map(m => ({
      id: m.id,
      name: m.name,
      latitude: m.latitude,
      longitude: m.longitude,
      averageRating: Number(m.averageRating),
      isActive: m.isActive,
      shopId: m.id
    }));
  }

  // Get top rated nearby shops using geography column
  async getTopRatedNearbyShops(
    latitude: number,
    longitude: number,
    radius: number,
    limit: number = 10
  ): Promise<NearbyShop[]> {
    const shops = await prisma.$queryRaw<Array<{
      id: string;
      name: string;
      slug: string;
      description: string | null;
      address: string;
      city: string;
      state: string;
      country: string;
      latitude: number;
      longitude: number;
      distance: number;
      averageRating: number;
      reviewCount: number;
      isActive: boolean;
      isAcceptingBookings: boolean;
      isAcceptingWalkIns: boolean;
      profileImage: string | null;
    }>>`
      SELECT
        s.id,
        s.name,
        s.slug,
        s.description,
        s.address,
        s.city,
        s.state,
        s.country,
        s.latitude,
        s.longitude,
        ST_Distance(
          s.location,
          ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography
        ) / 1000 as distance,
        COALESCE(AVG(r.rating), 0) as averageRating,
        COUNT(r.id) as reviewCount,
        s.isActive,
        s.isAcceptingBookings,
        s.isAcceptingWalkIns,
        s.profileImage
      FROM "Shop" s
      LEFT JOIN "Review" r ON r.shopId = s.id
      WHERE s.isActive = true
        AND ST_DWithin(
          s.location,
          ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography,
          ${radius * 1000}
        )
      GROUP BY s.id, s.name, s.slug, s.description, s.address, s.city, s.state, s.country, s.latitude, s.longitude, s.isActive, s.isAcceptingBookings, s.isAcceptingWalkIns, s.profileImage
      HAVING COUNT(r.id) >= 3
      ORDER BY averageRating DESC, reviewCount DESC
      LIMIT ${limit}
    `;

    return shops.map(shop => ({
      id: shop.id,
      name: shop.name,
      slug: shop.slug,
      description: shop.description,
      address: shop.address,
      city: shop.city,
      state: shop.state,
      country: shop.country,
      latitude: shop.latitude,
      longitude: shop.longitude,
      distance: Number(shop.distance),
      averageRating: Number(shop.averageRating),
      reviewCount: Number(shop.reviewCount),
      isActive: shop.isActive,
      isAcceptingBookings: shop.isAcceptingBookings,
      isAcceptingWalkIns: shop.isAcceptingWalkIns,
      profileImage: shop.profileImage,
      estimatedWaitMinutes: null,
      availableChairs: 0
    }));
  }

  // Calculate ETA estimation (simplified - in production use Google Maps API or similar)
  async calculateETA(shopId: string, userLat: number, userLng: number, mode: "walking" | "driving" | "transit"): Promise<ETAEstimation> {
    const shop = await prisma.shop.findUnique({
      where: { id: shopId },
      select: { latitude: true, longitude: true }
    });

    if (!shop) {
      throw new Error("Shop not found");
    }

    // Calculate distance using Haversine formula
    const distance = this.calculateDistance(userLat, userLng, shop.latitude, shop.longitude);

    // Estimate travel time based on mode (simplified)
    const speedKmPerHour = {
      walking: 5,
      driving: 40,
      transit: 25
    };

    const estimatedTravelTime = (distance / speedKmPerHour[mode]) * 60; // in minutes
    const estimatedArrivalTime = new Date(Date.now() + estimatedTravelTime * 60 * 1000);

    return {
      shopId,
      distance,
      estimatedTravelTime: Math.round(estimatedTravelTime),
      estimatedArrivalTime,
      mode
    };
  }

  // Create shop clusters for map display
  async createShopClusters(
    latitude: number,
    longitude: number,
    radius: number,
    clusterSize: number = 5
  ): Promise<ShopCluster[]> {
    const markers = await this.getMapMarkers(latitude, longitude, radius);

    // Simple clustering algorithm based on distance
    const clusters: ShopCluster[] = [];
    const used = new Set<string>();

    for (const marker of markers) {
      if (used.has(marker.id)) continue;

      const nearbyMarkers = markers.filter(m => {
        if (used.has(m.id)) return false;
        const dist = this.calculateDistance(marker.latitude, marker.longitude, m.latitude, m.longitude);
        return dist <= radius / clusterSize;
      });

      if (nearbyMarkers.length > 0) {
        const avgLat = nearbyMarkers.reduce((sum, m) => sum + m.latitude, 0) / nearbyMarkers.length;
        const avgLng = nearbyMarkers.reduce((sum, m) => sum + m.longitude, 0) / nearbyMarkers.length;

        clusters.push({
          latitude: avgLat,
          longitude: avgLng,
          shopCount: nearbyMarkers.length,
          shops: nearbyMarkers
        });

        nearbyMarkers.forEach(m => used.add(m.id));
      }
    }

    return clusters;
  }

  // Haversine formula for distance calculation
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Earth's radius in km
    const dLat = this.toRadians(lat2 - lat1);
    const dLon = this.toRadians(lon2 - lon1);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRadians(lat1)) * Math.cos(this.toRadians(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }

  // Get shops by city
  async getShopsByCity(city: string, limit: number = 20, offset: number = 0): Promise<PaginationResult<NearbyShop>> {
    const shops = await prisma.$queryRaw<Array<{
      id: string;
      name: string;
      slug: string;
      description: string | null;
      address: string;
      city: string;
      state: string;
      country: string;
      latitude: number;
      longitude: number;
      averageRating: number;
      reviewCount: number;
      isActive: boolean;
      isAcceptingBookings: boolean;
      isAcceptingWalkIns: boolean;
      profileImage: string | null;
    }>>`
      SELECT
        s.id,
        s.name,
        s.slug,
        s.description,
        s.address,
        s.city,
        s.state,
        s.country,
        s.latitude,
        s.longitude,
        COALESCE(AVG(r.rating), 0) as averageRating,
        COUNT(r.id) as reviewCount,
        s.isActive,
        s.isAcceptingBookings,
        s.isAcceptingWalkIns,
        s.profileImage
      FROM "Shop" s
      LEFT JOIN "Review" r ON r.shopId = s.id
      WHERE s.city ILIKE ${city}
        AND s.isActive = true
      GROUP BY s.id, s.name, s.slug, s.description, s.address, s.city, s.state, s.country, s.latitude, s.longitude, s.isActive, s.isAcceptingBookings, s.isAcceptingWalkIns, s.profileImage
      ORDER BY s.name
      LIMIT ${limit}
      OFFSET ${offset}
    `;

    const totalCount = await prisma.$queryRaw<Array<{ count: bigint }>>`
      SELECT COUNT(*) as count
      FROM "Shop" s
      WHERE s.city ILIKE ${city}
        AND s.isActive = true
    `;

    const nearbyShops: NearbyShop[] = shops.map(shop => ({
      id: shop.id,
      name: shop.name,
      slug: shop.slug,
      description: shop.description,
      address: shop.address,
      city: shop.city,
      state: shop.state,
      country: shop.country,
      latitude: shop.latitude,
      longitude: shop.longitude,
      distance: 0,
      averageRating: Number(shop.averageRating),
      reviewCount: Number(shop.reviewCount),
      isActive: shop.isActive,
      isAcceptingBookings: shop.isAcceptingBookings,
      isAcceptingWalkIns: shop.isAcceptingWalkIns,
      profileImage: shop.profileImage,
      estimatedWaitMinutes: null,
      availableChairs: 0
    }));

    return {
      data: nearbyShops,
      total: Number(totalCount[0]?.count || 0),
      limit,
      offset,
      hasMore: (offset + limit) < Number(totalCount[0]?.count || 0)
    };
  }
}
