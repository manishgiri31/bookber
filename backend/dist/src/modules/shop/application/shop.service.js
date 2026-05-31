import { Errors } from "../../../shared/http/app-error.js";
function makeShopSlug(name) {
    const base = name
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-+|-+$/g, "")
        .slice(0, 48);
    return `${base || "shop"}-${Date.now().toString(36)}`;
}
function assertBarberOrAdmin(user) {
    if (user.role !== "BARBER" && user.role !== "ADMIN") {
        throw Errors.forbidden();
    }
}
async function assertShopOwnership(user, shopId, repository) {
    if (user.role === "ADMIN")
        return;
    const barberShop = await repository.findShopByBarber(user.id);
    if (!barberShop || barberShop.id !== shopId) {
        throw Errors.forbidden();
    }
}
export class ShopService {
    repository;
    constructor(repository) {
        this.repository = repository;
    }
    async createShop(user, dto) {
        assertBarberOrAdmin(user);
        const existing = await this.repository.findShopByBarber(user.id);
        if (existing && user.role !== "ADMIN") {
            throw Errors.conflict("Barber already has a shop");
        }
        return this.repository.createShop({
            name: dto.name,
            slug: makeShopSlug(dto.name),
            description: dto.description ?? null,
            address: dto.address,
            city: dto.city,
            state: dto.state,
            country: dto.country,
            latitude: dto.latitude,
            longitude: dto.longitude,
            openingTime: dto.openingTime ?? null,
            closingTime: dto.closingTime ?? null,
            isActive: true,
            owner: { connect: { id: user.id } },
            services: {
                create: dto.services.map((service) => ({
                    name: service.name,
                    description: service.description ?? null,
                    durationMinutes: service.durationMinutes,
                    price: service.price
                }))
            },
            chairs: {
                create: dto.chairs.map((chair) => ({
                    number: chair.number
                }))
            }
        });
    }
    async updateShop(user, shopId, dto) {
        const shop = await this.repository.findShopById(shopId);
        if (!shop)
            throw Errors.notFound();
        await assertShopOwnership(user, shopId, this.repository);
        const updateData = {};
        if (dto.name !== undefined)
            updateData.name = dto.name;
        if (dto.description !== undefined)
            updateData.description = dto.description;
        if (dto.address !== undefined)
            updateData.address = dto.address;
        if (dto.city !== undefined)
            updateData.city = dto.city;
        if (dto.state !== undefined)
            updateData.state = dto.state;
        if (dto.country !== undefined)
            updateData.country = dto.country;
        if (dto.latitude !== undefined)
            updateData.latitude = dto.latitude;
        if (dto.longitude !== undefined)
            updateData.longitude = dto.longitude;
        if (dto.openingTime !== undefined)
            updateData.openingTime = dto.openingTime;
        if (dto.closingTime !== undefined)
            updateData.closingTime = dto.closingTime;
        if (dto.isActive !== undefined)
            updateData.isActive = dto.isActive;
        return this.repository.updateShop(shopId, updateData);
    }
    async getShop(shopId) {
        const shop = await this.repository.findShopById(shopId);
        if (!shop)
            throw Errors.notFound();
        return shop;
    }
    async searchShops(dto) {
        const searchParams = {
            page: dto.page,
            limit: dto.limit
        };
        if (dto.query !== undefined)
            searchParams.query = dto.query;
        if (dto.city !== undefined)
            searchParams.city = dto.city;
        if (dto.isActive !== undefined)
            searchParams.isActive = dto.isActive;
        if (dto.latitude !== undefined)
            searchParams.latitude = dto.latitude;
        if (dto.longitude !== undefined)
            searchParams.longitude = dto.longitude;
        if (dto.radiusKm !== undefined)
            searchParams.radiusKm = dto.radiusKm;
        return this.repository.searchShops(searchParams);
    }
    async getMyShop(user) {
        return this.repository.findShopByBarber(user.id);
    }
    async createService(user, shopId, dto) {
        const shop = await this.repository.findShopById(shopId);
        if (!shop)
            throw Errors.notFound();
        await assertShopOwnership(user, shopId, this.repository);
        return this.repository.createService(shopId, {
            name: dto.name,
            description: dto.description ?? null,
            durationMinutes: dto.durationMinutes,
            price: dto.price
        });
    }
    async updateService(user, serviceId, dto) {
        const service = await this.repository.findServiceById(serviceId);
        if (!service)
            throw Errors.notFound();
        await assertShopOwnership(user, service.shopId, this.repository);
        const updateData = {};
        if (dto.name !== undefined)
            updateData.name = dto.name;
        if (dto.description !== undefined)
            updateData.description = dto.description;
        if (dto.durationMinutes !== undefined)
            updateData.durationMinutes = dto.durationMinutes;
        if (dto.price !== undefined)
            updateData.price = dto.price;
        if (dto.isActive !== undefined)
            updateData.isActive = dto.isActive;
        return this.repository.updateService(serviceId, updateData);
    }
    async deleteService(user, serviceId) {
        const service = await this.repository.findServiceById(serviceId);
        if (!service)
            throw Errors.notFound();
        await assertShopOwnership(user, service.shopId, this.repository);
        return this.repository.deleteService(serviceId);
    }
    async searchServices(shopId, dto) {
        const searchParams = {
            shopId,
            page: dto.page,
            limit: dto.limit
        };
        if (dto.query !== undefined)
            searchParams.query = dto.query;
        if (dto.isActive !== undefined)
            searchParams.isActive = dto.isActive;
        return this.repository.searchServices(searchParams);
    }
    async addChair(user, shopId, dto) {
        const shop = await this.repository.findShopById(shopId);
        if (!shop)
            throw Errors.notFound();
        await assertShopOwnership(user, shopId, this.repository);
        return this.repository.createChair(shopId, dto);
    }
    async updateChair(user, chairId, dto) {
        const chair = await this.repository.findChairById(chairId);
        if (!chair)
            throw Errors.notFound();
        await assertShopOwnership(user, chair.shopId, this.repository);
        const updateData = {};
        if (dto.number !== undefined)
            updateData.number = dto.number;
        if (dto.status !== undefined)
            updateData.status = dto.status;
        return this.repository.updateChair(chairId, updateData);
    }
}
