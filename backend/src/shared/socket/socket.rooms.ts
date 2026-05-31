export const socketRooms = {
  shop: (shopId: string) => `shop:${shopId}`,
  barber: (barberId: string) => `barber:${barberId}`,
  booking: (bookingId: string) => `booking:${bookingId}`,
  user: (userId: string) => `user:${userId}`,
  /** @deprecated use user() */
  customer: (customerId: string) => `user:${customerId}`,
  admin: () => "admins"
} as const;
