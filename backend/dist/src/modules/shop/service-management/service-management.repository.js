import { Prisma } from "@prisma/client";
import { prisma } from "../../../shared/prisma/client.js";
function slugify(value) {
    return value
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-+|-+$/g, "");
}
export class PrismaServiceManagementRepository {
    async findShopById(shopId) {
        return prisma.shop.findUnique({ where: { id: shopId } });
    }
    async findServiceById(serviceId) {
        return prisma.shopService.findUnique({
            where: { id: serviceId },
            include: { shop: true, barber: true, comboItems: true }
        });
    }
    async createService(shopId, input) {
        const slug = slugify(input.name);
        const estimatedDurationMin = input.isCombo
            ? input.durationMin
            : Math.max(input.durationMin, 5);
        return prisma.shopService.create({
            data: {
                shopId,
                name: input.name,
                slug,
                description: input.description,
                durationMin: input.durationMin,
                estimatedDurationMin,
                price: new Prisma.Decimal(input.price),
                category: input.category,
                barberId: input.barberId,
                isBarberSpecific: input.isBarberSpecific,
                isCombo: input.isCombo
            }
        });
    }
    async updateService(serviceId, input) {
        return prisma.shopService.update({
            where: { id: serviceId },
            data: {
                name: input.name,
                slug: input.name ? slugify(input.name) : undefined,
                description: input.description,
                durationMin: input.durationMin,
                estimatedDurationMin: input.durationMin ? Math.max(input.durationMin, 5) : undefined,
                price: input.price === undefined ? undefined : new Prisma.Decimal(input.price),
                category: input.category,
                barberId: input.barberId,
                isBarberSpecific: input.isBarberSpecific,
                isCombo: input.isCombo,
                status: input.status
            }
        });
    }
    async deleteService(serviceId) {
        return prisma.shopService.update({
            where: { id: serviceId },
            data: { status: "INACTIVE" }
        });
    }
    async replaceComboItems(comboServiceId, items) {
        return prisma.$transaction([
            prisma.shopServiceComboItem.deleteMany({ where: { comboServiceId } }),
            prisma.shopServiceComboItem.createMany({
                data: items.map((item) => ({
                    comboServiceId,
                    itemServiceId: item.serviceId,
                    quantity: item.quantity
                }))
            })
        ]);
    }
}
