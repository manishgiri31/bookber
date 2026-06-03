console.log("Starting FLOW 4 test...");
console.log("DATABASE_URL:", process.env.DATABASE_URL);

try {
  const { PrismaClient } = require('@prisma/client');
  const { PrismaPg } = require('@prisma/adapter-pg');
  console.log("✓ PrismaClient imported");

  const bcrypt = require('bcrypt');
  console.log("✓ bcrypt imported");

  const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL });
  const prisma = new PrismaClient({
    adapter,
    log: [
      { emit: 'event', level: 'error' },
      { emit: 'event', level: 'warn' },
      { emit: 'event', level: 'query' }
    ]
  });
  console.log("✓ PrismaClient created");

  async function testFlow4() {
    console.log("=== FLOW 4: PAYMENT + REVIEW ===\n");

    try {
      // Setup: Create customer, barber, shop, service, chair, booking
      console.log("Setup: Creating test data...");
      const customerPassword = await bcrypt.hash("password123", 12);
      const customerUser = await prisma.user.create({
        data: {
          fullName: "Test Customer",
          email: `customer-${Date.now()}@test.com`,
          password: customerPassword,
          role: "CLIENT",
          phoneNumber: `+1${Date.now()}`
        }
      });
      console.log("✓ Customer user created:", customerUser.id);

      const barberPassword = await bcrypt.hash("barberpass", 12);
      const barberUser = await prisma.user.create({
        data: {
          fullName: "Test Barber",
          email: `barber-${Date.now()}@test.com`,
          password: barberPassword,
          role: "BARBER",
          phoneNumber: `+1${Date.now() + 1}`
        }
      });
      console.log("✓ Barber user created:", barberUser.id);

      const shop = await prisma.shop.create({
        data: {
          name: "Test Barber Shop",
          description: "A test shop",
          address: "123 Test Street",
          city: "Test City",
          state: "Test State",
          country: "Test Country",
          latitude: 40.7128,
          longitude: -74.0060,
          ownerId: barberUser.id,
          slug: "test-barber-shop-" + Date.now()
        }
      });
      console.log("✓ Shop created:", shop.id);

      const barber = await prisma.barber.create({
        data: {
          userId: barberUser.id,
          shopId: shop.id
        }
      });
      console.log("✓ Barber profile created:", barber.id);

      const service = await prisma.service.create({
        data: {
          shopId: shop.id,
          name: "Haircut",
          description: "Basic haircut",
          price: 20.0,
          durationMinutes: 30,
          category: "HAIRCUT"
        }
      });
      console.log("✓ Service created:", service.id);

      const chair = await prisma.chair.create({
        data: {
          shopId: shop.id,
          number: 1,
          status: "AVAILABLE"
        }
      });
      console.log("✓ Chair created:", chair.id);

      const scheduledTime = new Date(Date.now() + 24 * 60 * 60 * 1000);
      const booking = await prisma.booking.create({
        data: {
          userId: customerUser.id,
          shopId: shop.id,
          serviceId: service.id,
          barberId: barber.id,
          chairId: chair.id,
          arrivalWindowStart: new Date(scheduledTime.getTime() - 15 * 60 * 1000),
          arrivalWindowEnd: new Date(scheduledTime.getTime() + 15 * 60 * 1000),
          status: "COMPLETED"
        }
      });
      console.log("✓ Booking created:", booking.id);

      // Step 1: Create Payment
      console.log("\nStep 1: Create Payment");
      const payment = await prisma.payment.create({
        data: {
          bookingId: booking.id,
          amount: 20.0,
          method: "CARD",
          status: "PAID",
          completedAt: new Date()
        }
      });
      console.log("✓ Payment created:", payment.id);

      // Step 2: Submit Review
      console.log("\nStep 2: Submit Review");
      const review = await prisma.review.create({
        data: {
          userId: customerUser.id,
          shopId: shop.id,
          rating: 5,
          comment: "Great service!"
        }
      });
      console.log("✓ Review created:", review.id);

      console.log("\n=== FLOW 4: PASSED ===\n");

      // Cleanup
      console.log("Cleaning up test data...");
      await prisma.review.delete({ where: { id: review.id } });
      await prisma.payment.delete({ where: { id: payment.id } });
      await prisma.booking.delete({ where: { id: booking.id } });
      await prisma.chair.delete({ where: { id: chair.id } });
      await prisma.service.delete({ where: { id: service.id } });
      await prisma.barber.delete({ where: { id: barber.id } });
      await prisma.shop.delete({ where: { id: shop.id } });
      await prisma.user.delete({ where: { id: barberUser.id } });
      await prisma.user.delete({ where: { id: customerUser.id } });
      console.log("✓ Cleanup complete");

    } catch (error) {
      console.error("\n=== FLOW 4: FAILED ===");
      console.error("Error:", error);
      console.error("Stack:", error.stack);
      throw error;
    } finally {
      await prisma.$disconnect();
    }
  }

  testFlow4().catch(console.error);
} catch (error) {
  console.error("INITIALIZATION ERROR:", error);
  console.error("Stack:", error.stack);
  process.exit(1);
}
