import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
});

async function testFlow1() {
  console.log("=== FLOW 1: BARBER ONBOARDING ===\n");

  try {
    // Step 1: Register Barber
    console.log("Step 1: Register Barber");
    const hashedPassword = await bcrypt.hash("password123", 12);
    const barberUser = await prisma.user.create({
      data: {
        fullName: "Test Barber",
        email: "barber@test.com",
        password: hashedPassword,
        role: "BARBER",
        phoneNumber: "+1234567890"
      }
    });
    console.log("✓ Barber user created:", barberUser.id);

    // Step 2: Create Shop
    console.log("\nStep 2: Create Shop");
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

    // Step 3: Create Barber profile
    console.log("\nStep 3: Create Barber profile");
    const barber = await prisma.barber.create({
      data: {
        userId: barberUser.id,
        shopId: shop.id
      }
    });
    console.log("✓ Barber profile created:", barber.id);

    // Step 4: Create Service
    console.log("\nStep 4: Create Service");
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

    // Step 5: Create Chair
    console.log("\nStep 5: Create Chair");
    const chair = await prisma.chair.create({
      data: {
        shopId: shop.id,
        number: 1,
        status: "AVAILABLE"
      }
    });
    console.log("✓ Chair created:", chair.id);

    console.log("\n=== FLOW 1: PASSED ===\n");

    // Cleanup
    console.log("Cleaning up test data...");
    await prisma.chair.delete({ where: { id: chair.id } });
    await prisma.service.delete({ where: { id: service.id } });
    await prisma.barber.delete({ where: { id: barber.id } });
    await prisma.shop.delete({ where: { id: shop.id } });
    await prisma.user.delete({ where: { id: barberUser.id } });
    console.log("✓ Cleanup complete");

  } catch (error) {
    console.error("\n=== FLOW 1: FAILED ===");
    console.error("Error:", error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

testFlow1().catch(console.error);
