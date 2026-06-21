import type { Prisma, Shop } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";
import type { ChairStatus, PaginationResult, ShopSearchParams, ServiceSearchParams } from "../domain/shop.types.js";

export class PrismaShopRepository {
  async createShop(data: Prisma.ShopCreateInput) {
    return prisma.shop.create({ data });
  }

  async updateShop(shopId: string, data: Prisma.ShopUpdateInput) {
    return prisma.shop.update({ where: { id: shopId }, data });
  }

  async findShopById(shopId: string) {
    return prisma.shop.findUnique({
      where: { id: shopId },
      include: {
        services: { where: { isActive: true } },
        chairs: true
      }
    });
  }

  async findChairById(chairId: string) {
    return prisma.chair.findUnique({
      where: { id: chairId },
      include: { shop: true }
    });
  }

  async findServiceById(serviceId: string) {
    return prisma.service.findUnique({
      where: { id: serviceId }
    });
  }

  async findShopByBarber(userId: string) {
    const barber = await prisma.barber.findUnique({
      where: { userId },
      include: { shop: true }
    });
    return barber?.shop || null;
  }

  async upsertBarberProfile(userId: string, shopId: string) {
    return prisma.barber.upsert({
      where: { userId },
      update: { shopId },
      create: { userId, shopId }
    });
  }

  async createService(shopId: string, data: { name: string; description: string | null; durationMinutes: number; price: number }) {
    return prisma.service.create({ data: { shopId, ...data } });
  }

  async updateService(serviceId: string, data: Prisma.ServiceUpdateInput) {
    return prisma.service.update({ where: { id: serviceId }, data });
  }

  async deleteService(serviceId: string) {
    return prisma.service.update({
      where: { id: serviceId },
      data: { isActive: false satisfies boolean }
    });
  }

  async createChair(shopId: string, data: { number: number }) {
    return prisma.chair.create({ data: { shopId, ...data } });
  }

  async updateChair(chairId: string, data: Prisma.ChairUpdateInput) {
    return prisma.chair.update({ where: { id: chairId }, data });
  }

  async searchShops(params: ShopSearchParams): Promise<PaginationResult<Shop>> {
    const { page, limit, query, city, isActive, latitude, longitude, radiusKm } = params;
    const skip = (page - 1) * limit;

    const where: Prisma.ShopWhereInput = {};

    if (query) {
      where.OR = [
        { name: { contains: query, mode: "insensitive" } },
        { city: { contains: query, mode: "insensitive" } },
        { description: { contains: query, mode: "insensitive" } }
      ];
    }

    if (city) {
      where.city = { contains: city, mode: "insensitive" };
    }

    if (isActive !== undefined) {
      where.isActive = isActive;
    }

    if (latitude !== undefined && longitude !== undefined && radiusKm !== undefined) {
      where.AND = [
        {
          latitude: { gte: latitude - radiusKm / 111, lte: latitude + radiusKm / 111 }
        },
        {
          longitude: { gte: longitude - radiusKm / 111, lte: longitude + radiusKm / 111 }
        }
      ];
    }

    const [data, total] = await Promise.all([
      prisma.shop.findMany({
        where,
        skip,
        take: limit,
        include: {
          services: { where: { isActive: true } },
          chairs: true
        },
        orderBy: { createdAt: "desc" }
      }),
      prisma.shop.count({ where })
    ]);

    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit)
    };
  }

  async searchServices(params: ServiceSearchParams): Promise<PaginationResult<any>> {
    const { page, limit, shopId, query, isActive } = params;
    const skip = (page - 1) * limit;

    const where: Prisma.ServiceWhereInput = { shopId };

    if (query) {
      where.OR = [
        { name: { contains: query, mode: "insensitive" } },
        { description: { contains: query, mode: "insensitive" } }
      ];
    }

    if (isActive !== undefined) {
      where.isActive = isActive;
    }

    const [data, total] = await Promise.all([
      prisma.service.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: "asc" }
      }),
      prisma.service.count({ where })
    ]);

    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit)
    };
  }
}
