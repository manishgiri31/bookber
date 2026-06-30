// @ts-nocheck
import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import {
  UserRole,
  BookingStatus,
  ChairStatus,
  QueueStatus,
  QueueLane,
  ServiceCategory,
  PaymentMethod,
  PaymentStatus,
  QueueEventType,
} from "@prisma/client";
import bcrypt from "bcrypt";

const adapter = new PrismaPg({ connectionString: process.env["DATABASE_URL"]! });
const prisma = new PrismaClient({ adapter });

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const SEED_PASSWORD = "Bookber@123";

function daysAgo(d: number): Date {
  return new Date(Date.now() - d * 24 * 60 * 60 * 1000);
}

function minutesAgo(m: number): Date {
  return new Date(Date.now() - m * 60 * 1000);
}

function minutesFromNow(m: number): Date {
  return new Date(Date.now() + m * 60 * 1000);
}

function addMinutes(base: Date, m: number): Date {
  return new Date(base.getTime() + m * 60 * 1000);
}

/** findFirst-then-create (for models with no natural unique key on name+shopId). */
async function upsertService(
  shopId: string,
  data: {
    name: string;
    description: string;
    price: number;
    durationMinutes: number;
    category: ServiceCategory;
    rebookIntervalDays?: number;
  }
) {
  const existing = await prisma.service.findFirst({ where: { shopId, name: data.name } });
  if (existing) return existing;
  return prisma.service.create({ data: { shopId, isActive: true, ...data } });
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  console.log("🌱  BookBer seed starting …\n");

  // ─────────────────────────────────────────────────────────
  // 1. USERS
  // ─────────────────────────────────────────────────────────

  const hash = await bcrypt.hash(SEED_PASSWORD, 10);

  console.log("👤  Creating users …");

  const admin = await prisma.user.upsert({
    where: { email: "admin@bookber.dev" },
    update: {},
    create: {
      fullName: "BookBer Admin",
      email: "admin@bookber.dev",
      password: hash,
      role: UserRole.ADMIN,
      phoneNumber: "+919000000001",
    },
  });

  const owner1 = await prisma.user.upsert({
    where: { email: "owner.marcus@bookber.dev" },
    update: { role: UserRole.OWNER },
    create: {
      fullName: "Marcus Thompson",
      email: "owner.marcus@bookber.dev",
      password: hash,
      role: UserRole.OWNER,
      phoneNumber: "+919000000002",
    },
  });

  const owner2 = await prisma.user.upsert({
    where: { email: "owner.james@bookber.dev" },
    update: { role: UserRole.OWNER },
    create: {
      fullName: "James Rivera",
      email: "owner.james@bookber.dev",
      password: hash,
      role: UserRole.OWNER,
      phoneNumber: "+919000000003",
    },
  });

  const receptionUser1 = await prisma.user.upsert({
    where: { email: "reception.sara@bookber.dev" },
    update: { role: UserRole.RECEPTION },
    create: {
      fullName: "Sara Menon",
      email: "reception.sara@bookber.dev",
      password: hash,
      role: UserRole.RECEPTION,
      phoneNumber: "+919000000007",
    },
  });

  const barberUser1 = await prisma.user.upsert({
    where: { email: "barber.alex@bookber.dev" },
    update: { role: UserRole.BARBER },
    create: {
      fullName: "Alex Carter",
      email: "barber.alex@bookber.dev",
      password: hash,
      role: UserRole.BARBER,
      phoneNumber: "+919000000004",
    },
  });

  const barberUser2 = await prisma.user.upsert({
    where: { email: "barber.sam@bookber.dev" },
    update: { role: UserRole.BARBER },
    create: {
      fullName: "Sam Okonkwo",
      email: "barber.sam@bookber.dev",
      password: hash,
      role: UserRole.BARBER,
      phoneNumber: "+919000000005",
    },
  });

  const barberUser3 = await prisma.user.upsert({
    where: { email: "barber.mike@bookber.dev" },
    update: { role: UserRole.BARBER },
    create: {
      fullName: "Mike Delacroix",
      email: "barber.mike@bookber.dev",
      password: hash,
      role: UserRole.BARBER,
      phoneNumber: "+919000000006",
    },
  });

  const customerDefs = [
    { fullName: "Ravi Sharma", email: "customer.ravi@bookber.dev", phoneNumber: "+919100000001" },
    { fullName: "Priya Nair", email: "customer.priya@bookber.dev", phoneNumber: "+919100000002" },
    { fullName: "Arjun Mehta", email: "customer.arjun@bookber.dev", phoneNumber: "+919100000003" },
    { fullName: "Kiran Patel", email: "customer.kiran@bookber.dev", phoneNumber: "+919100000004" },
    { fullName: "Deepak Gupta", email: "customer.deepak@bookber.dev", phoneNumber: "+919100000005" },
    { fullName: "Sneha Reddy", email: "customer.sneha@bookber.dev", phoneNumber: "+919100000006" },
    { fullName: "Rahul Verma", email: "customer.rahul@bookber.dev", phoneNumber: "+919100000007" },
    { fullName: "Anita Singh", email: "customer.anita@bookber.dev", phoneNumber: "+919100000008" },
    { fullName: "Vijay Kumar", email: "customer.vijay@bookber.dev", phoneNumber: "+919100000009" },
    { fullName: "Neha Joshi", email: "customer.neha@bookber.dev", phoneNumber: "+919100000010" },
  ] as const;

  const customers = await Promise.all(
    customerDefs.map((c) =>
      prisma.user.upsert({
        where: { email: c.email },
        update: {},
        create: { ...c, password: hash, role: UserRole.CLIENT },
      })
    )
  );

  console.log(
    `   ✓  1 admin · 2 owners · 1 reception · 3 barbers · ${customers.length} customers  (total ${1 + 2 + 1 + 3 + customers.length})`
  );

  // ─────────────────────────────────────────────────────────
  // 2. SHOPS
  // ─────────────────────────────────────────────────────────

  console.log("\n🏪  Creating shops …");

  const shop1 = await prisma.shop.upsert({
    where: { slug: "the-classic-barber" },
    update: {},
    create: {
      name: "The Classic Barber",
      slug: "the-classic-barber",
      description:
        "Premium grooming services with a classic touch. Walk-ins always welcome.",
      address: "12, Linking Road",
      addressLine2: "Bandra West",
      city: "Mumbai",
      state: "Maharashtra",
      country: "India",
      postalCode: "400050",
      latitude: 19.0596,
      longitude: 72.8295,
      phone: "+912226001234",
      email: "hello@theclassicbarber.in",
      openingTime: "09:00",
      closingTime: "21:00",
      timezone: "Asia/Kolkata",
      isActive: true,
      isAcceptingBookings: true,
      isAcceptingWalkIns: true,
      bookBerReservedChairCount: 2,
      ownerId: owner1.id,
    },
  });

  const shop2 = await prisma.shop.upsert({
    where: { slug: "kings-cut-lounge" },
    update: {},
    create: {
      name: "Kings Cut Lounge",
      slug: "kings-cut-lounge",
      description:
        "South Delhi's finest barbershop. Precision cuts, expert beards, no waiting apps.",
      address: "Block B-14, Green Park Market",
      city: "Delhi",
      state: "Delhi",
      country: "India",
      postalCode: "110016",
      latitude: 28.559,
      longitude: 77.2088,
      phone: "+911126001234",
      email: "contact@kingscut.in",
      openingTime: "10:00",
      closingTime: "20:30",
      timezone: "Asia/Kolkata",
      isActive: true,
      isAcceptingBookings: true,
      isAcceptingWalkIns: true,
      bookBerReservedChairCount: 1,
      ownerId: owner2.id,
    },
  });

  console.log(`   ✓  ${shop1.name}  (Mumbai)`);
  console.log(`   ✓  ${shop2.name}  (Delhi)`);

  // ─────────────────────────────────────────────────────────
  // 3. OPERATING HOURS
  // ─────────────────────────────────────────────────────────

  console.log("\n🕐  Setting operating hours …");

  type ShopHourDef = { openTime: string; closeTime: string; closedOn: string[] };
  const hoursByShop: Record<string, ShopHourDef> = {
    [shop1.id]: { openTime: "09:00", closeTime: "21:00", closedOn: ["SUNDAY"] },
    [shop2.id]: { openTime: "10:00", closeTime: "20:30", closedOn: ["SUNDAY"] },
  };

  const DAYS = [
    "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY",
  ] as const;

  for (const shop of [shop1, shop2]) {
    const def = hoursByShop[shop.id];
    for (const day of DAYS) {
      const isClosed = def.closedOn.includes(day);
      await prisma.shopOperatingHour.upsert({
        where: { shopId_dayOfWeek: { shopId: shop.id, dayOfWeek: day } },
        update: {},
        create: {
          shopId: shop.id,
          dayOfWeek: day,
          openTime: def.openTime,
          closeTime: def.closeTime,
          isClosed,
        },
      });
    }
  }

  console.log("   ✓  7 days × 2 shops");

  // ─────────────────────────────────────────────────────────
  // 4. SHOP PHOTOS
  // ─────────────────────────────────────────────────────────

  console.log("\n📸  Adding shop photos …");

  const photoDefs = [
    {
      url: "https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800",
      caption: "Reception and waiting area",
      sortOrder: 0,
    },
    {
      url: "https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=800",
      caption: "Premium styling chairs",
      sortOrder: 1,
    },
    {
      url: "https://images.unsplash.com/photo-1567894340315-735d7c361db0?w=800",
      caption: "Professional grooming tools",
      sortOrder: 2,
    },
  ];

  for (const shop of [shop1, shop2]) {
    const count = await prisma.shopPhoto.count({ where: { shopId: shop.id } });
    if (count === 0) {
      await prisma.shopPhoto.createMany({
        data: photoDefs.map((p) => ({ shopId: shop.id, ...p })),
      });
    }
  }

  console.log("   ✓  3 photos × 2 shops");

  // ─────────────────────────────────────────────────────────
  // 5. CHAIRS
  // ─────────────────────────────────────────────────────────

  console.log("\n💺  Creating chairs …");

  type ChairDef = { number: number; reservedForBookBer: boolean };

  async function upsertChairs(shopId: string, defs: ChairDef[]) {
    const chairs = [];
    for (const def of defs) {
      const c = await prisma.chair.upsert({
        where: { shopId_number: { shopId, number: def.number } },
        update: {},
        create: {
          shopId,
          number: def.number,
          reservedForBookBer: def.reservedForBookBer,
          status: ChairStatus.AVAILABLE,
        },
      });
      chairs.push(c);
    }
    return chairs;
  }

  // Shop 1: 4 chairs — chair 1 & 2 reserved for BookBer advance bookings
  const chairs1 = await upsertChairs(shop1.id, [
    { number: 1, reservedForBookBer: true },
    { number: 2, reservedForBookBer: true },
    { number: 3, reservedForBookBer: false },
    { number: 4, reservedForBookBer: false },
  ]);

  // Shop 2: 3 chairs — chair 1 reserved for BookBer
  const chairs2 = await upsertChairs(shop2.id, [
    { number: 1, reservedForBookBer: true },
    { number: 2, reservedForBookBer: false },
    { number: 3, reservedForBookBer: false },
  ]);

  console.log(`   ✓  ${chairs1.length} chairs (shop1) · ${chairs2.length} chairs (shop2)`);

  // ─────────────────────────────────────────────────────────
  // 6. SERVICES
  // ─────────────────────────────────────────────────────────

  console.log("\n✂️   Creating services …");

  type ServiceDef = {
    name: string;
    description: string;
    price: number;
    durationMinutes: number;
    category: ServiceCategory;
    rebookIntervalDays?: number;
  };

  const serviceDefs: ServiceDef[] = [
    {
      name: "Classic Haircut",
      description: "Clean scissors cut with wash and blow dry",
      price: 250,
      durationMinutes: 30,
      category: ServiceCategory.HAIRCUT,
      rebookIntervalDays: 30,
    },
    {
      name: "Beard Trim",
      description: "Shape, define and trim beard to perfection",
      price: 150,
      durationMinutes: 20,
      category: ServiceCategory.BEARD,
      rebookIntervalDays: 14,
    },
    {
      name: "Haircut + Beard Combo",
      description: "Full haircut paired with expert beard shaping",
      price: 350,
      durationMinutes: 45,
      category: ServiceCategory.COMBO,
      rebookIntervalDays: 21,
    },
    {
      name: "Premium Grooming Package",
      description: "Hot towel shave, precision cut, styling and conditioning treatment",
      price: 600,
      durationMinutes: 60,
      category: ServiceCategory.COMBO,
    },
    {
      name: "Kids Haircut",
      description: "Gentle, fun haircut for kids under 12",
      price: 180,
      durationMinutes: 25,
      category: ServiceCategory.HAIRCUT,
      rebookIntervalDays: 30,
    },
  ];

  const services1 = await Promise.all(serviceDefs.map((s) => upsertService(shop1.id, s)));
  const services2 = await Promise.all(serviceDefs.map((s) => upsertService(shop2.id, s)));

  console.log(`   ✓  ${services1.length} services × 2 shops`);

  // ─────────────────────────────────────────────────────────
  // 7. BARBERS
  // ─────────────────────────────────────────────────────────

  console.log("\n💈  Creating barbers …");

  const barber1 = await prisma.barber.upsert({
    where: { userId: barberUser1.id },
    update: {},
    create: {
      userId: barberUser1.id,
      shopId: shop1.id,
      bio: "10 years of classic barbering. Specialist in fades and traditional cuts.",
      experienceYears: 10,
      rating: 4.8,
      isAvailable: true,
      serviceSpeedFactor: 0.95,
      averageServiceMinutes: 28,
    },
  });

  const barber2 = await prisma.barber.upsert({
    where: { userId: barberUser2.id },
    update: {},
    create: {
      userId: barberUser2.id,
      shopId: shop1.id,
      bio: "Master of textured cuts and beard artistry — 7 years experience.",
      experienceYears: 7,
      rating: 4.6,
      isAvailable: true,
      serviceSpeedFactor: 1.0,
      averageServiceMinutes: 32,
    },
  });

  const barber3 = await prisma.barber.upsert({
    where: { userId: barberUser3.id },
    update: {},
    create: {
      userId: barberUser3.id,
      shopId: shop2.id,
      bio: "French-trained barber bringing European precision to every cut.",
      experienceYears: 8,
      rating: 4.9,
      isAvailable: true,
      serviceSpeedFactor: 1.1,
      averageServiceMinutes: 35,
    },
  });

  console.log(
    `   ✓  Alex (shop1) · Sam (shop1) · Mike (shop2)`
  );

  // ─────────────────────────────────────────────────────────
  // 7b. SHOP STAFF (owner + reception linkage)
  // ─────────────────────────────────────────────────────────

  console.log("\n👥  Linking shop staff …");

  await prisma.shopStaff.upsert({
    where: { shopId_userId: { shopId: shop1.id, userId: owner1.id } },
    update: {},
    create: { shopId: shop1.id, userId: owner1.id },
  });
  await prisma.shopStaff.upsert({
    where: { shopId_userId: { shopId: shop2.id, userId: owner2.id } },
    update: {},
    create: { shopId: shop2.id, userId: owner2.id },
  });
  // Reception staff assigned to shop1
  await prisma.shopStaff.upsert({
    where: { shopId_userId: { shopId: shop1.id, userId: receptionUser1.id } },
    update: {},
    create: { shopId: shop1.id, userId: receptionUser1.id },
  });

  console.log("   ✓  Marcus → shop1 · James → shop2 · Sara (reception) → shop1");

  // ─────────────────────────────────────────────────────────
  // 8. BARBER ↔ SERVICE LINKS
  // ─────────────────────────────────────────────────────────

  console.log("\n🔗  Linking barbers to services …");

  for (const service of services1) {
    for (const barber of [barber1, barber2]) {
      await prisma.barberService.upsert({
        where: { barberId_serviceId: { barberId: barber.id, serviceId: service.id } },
        update: {},
        create: { barberId: barber.id, serviceId: service.id },
      });
    }
  }

  for (const service of services2) {
    await prisma.barberService.upsert({
      where: { barberId_serviceId: { barberId: barber3.id, serviceId: service.id } },
      update: {},
      create: { barberId: barber3.id, serviceId: service.id },
    });
  }

  console.log(
    `   ✓  ${services1.length * 2} links (shop1) · ${services2.length} links (shop2)`
  );

  // ─────────────────────────────────────────────────────────
  // 9. TRANSACTIONAL DATA — cleanup first (idempotency)
  // ─────────────────────────────────────────────────────────

  console.log("\n🧹  Clearing transactional seed data for idempotency …");

  const seedShopIds = [shop1.id, shop2.id];

  // QueueEvent.bookingId is nullable with no cascade — delete first to avoid FK issues
  await prisma.queueEvent.deleteMany({ where: { shopId: { in: seedShopIds } } });
  // Booking cascade-deletes: QueueEntry, ChairAllocation, Payment, PaymentTransactionLog, WebhookEvent
  await prisma.booking.deleteMany({ where: { shopId: { in: seedShopIds } } });
  await prisma.review.deleteMany({ where: { shopId: { in: seedShopIds } } });
  await prisma.waitTimeMetric.deleteMany({ where: { shopId: { in: seedShopIds } } });
  await prisma.shopAnalyticDaily.deleteMany({ where: { shopId: { in: seedShopIds } } });

  // Reset chairs that may have been set OCCUPIED by a prior seed run
  await prisma.chair.updateMany({
    where: { shopId: { in: seedShopIds } },
    data: { status: ChairStatus.AVAILABLE, activeServiceStart: null, activeServiceEnd: null },
  });

  // Clear new transactional seed data for idempotency
  const seedCustomerIds = customers.map((c) => c.id);

  // Wallet transactions (need wallet IDs first — relation filter not supported in deleteMany)
  const seedWallets = await prisma.wallet.findMany({
    where: { userId: { in: seedCustomerIds } },
    select: { id: true },
  });
  await prisma.walletTransaction.deleteMany({
    where: { walletId: { in: seedWallets.map((w) => w.id) } },
  });

  // Loyalty transactions
  const seedLoyaltyAccs = await prisma.loyaltyAccount.findMany({
    where: { userId: { in: seedCustomerIds } },
    select: { id: true },
  });
  await prisma.loyaltyTransaction.deleteMany({
    where: { loyaltyAccountId: { in: seedLoyaltyAccs.map((a) => a.id) } },
  });

  // Coupon redemptions
  await prisma.couponRedemption.deleteMany({
    where: { userId: { in: seedCustomerIds } },
  });

  // Rebooking reminders
  await prisma.rebookingReminder.deleteMany({
    where: { userId: { in: seedCustomerIds } },
  });

  // Event log entries for seed users / shops
  await prisma.eventLog.deleteMany({
    where: { OR: [{ userId: { in: seedCustomerIds } }, { shopId: { in: seedShopIds } }] },
  });

  console.log("   ✓  Done");

  // ─────────────────────────────────────────────────────────
  // 10. BOOKINGS (+ nested QueueEntry, ChairAllocation, Payment)
  // ─────────────────────────────────────────────────────────

  console.log("\n📅  Creating bookings …");

  // ── SHOP 1 ───────────────────────────────────────────────

  // [1] COMPLETED — 3 days ago — Ravi — Classic Haircut — Barber1 — Chair1 (BookBer)
  const s1b1Start = daysAgo(3);
  const b_s1_1 = await prisma.booking.create({
    data: {
      userId: customers[0].id,  // Ravi
      shopId: shop1.id,
      barberId: barber1.id,
      serviceId: services1[0].id,
      chairId: chairs1[0].id,
      status: BookingStatus.COMPLETED,
      walkIn: false,
      arrivalWindowStart: s1b1Start,
      arrivalWindowEnd: addMinutes(s1b1Start, 30),
      queueEntry: {
        create: {
          shopId: shop1.id,
          barberId: barber1.id,
          chairId: chairs1[0].id,
          lane: QueueLane.BOOKBER,
          position: 100,
          queueStatus: QueueStatus.COMPLETED,
          estimatedWaitMinutes: 0,
          version: 3,
        },
      },
      chairAllocations: {
        create: {
          shopId: shop1.id,
          chairId: chairs1[0].id,
          allocatedAt: addMinutes(s1b1Start, 2),
          activeServiceStart: addMinutes(s1b1Start, 5),
          activeServiceEnd: addMinutes(s1b1Start, 33),
          releasedAt: addMinutes(s1b1Start, 33),
        },
      },
      payment: {
        create: {
          amount: services1[0].price,
          method: PaymentMethod.UPI,
          status: PaymentStatus.PAID,
          transactionId: "UPI-RAVI-001",
          idempotencyKey: "seed-b-s1-1",
          completedAt: addMinutes(s1b1Start, 35),
          transactionLogs: {
            create: {
              action: "CHARGE",
              status: PaymentStatus.PAID,
              gatewayResponse: { provider: "razorpay", status: "captured" },
            },
          },
        },
      },
    },
  });

  // [2] COMPLETED — 5 days ago — Priya — Beard Trim — Barber2 — Chair3 — Walk-in
  const s1b2Start = daysAgo(5);
  const b_s1_2 = await prisma.booking.create({
    data: {
      userId: customers[1].id,  // Priya
      shopId: shop1.id,
      barberId: barber2.id,
      serviceId: services1[1].id,
      chairId: chairs1[2].id,
      status: BookingStatus.COMPLETED,
      walkIn: true,
      arrivalWindowStart: s1b2Start,
      arrivalWindowEnd: addMinutes(s1b2Start, 30),
      queueEntry: {
        create: {
          shopId: shop1.id,
          barberId: barber2.id,
          chairId: chairs1[2].id,
          lane: QueueLane.WALKIN,
          position: 100,
          queueStatus: QueueStatus.COMPLETED,
          estimatedWaitMinutes: 0,
          version: 2,
        },
      },
      chairAllocations: {
        create: {
          shopId: shop1.id,
          chairId: chairs1[2].id,
          allocatedAt: addMinutes(s1b2Start, 1),
          activeServiceStart: addMinutes(s1b2Start, 3),
          activeServiceEnd: addMinutes(s1b2Start, 25),
          releasedAt: addMinutes(s1b2Start, 25),
        },
      },
      payment: {
        create: {
          amount: services1[1].price,
          method: PaymentMethod.CASH,
          status: PaymentStatus.PAID,
          idempotencyKey: "seed-b-s1-2",
          completedAt: addMinutes(s1b2Start, 26),
        },
      },
    },
  });

  // [3] COMPLETED — 2 days ago — Arjun — Combo — Barber1 — Chair2 (BookBer)
  const s1b3Start = daysAgo(2);
  const b_s1_3 = await prisma.booking.create({
    data: {
      userId: customers[2].id,  // Arjun
      shopId: shop1.id,
      barberId: barber1.id,
      serviceId: services1[2].id,
      chairId: chairs1[1].id,
      status: BookingStatus.COMPLETED,
      walkIn: false,
      arrivalWindowStart: s1b3Start,
      arrivalWindowEnd: addMinutes(s1b3Start, 30),
      queueEntry: {
        create: {
          shopId: shop1.id,
          barberId: barber1.id,
          chairId: chairs1[1].id,
          lane: QueueLane.BOOKBER,
          position: 110,
          queueStatus: QueueStatus.COMPLETED,
          estimatedWaitMinutes: 0,
          version: 4,
        },
      },
      chairAllocations: {
        create: {
          shopId: shop1.id,
          chairId: chairs1[1].id,
          allocatedAt: addMinutes(s1b3Start, 3),
          activeServiceStart: addMinutes(s1b3Start, 5),
          activeServiceEnd: addMinutes(s1b3Start, 48),
          releasedAt: addMinutes(s1b3Start, 48),
        },
      },
      payment: {
        create: {
          amount: services1[2].price,
          method: PaymentMethod.CARD,
          status: PaymentStatus.PAID,
          transactionId: "CARD-ARJUN-003",
          idempotencyKey: "seed-b-s1-3",
          completedAt: addMinutes(s1b3Start, 50),
          transactionLogs: {
            create: {
              action: "CHARGE",
              status: PaymentStatus.PAID,
              gatewayResponse: { provider: "stripe", status: "succeeded" },
            },
          },
        },
      },
    },
  });

  // [4] IN_SERVICE — right now — Kiran — Classic Haircut — Barber2 — Chair1 (BookBer)
  //      Position 120 in BOOKBER lane (distinct from 100 and 110 above)
  const inServiceStart = minutesAgo(15);
  const b_s1_4 = await prisma.booking.create({
    data: {
      userId: customers[3].id,  // Kiran
      shopId: shop1.id,
      barberId: barber2.id,
      serviceId: services1[0].id,
      chairId: chairs1[0].id,
      status: BookingStatus.IN_SERVICE,
      walkIn: false,
      arrivalWindowStart: minutesAgo(40),
      arrivalWindowEnd: minutesAgo(10),
      queueEntry: {
        create: {
          shopId: shop1.id,
          barberId: barber2.id,
          chairId: chairs1[0].id,
          lane: QueueLane.BOOKBER,
          position: 120,
          queueStatus: QueueStatus.IN_SERVICE,
          estimatedWaitMinutes: 0,
          version: 2,
        },
      },
      chairAllocations: {
        create: {
          shopId: shop1.id,
          chairId: chairs1[0].id,
          allocatedAt: minutesAgo(18),
          activeServiceStart: inServiceStart,
          // releasedAt / activeServiceEnd intentionally null — service in progress
        },
      },
    },
  });

  // Mark chair1 as OCCUPIED for the live booking
  await prisma.chair.update({
    where: { id: chairs1[0].id },
    data: {
      status: ChairStatus.OCCUPIED,
      activeServiceStart: inServiceStart,
      activeServiceEnd: addMinutes(inServiceStart, 30),
    },
  });

  // [5] QUEUED (WAITING) — Deepak — Classic Haircut — Barber1 — BookBer lane pos 10
  const b_s1_5 = await prisma.booking.create({
    data: {
      userId: customers[4].id,  // Deepak
      shopId: shop1.id,
      barberId: barber1.id,
      serviceId: services1[0].id,
      status: BookingStatus.QUEUED,
      walkIn: false,
      arrivalWindowStart: minutesAgo(5),
      arrivalWindowEnd: minutesFromNow(25),
      queueEntry: {
        create: {
          shopId: shop1.id,
          barberId: barber1.id,
          lane: QueueLane.BOOKBER,
          position: 10,
          queueStatus: QueueStatus.WAITING,
          estimatedWaitMinutes: 15,
          estimatedServiceStart: minutesFromNow(15),
          version: 0,
        },
      },
    },
  });

  // [6] QUEUED (WAITING) — Sneha — Beard Trim — Walk-in, no barber assigned yet
  const b_s1_6 = await prisma.booking.create({
    data: {
      userId: customers[5].id,  // Sneha
      shopId: shop1.id,
      serviceId: services1[1].id,
      status: BookingStatus.QUEUED,
      walkIn: true,
      arrivalWindowStart: minutesAgo(2),
      arrivalWindowEnd: minutesFromNow(28),
      queueEntry: {
        create: {
          shopId: shop1.id,
          lane: QueueLane.WALKIN,
          position: 10,
          queueStatus: QueueStatus.WAITING,
          estimatedWaitMinutes: 20,
          estimatedServiceStart: minutesFromNow(20),
          version: 0,
        },
      },
    },
  });

  // [7] CANCELLED — yesterday — Rahul — Premium Grooming
  const s1b7Start = daysAgo(1);
  await prisma.booking.create({
    data: {
      userId: customers[6].id,  // Rahul
      shopId: shop1.id,
      serviceId: services1[3].id,
      status: BookingStatus.CANCELLED,
      walkIn: false,
      arrivalWindowStart: s1b7Start,
      arrivalWindowEnd: addMinutes(s1b7Start, 30),
      cancellationReason: "Customer no longer available",
      cancelledAt: addMinutes(s1b7Start, -120), // cancelled 2h before slot
      queueEntry: {
        create: {
          shopId: shop1.id,
          lane: QueueLane.BOOKBER,
          position: 130,
          queueStatus: QueueStatus.CANCELLED,
          estimatedWaitMinutes: 0,
          version: 1,
        },
      },
    },
  });

  // ── SHOP 2 ───────────────────────────────────────────────

  // [8] COMPLETED — 4 days ago — Anita — Classic Haircut — Barber3 — Chair1 (BookBer)
  const s2b1Start = daysAgo(4);
  const b_s2_1 = await prisma.booking.create({
    data: {
      userId: customers[7].id,  // Anita
      shopId: shop2.id,
      barberId: barber3.id,
      serviceId: services2[0].id,
      chairId: chairs2[0].id,
      status: BookingStatus.COMPLETED,
      walkIn: false,
      arrivalWindowStart: s2b1Start,
      arrivalWindowEnd: addMinutes(s2b1Start, 30),
      queueEntry: {
        create: {
          shopId: shop2.id,
          barberId: barber3.id,
          chairId: chairs2[0].id,
          lane: QueueLane.BOOKBER,
          position: 100,
          queueStatus: QueueStatus.COMPLETED,
          estimatedWaitMinutes: 0,
          version: 3,
        },
      },
      chairAllocations: {
        create: {
          shopId: shop2.id,
          chairId: chairs2[0].id,
          allocatedAt: addMinutes(s2b1Start, 2),
          activeServiceStart: addMinutes(s2b1Start, 4),
          activeServiceEnd: addMinutes(s2b1Start, 37),
          releasedAt: addMinutes(s2b1Start, 37),
        },
      },
      payment: {
        create: {
          amount: services2[0].price,
          method: PaymentMethod.UPI,
          status: PaymentStatus.PAID,
          transactionId: "UPI-ANITA-001",
          idempotencyKey: "seed-b-s2-1",
          completedAt: addMinutes(s2b1Start, 38),
          transactionLogs: {
            create: {
              action: "CHARGE",
              status: PaymentStatus.PAID,
              gatewayResponse: { provider: "razorpay", status: "captured" },
            },
          },
        },
      },
    },
  });

  // [9] COMPLETED — 6 days ago — Vijay — Combo — Barber3 — Chair2 — Walk-in
  const s2b2Start = daysAgo(6);
  const b_s2_2 = await prisma.booking.create({
    data: {
      userId: customers[8].id,  // Vijay
      shopId: shop2.id,
      barberId: barber3.id,
      serviceId: services2[2].id,
      chairId: chairs2[1].id,
      status: BookingStatus.COMPLETED,
      walkIn: true,
      arrivalWindowStart: s2b2Start,
      arrivalWindowEnd: addMinutes(s2b2Start, 30),
      queueEntry: {
        create: {
          shopId: shop2.id,
          barberId: barber3.id,
          chairId: chairs2[1].id,
          lane: QueueLane.WALKIN,
          position: 100,
          queueStatus: QueueStatus.COMPLETED,
          estimatedWaitMinutes: 0,
          version: 4,
        },
      },
      chairAllocations: {
        create: {
          shopId: shop2.id,
          chairId: chairs2[1].id,
          allocatedAt: addMinutes(s2b2Start, 5),
          activeServiceStart: addMinutes(s2b2Start, 8),
          activeServiceEnd: addMinutes(s2b2Start, 54),
          releasedAt: addMinutes(s2b2Start, 54),
        },
      },
      payment: {
        create: {
          amount: services2[2].price,
          method: PaymentMethod.CARD,
          status: PaymentStatus.PAID,
          transactionId: "CARD-VIJAY-001",
          idempotencyKey: "seed-b-s2-2",
          completedAt: addMinutes(s2b2Start, 56),
        },
      },
    },
  });

  // [10] QUEUED — Neha — Beard Trim — Barber3 — BookBer pos 10
  await prisma.booking.create({
    data: {
      userId: customers[9].id,  // Neha
      shopId: shop2.id,
      barberId: barber3.id,
      serviceId: services2[1].id,
      status: BookingStatus.QUEUED,
      walkIn: false,
      arrivalWindowStart: minutesAgo(10),
      arrivalWindowEnd: minutesFromNow(20),
      queueEntry: {
        create: {
          shopId: shop2.id,
          barberId: barber3.id,
          lane: QueueLane.BOOKBER,
          position: 10,
          queueStatus: QueueStatus.WAITING,
          estimatedWaitMinutes: 10,
          estimatedServiceStart: minutesFromNow(10),
          version: 0,
        },
      },
    },
  });

  // [11] NO_SHOW — yesterday — Ravi (returned at shop2) — Classic Haircut
  const s2b4Start = new Date(daysAgo(1).setHours(11, 0, 0, 0));
  await prisma.booking.create({
    data: {
      userId: customers[0].id,  // Ravi — same customer, different shop
      shopId: shop2.id,
      barberId: barber3.id,
      serviceId: services2[0].id,
      status: BookingStatus.NO_SHOW,
      walkIn: false,
      arrivalWindowStart: s2b4Start,
      arrivalWindowEnd: addMinutes(s2b4Start, 30),
      noShowAt: addMinutes(s2b4Start, 15),
      queueEntry: {
        create: {
          shopId: shop2.id,
          barberId: barber3.id,
          lane: QueueLane.BOOKBER,
          position: 110,
          queueStatus: QueueStatus.NO_SHOW,
          estimatedWaitMinutes: 0,
          version: 2,
        },
      },
    },
  });

  // [12] SCHEDULED — tomorrow morning — Deepak — Premium Grooming — shop1, Barber1
  const scheduledTime = new Date();
  scheduledTime.setDate(scheduledTime.getDate() + 1);
  scheduledTime.setHours(10, 30, 0, 0);
  const b_s1_scheduled = await prisma.booking.create({
    data: {
      userId: customers[4].id, // Deepak
      shopId: shop1.id,
      barberId: barber1.id,
      serviceId: services1[3].id, // Premium Grooming Package
      status: BookingStatus.SCHEDULED,
      walkIn: false,
      scheduledStart: scheduledTime,
      notes: "Please use the lavender conditioning treatment",
      arrivalWindowStart: scheduledTime,
      arrivalWindowEnd: addMinutes(scheduledTime, 30),
    },
  });

  console.log("   ✓  7 bookings (shop1): 3 completed · 1 in-service · 2 queued · 1 cancelled");
  console.log("   ✓  4 bookings (shop2): 2 completed · 1 queued · 1 no-show");
  console.log("   ✓  1 SCHEDULED booking (shop1, tomorrow 10:30)");

  // ─────────────────────────────────────────────────────────
  // 11. QUEUE EVENTS
  // ─────────────────────────────────────────────────────────

  console.log("\n📋  Logging queue events …");

  type QueueEventSeed = {
    shopId: string;
    bookingId: string;
    type: QueueEventType;
    payload: Record<string, unknown>;
  };

  const queueEvents: QueueEventSeed[] = [
    // ENQUEUED for every booking (SCHEDULED bookings use PROMOTED when they become QUEUED)
    { shopId: shop1.id, bookingId: b_s1_1.id, type: QueueEventType.ENQUEUED, payload: { lane: "BOOKBER", position: 100 } },
    { shopId: shop1.id, bookingId: b_s1_2.id, type: QueueEventType.ENQUEUED, payload: { lane: "WALKIN", position: 100 } },
    { shopId: shop1.id, bookingId: b_s1_3.id, type: QueueEventType.ENQUEUED, payload: { lane: "BOOKBER", position: 110 } },
    { shopId: shop1.id, bookingId: b_s1_4.id, type: QueueEventType.ENQUEUED, payload: { lane: "BOOKBER", position: 120 } },
    { shopId: shop1.id, bookingId: b_s1_5.id, type: QueueEventType.ENQUEUED, payload: { lane: "BOOKBER", position: 10 } },
    { shopId: shop1.id, bookingId: b_s1_6.id, type: QueueEventType.ENQUEUED, payload: { lane: "WALKIN", position: 10 } },
    { shopId: shop2.id, bookingId: b_s2_1.id, type: QueueEventType.ENQUEUED, payload: { lane: "BOOKBER", position: 100 } },
    { shopId: shop2.id, bookingId: b_s2_2.id, type: QueueEventType.ENQUEUED, payload: { lane: "WALKIN", position: 100 } },
    // State transitions for completed bookings
    { shopId: shop1.id, bookingId: b_s1_1.id, type: QueueEventType.CHAIR_ASSIGNED, payload: { chairNumber: 1 } },
    { shopId: shop1.id, bookingId: b_s1_1.id, type: QueueEventType.IN_SERVICE, payload: {} },
    { shopId: shop1.id, bookingId: b_s1_1.id, type: QueueEventType.COMPLETED, payload: {} },
    { shopId: shop1.id, bookingId: b_s1_4.id, type: QueueEventType.CHAIR_ASSIGNED, payload: { chairNumber: 1 } },
    { shopId: shop1.id, bookingId: b_s1_4.id, type: QueueEventType.IN_SERVICE, payload: {} },
    { shopId: shop2.id, bookingId: b_s2_1.id, type: QueueEventType.CHAIR_ASSIGNED, payload: { chairNumber: 1 } },
    { shopId: shop2.id, bookingId: b_s2_1.id, type: QueueEventType.IN_SERVICE, payload: {} },
    { shopId: shop2.id, bookingId: b_s2_1.id, type: QueueEventType.COMPLETED, payload: {} },
  ];

  await prisma.queueEvent.createMany({ data: queueEvents });

  console.log(`   ✓  ${queueEvents.length} queue events`);

  // ─────────────────────────────────────────────────────────
  // 12. REVIEWS
  // ─────────────────────────────────────────────────────────

  console.log("\n⭐  Creating reviews …");

  await prisma.review.createMany({
    data: [
      {
        userId: customers[0].id, // Ravi → shop1
        shopId: shop1.id,
        rating: 5,
        comment: "Alex is an absolute legend. Best fade I've ever had in Mumbai!",
      },
      {
        userId: customers[1].id, // Priya → shop1
        shopId: shop1.id,
        rating: 4,
        comment: "Sam did a great beard trim. Took a bit longer but totally worth it.",
      },
      {
        userId: customers[2].id, // Arjun → shop1
        shopId: shop1.id,
        rating: 5,
        comment: "The combo deal is unbeatable. Perfect cut and beard shape — will be back!",
      },
      {
        userId: customers[7].id, // Anita → shop2
        shopId: shop2.id,
        rating: 5,
        comment: "Mike is phenomenal. French technique, flawless execution. 10/10.",
      },
      {
        userId: customers[8].id, // Vijay → shop2
        shopId: shop2.id,
        rating: 5,
        comment: "Best combo cut I've had. The hot towel treatment was an unexpected bonus.",
      },
    ],
  });

  console.log("   ✓  5 reviews");

  // ─────────────────────────────────────────────────────────
  // 13. WAIT TIME METRICS
  // ─────────────────────────────────────────────────────────

  console.log("\n⏱️   Seeding wait time metrics …");

  await prisma.waitTimeMetric.createMany({
    data: [
      { shopId: shop1.id, barberId: barber1.id, category: ServiceCategory.HAIRCUT, actualMinutes: 28, expectedMinutes: 30, recordedAt: daysAgo(3) },
      { shopId: shop1.id, barberId: barber1.id, category: ServiceCategory.COMBO, actualMinutes: 44, expectedMinutes: 45, recordedAt: daysAgo(2) },
      { shopId: shop1.id, barberId: barber2.id, category: ServiceCategory.BEARD, actualMinutes: 22, expectedMinutes: 20, recordedAt: daysAgo(5) },
      { shopId: shop1.id, barberId: barber2.id, category: ServiceCategory.HAIRCUT, actualMinutes: 31, expectedMinutes: 30, recordedAt: daysAgo(1) },
      { shopId: shop2.id, barberId: barber3.id, category: ServiceCategory.HAIRCUT, actualMinutes: 35, expectedMinutes: 30, recordedAt: daysAgo(4) },
      { shopId: shop2.id, barberId: barber3.id, category: ServiceCategory.COMBO, actualMinutes: 47, expectedMinutes: 45, recordedAt: daysAgo(6) },
      { shopId: shop2.id, barberId: barber3.id, category: ServiceCategory.BEARD, actualMinutes: 18, expectedMinutes: 20, recordedAt: daysAgo(2) },
    ],
  });

  console.log("   ✓  7 metrics (shop1: 4 · shop2: 3)");

  // ─────────────────────────────────────────────────────────
  // 14. SHOP ANALYTICS (last 7 days)
  // ─────────────────────────────────────────────────────────

  console.log("\n📊  Generating 7-day analytics …");

  // Deterministic analytics so repeated runs produce stable data
  type DayStats = {
    totalBookings: number;
    totalWalkIns: number;
    completedBookings: number;
    cancelledBookings: number;
    noShows: number;
    avgWaitMinutes: number;
    avgServiceMinutes: number;
    totalRevenue: number;
    peakHour: number;
    chairUtilizationPct: number;
    queueAbandonments: number;
  };

  const dailyStats: DayStats[] = [
    { totalBookings: 22, totalWalkIns: 6, completedBookings: 18, cancelledBookings: 2, noShows: 2, avgWaitMinutes: 12.5, avgServiceMinutes: 32.0, totalRevenue: 4200, peakHour: 11, chairUtilizationPct: 0.72, queueAbandonments: 1 },
    { totalBookings: 18, totalWalkIns: 4, completedBookings: 15, cancelledBookings: 2, noShows: 1, avgWaitMinutes: 14.0, avgServiceMinutes: 29.5, totalRevenue: 3500, peakHour: 12, chairUtilizationPct: 0.65, queueAbandonments: 2 },
    { totalBookings: 25, totalWalkIns: 8, completedBookings: 21, cancelledBookings: 3, noShows: 1, avgWaitMinutes: 10.2, avgServiceMinutes: 31.0, totalRevenue: 5100, peakHour: 10, chairUtilizationPct: 0.80, queueAbandonments: 0 },
    { totalBookings: 20, totalWalkIns: 5, completedBookings: 17, cancelledBookings: 2, noShows: 1, avgWaitMinutes: 11.8, avgServiceMinutes: 30.0, totalRevenue: 3900, peakHour: 13, chairUtilizationPct: 0.70, queueAbandonments: 1 },
    { totalBookings: 28, totalWalkIns: 9, completedBookings: 24, cancelledBookings: 3, noShows: 1, avgWaitMinutes: 9.5, avgServiceMinutes: 33.0, totalRevenue: 5800, peakHour: 11, chairUtilizationPct: 0.85, queueAbandonments: 0 },
    { totalBookings: 30, totalWalkIns: 10, completedBookings: 26, cancelledBookings: 3, noShows: 1, avgWaitMinutes: 8.0, avgServiceMinutes: 34.0, totalRevenue: 6300, peakHour: 12, chairUtilizationPct: 0.90, queueAbandonments: 1 },
    { totalBookings: 15, totalWalkIns: 3, completedBookings: 12, cancelledBookings: 2, noShows: 1, avgWaitMinutes: 16.0, avgServiceMinutes: 28.0, totalRevenue: 2900, peakHour: 14, chairUtilizationPct: 0.55, queueAbandonments: 2 },
  ];

  for (const shop of [shop1, shop2]) {
    for (let d = 6; d >= 0; d--) {
      const date = new Date(daysAgo(d));
      date.setHours(0, 0, 0, 0);
      const stats = dailyStats[6 - d];

      // Shop2 has slightly lower throughput (1 barber vs 2)
      const scale = shop.id === shop2.id ? 0.55 : 1.0;

      await prisma.shopAnalyticDaily.upsert({
        where: { shopId_date: { shopId: shop.id, date } },
        update: {},
        create: {
          shopId: shop.id,
          date,
          totalBookings: Math.round(stats.totalBookings * scale),
          totalWalkIns: Math.round(stats.totalWalkIns * scale),
          completedBookings: Math.round(stats.completedBookings * scale),
          cancelledBookings: Math.round(stats.cancelledBookings * scale),
          noShows: stats.noShows,
          avgWaitMinutes: stats.avgWaitMinutes + (shop.id === shop2.id ? 3 : 0),
          avgServiceMinutes: stats.avgServiceMinutes + (shop.id === shop2.id ? 5 : 0),
          totalRevenue: stats.totalRevenue * scale,
          peakHour: stats.peakHour,
          chairUtilizationPct: stats.chairUtilizationPct * (shop.id === shop2.id ? 0.85 : 1),
          queueAbandonments: stats.queueAbandonments,
        },
      });
    }
  }

  console.log("   ✓  7 days × 2 shops = 14 daily analytic rows");

  // ─────────────────────────────────────────────────────────
  // SUMMARY
  // ─────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────
  // 15. WALLETS
  // ─────────────────────────────────────────────────────────

  console.log("\n💰  Creating customer wallets …");

  // [index] = customer balance in ₹
  const walletBalances = [500, 0, 1200, 250, 750, 0, 100, 900, 350, 600];

  const wallets = await Promise.all(
    customers.map((c, i) =>
      prisma.wallet.upsert({
        where: { userId: c.id },
        update: { balance: walletBalances[i] },
        create: { userId: c.id, balance: walletBalances[i] },
      })
    )
  );

  type WTx = { walletId: string; amount: number; type: string; reason: string; refId?: string };
  const walletTxns: WTx[] = [
    // Ravi — topped up ₹1000, paid ₹250 for booking, paid ₹250 for combo
    { walletId: wallets[0].id, amount: 1000, type: "CREDIT", reason: "Wallet top-up" },
    { walletId: wallets[0].id, amount: 250, type: "DEBIT", reason: "Payment: Classic Haircut", refId: b_s1_1.id },
    { walletId: wallets[0].id, amount: 250, type: "DEBIT", reason: "Payment: Haircut + Beard Combo", refId: b_s1_3.id },
    // Arjun — topped up
    { walletId: wallets[2].id, amount: 1200, type: "CREDIT", reason: "Wallet top-up" },
    // Kiran — referral reward
    { walletId: wallets[3].id, amount: 250, type: "CREDIT", reason: "Referral reward — friend joined" },
    // Deepak — top-up then one purchase
    { walletId: wallets[4].id, amount: 1000, type: "CREDIT", reason: "Wallet top-up" },
    { walletId: wallets[4].id, amount: 250, type: "DEBIT", reason: "Payment: Classic Haircut" },
    // Rahul — small top-up
    { walletId: wallets[6].id, amount: 100, type: "CREDIT", reason: "Wallet top-up" },
    // Anita — top-up
    { walletId: wallets[7].id, amount: 900, type: "CREDIT", reason: "Wallet top-up" },
    // Vijay — two top-ups, one spend
    { walletId: wallets[8].id, amount: 500, type: "CREDIT", reason: "Wallet top-up" },
    { walletId: wallets[8].id, amount: 350, type: "DEBIT", reason: "Payment: Haircut + Beard Combo", refId: b_s2_2.id },
    { walletId: wallets[8].id, amount: 200, type: "CREDIT", reason: "Wallet top-up" },
    // Neha — top-up
    { walletId: wallets[9].id, amount: 600, type: "CREDIT", reason: "Wallet top-up" },
  ];

  for (const tx of walletTxns) {
    await prisma.walletTransaction.create({ data: tx });
  }

  console.log(`   ✓  ${wallets.length} wallets · ${walletTxns.length} transactions`);

  // ─────────────────────────────────────────────────────────
  // 16. LOYALTY ACCOUNTS
  // ─────────────────────────────────────────────────────────

  console.log("\n🏆  Creating loyalty accounts …");

  const loyaltyDefs = [
    { points: 1250, tier: "SILVER" }, // Ravi
    { points: 150, tier: "BRONZE" }, // Priya
    { points: 3200, tier: "GOLD" }, // Arjun
    { points: 80, tier: "BRONZE" }, // Kiran
    { points: 720, tier: "BRONZE" }, // Deepak
    { points: 50, tier: "BRONZE" }, // Sneha
    { points: 0, tier: "BRONZE" }, // Rahul (cancelled booking)
    { points: 2100, tier: "SILVER" }, // Anita
    { points: 3500, tier: "GOLD" }, // Vijay
    { points: 4800, tier: "PLATINUM" }, // Neha
  ];

  const loyaltyAccounts = await Promise.all(
    customers.map((c, i) =>
      prisma.loyaltyAccount.upsert({
        where: { userId: c.id },
        update: { points: loyaltyDefs[i].points, tier: loyaltyDefs[i].tier },
        create: { userId: c.id, points: loyaltyDefs[i].points, tier: loyaltyDefs[i].tier },
      })
    )
  );

  type LTx = { loyaltyAccountId: string; points: number; type: string; reason: string; refId?: string };
  const loyaltyTxns: LTx[] = [
    // Ravi — earned from bookings + legacy migration
    { loyaltyAccountId: loyaltyAccounts[0].id, points: 25, type: "EARN", reason: "Classic Haircut — ₹250 spend", refId: b_s1_1.id },
    { loyaltyAccountId: loyaltyAccounts[0].id, points: 35, type: "EARN", reason: "Haircut + Beard Combo — ₹350 spend", refId: b_s1_3.id },
    { loyaltyAccountId: loyaltyAccounts[0].id, points: 1190, type: "ADJUSTMENT", reason: "Migration from legacy system" },
    // Priya
    { loyaltyAccountId: loyaltyAccounts[1].id, points: 150, type: "EARN", reason: "Beard Trim — ₹150 spend", refId: b_s1_2.id },
    // Arjun — large accumulated balance
    { loyaltyAccountId: loyaltyAccounts[2].id, points: 3200, type: "ADJUSTMENT", reason: "Migration from legacy system" },
    // Kiran — small earn from queued booking
    { loyaltyAccountId: loyaltyAccounts[3].id, points: 80, type: "EARN", reason: "Classic Haircut — queued spend" },
    // Deepak — earn from queued booking
    { loyaltyAccountId: loyaltyAccounts[4].id, points: 720, type: "EARN", reason: "Loyalty bonus from membership" },
    // Sneha
    { loyaltyAccountId: loyaltyAccounts[5].id, points: 50, type: "EARN", reason: "Beard Trim — ₹150 spend" },
    // Anita — earned + legacy
    { loyaltyAccountId: loyaltyAccounts[7].id, points: 25, type: "EARN", reason: "Classic Haircut — ₹250 spend", refId: b_s2_1.id },
    { loyaltyAccountId: loyaltyAccounts[7].id, points: 2075, type: "ADJUSTMENT", reason: "Migration from legacy system" },
    // Vijay — earned + legacy
    { loyaltyAccountId: loyaltyAccounts[8].id, points: 35, type: "EARN", reason: "Haircut + Beard Combo — ₹350 spend", refId: b_s2_2.id },
    { loyaltyAccountId: loyaltyAccounts[8].id, points: 3465, type: "ADJUSTMENT", reason: "Migration from legacy system" },
    // Neha — big earn, then a redemption
    { loyaltyAccountId: loyaltyAccounts[9].id, points: 5000, type: "EARN", reason: "Lifetime bookings accumulation" },
    { loyaltyAccountId: loyaltyAccounts[9].id, points: -200, type: "REDEEM", reason: "Redeemed 200 pts → ₹20 wallet credit" },
  ];

  for (const tx of loyaltyTxns) {
    await prisma.loyaltyTransaction.create({ data: tx });
  }

  console.log(`   ✓  ${loyaltyAccounts.length} accounts · ${loyaltyTxns.length} transactions`);

  // ─────────────────────────────────────────────────────────
  // 17. REFERRALS
  // ─────────────────────────────────────────────────────────

  console.log("\n🎁  Creating referral codes …");

  const referralDefs = customers.map((c, i) => ({
    referrerId: c.id,
    code: `BB-${c.fullName.split(" ")[0].toUpperCase()}-${1001 + i}`,
    status: i < 3 ? "COMPLETED" : "PENDING",
    rewardGranted: i < 3,
    // First 3 customers referred someone; use offset to avoid self-referral
    refereeId: i < 3 ? customers[(i + 5) % 10].id : null,
  }));

  let referralCount = 0;
  for (const def of referralDefs) {
    const exists = await prisma.referral.findUnique({ where: { code: def.code } });
    if (!exists) {
      await prisma.referral.create({ data: def });
      referralCount++;
    }
  }

  console.log(`   ✓  ${referralCount} referral codes (3 completed · ${referralCount - 3} pending)`);

  // ─────────────────────────────────────────────────────────
  // 18. COUPONS
  // ─────────────────────────────────────────────────────────

  console.log("\n🎟️   Creating coupons …");

  const couponDefs = [
    {
      code: "WELCOME20",
      type: "PERCENT",
      value: 20,
      maxRedemptions: 100,
      usedCount: 1,
      minAmount: 200,
      expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
      isActive: true,
    },
    {
      code: "FLAT50",
      type: "FLAT",
      value: 50,
      maxRedemptions: 50,
      usedCount: 1,
      minAmount: 300,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      isActive: true,
    },
    {
      code: "SUMMER15",
      type: "PERCENT",
      value: 15,
      maxRedemptions: 200,
      usedCount: 0,
      minAmount: 150,
      expiresAt: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
      isActive: true,
    },
    {
      code: "NEWUSER10",
      type: "FLAT",
      value: 10,
      maxRedemptions: 500,
      usedCount: 0,
      minAmount: 0,
      expiresAt: null,
      isActive: true,
    },
    {
      code: "EXPIRED10",
      type: "PERCENT",
      value: 10,
      maxRedemptions: 10,
      usedCount: 10,
      minAmount: 0,
      expiresAt: daysAgo(30),
      isActive: false,
    },
  ];

  const coupons: any[] = [];
  for (const def of couponDefs) {
    const existing = await prisma.coupon.findUnique({ where: { code: def.code } });
    coupons.push(
      existing ??
      (await prisma.coupon.create({ data: def }))
    );
  }

  // Redemptions tied to completed bookings
  const redemptions = [
    { couponId: coupons[0].id, userId: customers[0].id, bookingId: b_s1_1.id, discount: 50 },
    { couponId: coupons[1].id, userId: customers[2].id, bookingId: b_s1_3.id, discount: 50 },
  ];

  for (const r of redemptions) {
    const exists = await prisma.couponRedemption.findFirst({
      where: { couponId: r.couponId, userId: r.userId },
    });
    if (!exists) {
      await prisma.couponRedemption.create({ data: r });
    }
  }

  console.log(`   ✓  ${coupons.length} coupons · ${redemptions.length} redemptions`);

  // ─────────────────────────────────────────────────────────
  // 19. REBOOKING REMINDERS
  // ─────────────────────────────────────────────────────────

  console.log("\n🔔  Creating rebooking reminders …");

  const reminderDefs = [
    {
      // Ravi — Classic Haircut 3 days ago, 30-day rebook interval → remind in 27 days
      userId: customers[0].id, shopId: shop1.id, serviceId: services1[0].id,
      lastVisitAt: daysAgo(3),
      reminderAt: new Date(Date.now() + 27 * 24 * 60 * 60 * 1000),
    },
    {
      // Priya — Beard Trim 5 days ago, 14-day interval → remind in 9 days
      userId: customers[1].id, shopId: shop1.id, serviceId: services1[1].id,
      lastVisitAt: daysAgo(5),
      reminderAt: new Date(Date.now() + 9 * 24 * 60 * 60 * 1000),
    },
    {
      // Arjun — Combo 2 days ago, 21-day interval → remind in 19 days
      userId: customers[2].id, shopId: shop1.id, serviceId: services1[2].id,
      lastVisitAt: daysAgo(2),
      reminderAt: new Date(Date.now() + 19 * 24 * 60 * 60 * 1000),
    },
    {
      // Anita — Classic Haircut 4 days ago → remind in 26 days
      userId: customers[7].id, shopId: shop2.id, serviceId: services2[0].id,
      lastVisitAt: daysAgo(4),
      reminderAt: new Date(Date.now() + 26 * 24 * 60 * 60 * 1000),
    },
    {
      // Vijay — Combo 6 days ago, 21-day interval → remind in 15 days
      userId: customers[8].id, shopId: shop2.id, serviceId: services2[2].id,
      lastVisitAt: daysAgo(6),
      reminderAt: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
    },
  ];

  await prisma.rebookingReminder.createMany({ data: reminderDefs });

  console.log(`   ✓  ${reminderDefs.length} reminders`);

  // ─────────────────────────────────────────────────────────
  // 20. EVENT LOG (audit trail)
  // ─────────────────────────────────────────────────────────

  console.log("\n📝  Writing audit event log …");

  const eventLogEntries = [
    // Bookings created
    { type: "BOOKING_CREATED", shopId: shop1.id, bookingId: b_s1_1.id, userId: customers[0].id, payload: { service: "Classic Haircut", walkIn: false } },
    { type: "BOOKING_CREATED", shopId: shop1.id, bookingId: b_s1_2.id, userId: customers[1].id, payload: { service: "Beard Trim", walkIn: true } },
    { type: "BOOKING_CREATED", shopId: shop1.id, bookingId: b_s1_3.id, userId: customers[2].id, payload: { service: "Haircut + Beard Combo", walkIn: false } },
    { type: "BOOKING_CREATED", shopId: shop1.id, bookingId: b_s1_4.id, userId: customers[3].id, payload: { service: "Classic Haircut", walkIn: false } },
    { type: "BOOKING_CREATED", shopId: shop1.id, bookingId: b_s1_5.id, userId: customers[4].id, payload: { service: "Classic Haircut", walkIn: false } },
    { type: "BOOKING_CREATED", shopId: shop2.id, bookingId: b_s2_1.id, userId: customers[7].id, payload: { service: "Classic Haircut", walkIn: false } },
    { type: "BOOKING_CREATED", shopId: shop2.id, bookingId: b_s2_2.id, userId: customers[8].id, payload: { service: "Haircut + Beard Combo", walkIn: true } },
    // Queue joins
    { type: "QUEUE_JOINED", shopId: shop1.id, bookingId: b_s1_5.id, userId: customers[4].id, payload: { lane: "BOOKBER", position: 10 } },
    { type: "QUEUE_JOINED", shopId: shop1.id, bookingId: b_s1_6.id, userId: customers[5].id, payload: { lane: "WALKIN", position: 10 } },
    { type: "QUEUE_JOINED", shopId: shop2.id, userId: customers[9].id, payload: { lane: "BOOKBER", position: 10 } },
    // Chair assignments
    { type: "CHAIR_ASSIGNED", shopId: shop1.id, bookingId: b_s1_1.id, chairId: chairs1[0].id, userId: customers[0].id, payload: { chairNumber: 1 } },
    { type: "CHAIR_ASSIGNED", shopId: shop1.id, bookingId: b_s1_3.id, chairId: chairs1[1].id, userId: customers[2].id, payload: { chairNumber: 2 } },
    { type: "CHAIR_ASSIGNED", shopId: shop1.id, bookingId: b_s1_4.id, chairId: chairs1[0].id, userId: customers[3].id, payload: { chairNumber: 1 } },
    { type: "CHAIR_ASSIGNED", shopId: shop2.id, bookingId: b_s2_1.id, chairId: chairs2[0].id, userId: customers[7].id, payload: { chairNumber: 1 } },
    { type: "CHAIR_ASSIGNED", shopId: shop2.id, bookingId: b_s2_2.id, chairId: chairs2[1].id, userId: customers[8].id, payload: { chairNumber: 2 } },
    // Chair releases
    { type: "CHAIR_RELEASED", shopId: shop1.id, chairId: chairs1[0].id, payload: { chairNumber: 1, durationMinutes: 28 } },
    { type: "CHAIR_RELEASED", shopId: shop1.id, chairId: chairs1[1].id, payload: { chairNumber: 2, durationMinutes: 48 } },
    { type: "CHAIR_RELEASED", shopId: shop2.id, chairId: chairs2[0].id, payload: { chairNumber: 1, durationMinutes: 33 } },
    { type: "CHAIR_RELEASED", shopId: shop2.id, chairId: chairs2[1].id, payload: { chairNumber: 2, durationMinutes: 46 } },
    // Payments
    { type: "PAYMENT_COMPLETED", shopId: shop1.id, bookingId: b_s1_1.id, userId: customers[0].id, payload: { amount: 250, method: "UPI" } },
    { type: "PAYMENT_COMPLETED", shopId: shop1.id, bookingId: b_s1_2.id, userId: customers[1].id, payload: { amount: 150, method: "CASH" } },
    { type: "PAYMENT_COMPLETED", shopId: shop1.id, bookingId: b_s1_3.id, userId: customers[2].id, payload: { amount: 350, method: "CARD" } },
    { type: "PAYMENT_COMPLETED", shopId: shop2.id, bookingId: b_s2_1.id, userId: customers[7].id, payload: { amount: 250, method: "UPI" } },
    { type: "PAYMENT_COMPLETED", shopId: shop2.id, bookingId: b_s2_2.id, userId: customers[8].id, payload: { amount: 350, method: "CARD" } },
    // Cancellation & no-show
    { type: "BOOKING_CANCELLED", shopId: shop1.id, userId: customers[6].id, payload: { reason: "Customer no longer available" } },
    { type: "BOOKING_NO_SHOW", shopId: shop2.id, userId: customers[0].id, payload: { service: "Classic Haircut" } },
    // Reviews
    { type: "REVIEW_CREATED", shopId: shop1.id, userId: customers[0].id, payload: { rating: 5 } },
    { type: "REVIEW_CREATED", shopId: shop1.id, userId: customers[1].id, payload: { rating: 4 } },
    { type: "REVIEW_CREATED", shopId: shop1.id, userId: customers[2].id, payload: { rating: 5 } },
    { type: "REVIEW_CREATED", shopId: shop2.id, userId: customers[7].id, payload: { rating: 5 } },
    { type: "REVIEW_CREATED", shopId: shop2.id, userId: customers[8].id, payload: { rating: 5 } },
    // Rebooking reminders sent (simulated past ones)
    { type: "REBOOKING_REMINDER_SENT", shopId: shop1.id, userId: customers[0].id, payload: { serviceId: services1[0].id, daysUntilDue: 27 } },
    { type: "REBOOKING_REMINDER_SENT", shopId: shop2.id, userId: customers[7].id, payload: { serviceId: services2[0].id, daysUntilDue: 26 } },
    // Scheduled booking
    { type: "BOOKING_SCHEDULED", shopId: shop1.id, bookingId: b_s1_scheduled.id, userId: customers[4].id, payload: { scheduledStart: scheduledTime, service: "Premium Grooming Package" } },
  ];

  await prisma.eventLog.createMany({ data: eventLogEntries });

  console.log(`   ✓  ${eventLogEntries.length} event log entries`);

  console.log("\n" + "─".repeat(55));
  console.log("✅  BookBer seed complete!\n");

  console.log("🔑  Credentials  (all passwords: Bookber@123)\n");
  console.log("  Role        Email");
  console.log("  ──────────  ─────────────────────────────────");
  console.log(`  ADMIN       admin@bookber.dev`);
  console.log(`  OWNER       owner.marcus@bookber.dev    (The Classic Barber)`);
  console.log(`  OWNER       owner.james@bookber.dev     (Kings Cut Lounge)`);
  console.log(`  RECEPTION   reception.sara@bookber.dev  (The Classic Barber)`);
  console.log(`  BARBER      barber.alex@bookber.dev     (shop1)`);
  console.log(`  BARBER      barber.sam@bookber.dev      (shop1)`);
  console.log(`  BARBER      barber.mike@bookber.dev     (shop2)`);
  console.log(`  CLIENT      customer.ravi@bookber.dev`);
  console.log(`  CLIENT      customer.priya@bookber.dev`);
  console.log(`  CLIENT      customer.arjun@bookber.dev`);
  console.log(`  CLIENT      customer.kiran@bookber.dev`);
  console.log(`  CLIENT      customer.deepak@bookber.dev`);
  console.log(`  CLIENT      customer.sneha@bookber.dev`);
  console.log(`  CLIENT      customer.rahul@bookber.dev`);
  console.log(`  CLIENT      customer.anita@bookber.dev`);
  console.log(`  CLIENT      customer.vijay@bookber.dev`);
  console.log(`  CLIENT      customer.neha@bookber.dev`);

  console.log("\n🏪  Shops");
  console.log(`  the-classic-barber  →  Mumbai, 4 chairs (2 BookBer), 2 barbers`);
  console.log(`  kings-cut-lounge    →  Delhi,  3 chairs (1 BookBer), 1 barber`);

  console.log("\n📅  Active queue state");
  console.log(`  Shop1 IN_SERVICE: Kiran (Classic Haircut, chair #1)`);
  console.log(`  Shop1 QUEUED:     Deepak (BookBer pos 10) · Sneha walk-in (pos 10)`);
  console.log(`  Shop2 QUEUED:     Neha (BookBer pos 10)`);

  console.log("\n💰  Wallets & Loyalty");
  console.log(`  10 wallets seeded (Ravi ₹500 · Arjun ₹1200 · Deepak ₹750 · Anita ₹900 …)`);
  console.log(`  Tiers: Neha=PLATINUM · Arjun=GOLD · Vijay=GOLD · Ravi=SILVER · Anita=SILVER`);

  console.log("\n🎁  Referrals & Coupons");
  console.log(`  10 referral codes (3 completed). Codes: BB-RAVI-1001 … BB-NEHA-1010`);
  console.log(`  Coupons: WELCOME20 (20%) · FLAT50 (₹50 off) · SUMMER15 (15%) · NEWUSER10 (₹10 off)`);

  console.log("─".repeat(55) + "\n");
}

main()
  .catch((e: unknown) => {
    console.error("\n❌  Seed failed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
