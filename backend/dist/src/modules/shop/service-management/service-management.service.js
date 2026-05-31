import { Errors } from "../../../shared/http/app-error.js";
function assertShopOwnerOrAdmin(user, ownerId) {
    if (user.role !== "ADMIN" && user.id !== ownerId) {
        throw Errors.forbidden();
    }
}
export class ServiceManagementService {
    repository;
    constructor(repository) {
        this.repository = repository;
    }
    async addService(user, shopId, dto) {
        const shop = await this.repository.findShopById(shopId);
        if (!shop)
            throw Errors.notFound("Shop not found");
        assertShopOwnerOrAdmin(user, shop.ownerId);
        if (dto.isBarberSpecific && !dto.barberId) {
            throw Errors.validation("barberId is required for barber-specific services");
        }
        const service = await this.repository.createService(shopId, dto);
        if (dto.isCombo && dto.comboItems.length > 0) {
            await this.repository.replaceComboItems(service.id, dto.comboItems);
        }
        return service;
    }
    async updateService(user, serviceId, dto) {
        const service = await this.repository.findServiceById(serviceId);
        if (!service)
            throw Errors.notFound("Service not found");
        assertShopOwnerOrAdmin(user, service.shop.ownerId);
        const updated = await this.repository.updateService(serviceId, dto);
        if (dto.comboItems) {
            await this.repository.replaceComboItems(serviceId, dto.comboItems);
        }
        return updated;
    }
    async deleteService(user, serviceId) {
        const service = await this.repository.findServiceById(serviceId);
        if (!service)
            throw Errors.notFound("Service not found");
        assertShopOwnerOrAdmin(user, service.shop.ownerId);
        return this.repository.deleteService(serviceId);
    }
    getDuration(service) {
        if (!service.isCombo)
            return service.durationMin;
        return (service.durationMin +
            (service.comboItems ?? []).reduce((total, item) => total + (item.itemService?.durationMin ?? 0) * item.quantity, 0));
    }
    getPrice(service) {
        if (!service.isCombo)
            return service.price;
        const total = (service.comboItems ?? []).reduce((sum, item) => {
            const unit = item.itemService?.price ? item.itemService.price.toNumber() : 0;
            return sum + unit * item.quantity;
        }, 0);
        return total;
    }
}
