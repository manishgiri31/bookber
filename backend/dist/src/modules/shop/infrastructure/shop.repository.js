import { prisma } from "../../../shared/prisma/client.js";
export class PrismaShopRepository {
    async createShop(data) {
        return prisma.shop.create({ data });
    }
    async updateShop(shopId, data) {
        return prisma.shop.update({ where: { id: shopId }, data });
    }
    async findShopById(shopId) {
        return prisma.shop.findUnique({
            where: { id: shopId },
            include: {
                services: { where: { isActive: true } },
                chairs: true
            }
        });
    }
    async findChairById(chairId) {
        return prisma.chair.findUnique({
            where: { id: chairId },
            include: { shop: true }
        });
    }
    async findServiceById(serviceId) {
        return prisma.service.findUnique({
            where: { id: serviceId }
        });
    }
    async findShopByBarber(barberId) {
        const barber = await prisma.barber.findUnique({
            where: { id: barberId },
            include: { shop: true }
        });
        return barber?.shop || null;
    }
    async createService(shopId, data) {
        return prisma.service.create({ data: { shopId, ...data } });
    }
    async updateService(serviceId, data) {
        return prisma.service.update({ where: { id: serviceId }, data });
    }
    async deleteService(serviceId) {
        return prisma.service.update({
            where: { id: serviceId },
            data: { isActive: false }
        });
    }
    async createChair(shopId, data) {
        return prisma.chair.create({ data: { shopId, ...data } });
    }
    async updateChair(chairId, data) {
        return prisma.chair.update({ where: { id: chairId }, data });
    }
    async searchShops(params) {
        const { page, limit, query, city, isActive, latitude, longitude, radiusKm } = params;
        const skip = (page - 1) * limit;
        const where = {};
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
    async searchServices(params) {
        const { page, limit, shopId, query, isActive } = params;
        const skip = (page - 1) * limit;
        const where = { shopId };
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
