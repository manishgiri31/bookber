import { z } from "zod";

export const nearbyShopsSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  radius: z.number().min(0.1).max(100).optional(), // max 100km
  city: z.string().min(1).max(100).optional(),
  limit: z.number().int().min(1).max(50).optional(),
  offset: z.number().int().min(0).optional()
});

export const geolocationSearchSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  radius: z.number().min(0.1).max(100).optional(),
  city: z.string().min(1).max(100).optional(),
  minRating: z.number().min(0).max(5).optional(),
  acceptingBookings: z.boolean().optional(),
  acceptingWalkIns: z.boolean().optional(),
  limit: z.number().int().min(1).max(50).optional(),
  offset: z.number().int().min(0).optional()
});

export const mapMarkersSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  radius: z.number().min(0.1).max(100).optional(),
  city: z.string().min(1).max(100).optional()
});

export const etaEstimationSchema = z.object({
  shopId: z.string().cuid(),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  mode: z.enum(["walking", "driving", "transit"]).default("driving")
});

export const shopClusteringSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  radius: z.number().min(0.1).max(50).optional(), // clustering radius
  clusterSize: z.number().int().min(2).max(10).optional()
});

export type NearbyShopsDto = z.infer<typeof nearbyShopsSchema>;
export type GeolocationSearchDto = z.infer<typeof geolocationSearchSchema>;
export type MapMarkersDto = z.infer<typeof mapMarkersSchema>;
export type ETAEstimationDto = z.infer<typeof etaEstimationSchema>;
export type ShopClusteringDto = z.infer<typeof shopClusteringSchema>;
