export const socketRooms = {
    shop: (shopId) => `shop:${shopId}`,
    barber: (barberId) => `barber:${barberId}`,
    booking: (bookingId) => `booking:${bookingId}`,
    user: (userId) => `user:${userId}`,
    /** @deprecated use user() */
    customer: (customerId) => `user:${customerId}`,
    admin: () => "admins"
};
