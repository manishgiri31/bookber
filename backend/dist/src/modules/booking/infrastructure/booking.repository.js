export class PrismaBookingRepository {
    async findShopForUpdate(db, shopId) {
        await db.$queryRaw `SELECT id FROM "Shop" WHERE id = ${shopId} FOR UPDATE`;
    }
    async findServiceById(db, serviceId) {
        return db.service.findUnique({
            where: { id: serviceId },
            include: { shop: true }
        });
    }
    async findShopById(db, shopId) {
        return db.shop.findUnique({
            where: { id: shopId },
            include: { chairs: true, operatingHours: true }
        });
    }
    async findBookingById(db, bookingId) {
        return db.booking.findUnique({
            where: { id: bookingId },
            include: {
                shop: true,
                user: true,
                barber: { include: { user: true } },
                chair: true,
                service: true,
                queueEntry: true
            }
        });
    }
    async findActiveBookingsForShop(db, shopId) {
        return db.booking.findMany({
            where: {
                shopId,
                status: { in: ["QUEUED", "READY", "CALLED", "IN_SERVICE"] }
            },
            orderBy: { queueEntry: { position: "asc" } },
            include: {
                user: true,
                service: true,
                barber: { include: { user: true } },
                chair: true,
                queueEntry: true
            }
        });
    }
    async findActiveBookingForUser(db, userId, shopId) {
        return db.booking.findFirst({
            where: {
                userId,
                shopId,
                status: { in: ["QUEUED", "READY", "CALLED", "IN_SERVICE"] }
            }
        });
    }
}
