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

// Haversine distance expression in km — no PostGIS required.
// Uses plain latitude/longitude double columns that already exist on Shop.
// GREATEST/LEAST guard against floating-point values outside [-1, 1] that
// would make acos() return NaN.
function haversineSql(lat: number, lng: number, latCol: string, lngCol: string): Prisma.Sql {
  return Prisma.sql`(6371.0 * acos(
    GREATEST(-1.0, LEAST(1.0,
      cos(radians(${lat})) * cos(radians(${Prisma.raw(latCol)})) *
      cos(radians(${Prisma.raw(lngCol)}) - radians(${lng})) +
      sin(radians(${lat})) * sin(radians(${Prisma.raw(latCol)}))
    ))
  ))`;
}

export class PrismaGeolocationRepository {
  async findNearbyShops(params: GeolocationSearchParams): Promise<PaginationResult<NearbyShop>> {
    const {
      latitude,
      longitude,
      radius = 10,
      city,
      minRating,
      acceptingBookings,
      acceptingWalkIns,
      premiumOnly,
      maxWaitMinutes,
      sortBy = "distance",
      limit = 20,
      offset = 0
    } = params;

    const distExpr = haversineSql(latitude, longitude, `s."latitude"`, `s."longitude"`);

    let whereClause = Prisma.sql`s."isActive" = true AND ${distExpr} <= ${radius}`;

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

    let orderByClause: Prisma.Sql;
    switch (sortBy) {
      case "wait":
        orderByClause = Prisma.sql`COALESCE(AVG(q."estimatedWaitMinutes"), 0) ASC, ns.distance ASC`;
        break;
      case "rating":
        orderByClause = Prisma.sql`COALESCE(AVG(r.rating), 0) DESC, COUNT(r.id) DESC, ns.distance ASC`;
        break;
      case "premium":
        orderByClause = Prisma.sql`ns."bookBerReservedChairCount" DESC, COALESCE(AVG(q."estimatedWaitMinutes"), 0) ASC, ns.distance ASC`;
        break;
      case "distance":
      default:
        orderByClause = Prisma.sql`ns.distance ASC`;
        break;
    }

    const shops = await prisma.$queryRaw<
      Array<{
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
      }>
    >`
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
          s."latitude",
          s."longitude",
          ${distExpr} AS distance,
          s."isActive",
          s."isAcceptingBookings",
          s."isAcceptingWalkIns",
          s."profileImage",
          s."bookBerReservedChairCount"
        FROM "Shop" s
        WHERE ${whereClause}
      ),
      shop_ratings AS (
        SELECT
          ns.id,
          COALESCE(AVG(r.rating), 0)  AS "averageRating",
          COUNT(r.id)                  AS "reviewCount"
        FROM nearby_shops ns
        LEFT JOIN "Review" r ON r."shopId" = ns.id
        GROUP BY ns.id
        HAVING COALESCE(AVG(r.rating), 0) >= ${minRating || 0}
      ),
      shop_queue_info AS (
        SELECT
          ns.id,
          COALESCE(AVG(q."estimatedWaitMinutes"), 0)                               AS "estimatedWaitMinutes",
          COUNT(DISTINCT CASE WHEN c.status = 'AVAILABLE' THEN c.id END)::int      AS "availableChairs"
        FROM nearby_shops ns
        LEFT JOIN "QueueEntry" q ON q."shopId" = ns.id
          AND q."queueStatus" IN ('WAITING', 'READY', 'CALLED')
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
        ns."latitude"                  AS latitude,
        ns."longitude"                 AS longitude,
        ns.distance,
        sr."averageRating",
        sr."reviewCount",
        ns."isActive",
        ns."isAcceptingBookings",
        ns."isAcceptingWalkIns",
        ns."profileImage",
        sq."estimatedWaitMinutes",
        sq."availableChairs",
        ns."bookBerReservedChairCount"
      FROM nearby_shops ns
      INNER JOIN shop_ratings sr ON sr.id = ns.id
      LEFT JOIN shop_queue_info sq ON sq.id = ns.id
      ${
        maxWaitMinutes
          ? Prisma.sql`WHERE sq."estimatedWaitMinutes" <= ${maxWaitMinutes} OR sq."estimatedWaitMinutes" IS NULL`
          : Prisma.empty
      }
      ORDER BY ${orderByClause}
      LIMIT ${limit}
      OFFSET ${offset}
    `;

    const totalCount = await prisma.$queryRaw<Array<{ count: bigint }>>`
      SELECT COUNT(*) AS count
      FROM "Shop" s
      WHERE ${whereClause}
    `;

    return {
      data: shops.map((shop) => ({
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
      })),
      total: Number(totalCount[0]?.count || 0),
      limit,
      offset,
      hasMore: offset + limit < Number(totalCount[0]?.count || 0)
    };
  }

  async getMapMarkers(
    latitude: number,
    longitude: number,
    radius?: number,
    city?: string
  ): Promise<MapMarker[]> {
    const radiusInKm = radius || 50;
    const distExpr = haversineSql(latitude, longitude, `s."latitude"`, `s."longitude"`);

    const markers = await prisma.$queryRaw<
      Array<{
        id: string;
        name: string;
        latitude: number;
        longitude: number;
        averageRating: number;
        isActive: boolean;
      }>
    >`
      SELECT
        s.id,
        s.name,
        s."latitude",
        s."longitude",
        COALESCE(AVG(r.rating), 0) AS "averageRating",
        s."isActive"
      FROM "Shop" s
      LEFT JOIN "Review" r ON r."shopId" = s.id
      WHERE s."isActive" = true
        AND ${distExpr} <= ${radiusInKm}
        ${city ? Prisma.sql`AND s.city ILIKE ${city}` : Prisma.empty}
      GROUP BY s.id, s.name, s."latitude", s."longitude", s."isActive"
      ORDER BY s.id
    `;

    return markers.map((m) => ({
      id: m.id,
      name: m.name,
      latitude: m.latitude,
      longitude: m.longitude,
      averageRating: Number(m.averageRating),
      isActive: m.isActive,
      shopId: m.id
    }));
  }

  async getTopRatedNearbyShops(
    latitude: number,
    longitude: number,
    radius: number,
    limit: number = 10
  ): Promise<NearbyShop[]> {
    const distExpr = haversineSql(latitude, longitude, `s."latitude"`, `s."longitude"`);

    const shops = await prisma.$queryRaw<
      Array<{
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
      }>
    >`
      SELECT
        s.id,
        s.name,
        s.slug,
        s.description,
        s.address,
        s.city,
        s.state,
        s.country,
        s."latitude",
        s."longitude",
        ${distExpr} AS distance,
        COALESCE(AVG(r.rating), 0) AS "averageRating",
        COUNT(r.id)                AS "reviewCount",
        s."isActive",
        s."isAcceptingBookings",
        s."isAcceptingWalkIns",
        s."profileImage"
      FROM "Shop" s
      LEFT JOIN "Review" r ON r."shopId" = s.id
      WHERE s."isActive" = true
        AND ${distExpr} <= ${radius}
      GROUP BY
        s.id, s.name, s.slug, s.description, s.address, s.city, s.state,
        s.country, s."latitude", s."longitude", s."isActive",
        s."isAcceptingBookings", s."isAcceptingWalkIns", s."profileImage"
      HAVING COUNT(r.id) >= 3
      ORDER BY "averageRating" DESC, "reviewCount" DESC
      LIMIT ${limit}
    `;

    return shops.map((shop) => ({
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

  async calculateETA(
    shopId: string,
    userLat: number,
    userLng: number,
    mode: "walking" | "driving" | "transit"
  ): Promise<ETAEstimation> {
    const shop = await prisma.shop.findUnique({
      where: { id: shopId },
      select: { latitude: true, longitude: true }
    });

    if (!shop) throw new Error("Shop not found");

    const distance = this.calculateDistance(userLat, userLng, shop.latitude, shop.longitude);
    const speedKmPerHour = { walking: 5, driving: 40, transit: 25 };
    const estimatedTravelTime = (distance / speedKmPerHour[mode]) * 60;

    return {
      shopId,
      distance,
      estimatedTravelTime: Math.round(estimatedTravelTime),
      estimatedArrivalTime: new Date(Date.now() + estimatedTravelTime * 60 * 1000),
      mode
    };
  }

  async createShopClusters(
    latitude: number,
    longitude: number,
    radius: number,
    clusterSize: number = 5
  ): Promise<ShopCluster[]> {
    const markers = await this.getMapMarkers(latitude, longitude, radius);
    const clusters: ShopCluster[] = [];
    const used = new Set<string>();

    for (const marker of markers) {
      if (used.has(marker.id)) continue;

      const nearbyMarkers = markers.filter((m) => {
        if (used.has(m.id)) return false;
        return (
          this.calculateDistance(marker.latitude, marker.longitude, m.latitude, m.longitude) <=
          radius / clusterSize
        );
      });

      if (nearbyMarkers.length > 0) {
        clusters.push({
          latitude: nearbyMarkers.reduce((s, m) => s + m.latitude, 0) / nearbyMarkers.length,
          longitude: nearbyMarkers.reduce((s, m) => s + m.longitude, 0) / nearbyMarkers.length,
          shopCount: nearbyMarkers.length,
          shops: nearbyMarkers
        });
        nearbyMarkers.forEach((m) => used.add(m.id));
      }
    }

    return clusters;
  }

  async getShopsByCity(
    city: string,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginationResult<NearbyShop>> {
    const shops = await prisma.$queryRaw<
      Array<{
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
      }>
    >`
      SELECT
        s.id,
        s.name,
        s.slug,
        s.description,
        s.address,
        s.city,
        s.state,
        s.country,
        s."latitude",
        s."longitude",
        COALESCE(AVG(r.rating), 0) AS "averageRating",
        COUNT(r.id)                AS "reviewCount",
        s."isActive",
        s."isAcceptingBookings",
        s."isAcceptingWalkIns",
        s."profileImage"
      FROM "Shop" s
      LEFT JOIN "Review" r ON r."shopId" = s.id
      WHERE s.city ILIKE ${city}
        AND s."isActive" = true
      GROUP BY
        s.id, s.name, s.slug, s.description, s.address, s.city, s.state,
        s.country, s."latitude", s."longitude", s."isActive",
        s."isAcceptingBookings", s."isAcceptingWalkIns", s."profileImage"
      ORDER BY s.name
      LIMIT ${limit}
      OFFSET ${offset}
    `;

    const totalCount = await prisma.$queryRaw<Array<{ count: bigint }>>`
      SELECT COUNT(*) AS count
      FROM "Shop" s
      WHERE s.city ILIKE ${city}
        AND s."isActive" = true
    `;

    return {
      data: shops.map((shop) => ({
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
      })),
      total: Number(totalCount[0]?.count || 0),
      limit,
      offset,
      hasMore: offset + limit < Number(totalCount[0]?.count || 0)
    };
  }

  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    const dLat = this.toRadians(lat2 - lat1);
    const dLon = this.toRadians(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(this.toRadians(lat1)) * Math.cos(this.toRadians(lat2)) * Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  private toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }
}
