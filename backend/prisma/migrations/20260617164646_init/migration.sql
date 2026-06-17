-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('CLIENT', 'BARBER', 'ADMIN');

-- CreateEnum
CREATE TYPE "BookingStatus" AS ENUM ('QUEUED', 'READY', 'CALLED', 'IN_SERVICE', 'COMPLETED', 'CANCELLED', 'NO_SHOW');

-- CreateEnum
CREATE TYPE "ChairStatus" AS ENUM ('AVAILABLE', 'OCCUPIED', 'CLEANING', 'BLOCKED');

-- CreateEnum
CREATE TYPE "QueueStatus" AS ENUM ('WAITING', 'READY', 'IN_SERVICE', 'COMPLETED', 'SKIPPED', 'CALLED', 'NO_SHOW', 'CANCELLED');

-- CreateEnum
CREATE TYPE "QueueLane" AS ENUM ('BOOKBER', 'WALKIN');

-- CreateEnum
CREATE TYPE "ServiceCategory" AS ENUM ('HAIRCUT', 'BEARD', 'COMBO');

-- CreateEnum
CREATE TYPE "QueueEventType" AS ENUM ('ENQUEUED', 'POSITION_CHANGED', 'WAIT_RECALCULATED', 'CALLED', 'IN_SERVICE', 'COMPLETED', 'NO_SHOW', 'CANCELLED', 'CHAIR_ASSIGNED', 'CHAIR_RELEASED', 'DELAYED', 'OVERRUN');

-- CreateEnum
CREATE TYPE "EventLogType" AS ENUM ('BOOKING_CREATED', 'BOOKING_CANCELLED', 'BOOKING_NO_SHOW', 'QUEUE_JOINED', 'QUEUE_LEFT', 'CHAIR_ASSIGNED', 'CHAIR_RELEASED', 'PAYMENT_COMPLETED', 'REVIEW_CREATED', 'REBOOKING_REMINDER_SENT');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('CASH', 'UPI', 'CARD');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'PAID', 'FAILED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "Platform" AS ENUM ('IOS', 'ANDROID', 'WEB');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "fullName" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "role" "UserRole" NOT NULL,
    "profileImage" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "failedLoginAttempts" INTEGER NOT NULL DEFAULT 0,
    "lockedUntil" TIMESTAMP(3),

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DeviceToken" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" "Platform" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DeviceToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "revokedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Shop" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "address" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "country" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "openingTime" TEXT,
    "closingTime" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "bookBerReservedChairCount" INTEGER NOT NULL DEFAULT 0,
    "addressLine2" TEXT,
    "email" TEXT,
    "isAcceptingBookings" BOOLEAN NOT NULL DEFAULT true,
    "isAcceptingWalkIns" BOOLEAN NOT NULL DEFAULT true,
    "ownerId" TEXT NOT NULL,
    "phone" TEXT,
    "postalCode" TEXT,
    "profileImage" TEXT,
    "slug" TEXT NOT NULL,
    "timezone" TEXT NOT NULL DEFAULT 'UTC',

    CONSTRAINT "Shop_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ShopOperatingHour" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "dayOfWeek" TEXT NOT NULL,
    "openTime" TEXT NOT NULL,
    "closeTime" TEXT NOT NULL,
    "isClosed" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "ShopOperatingHour_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ShopPhoto" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "publicId" TEXT,
    "caption" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "ShopPhoto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Barber" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "bio" TEXT,
    "experienceYears" INTEGER,
    "rating" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "isAvailable" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "serviceSpeedFactor" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "averageServiceMinutes" INTEGER,

    CONSTRAINT "Barber_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BarberService" (
    "barberId" TEXT NOT NULL,
    "serviceId" TEXT NOT NULL,

    CONSTRAINT "BarberService_pkey" PRIMARY KEY ("barberId","serviceId")
);

-- CreateTable
CREATE TABLE "Chair" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "number" INTEGER NOT NULL,
    "status" "ChairStatus" NOT NULL DEFAULT 'AVAILABLE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reservedForBookBer" BOOLEAN NOT NULL DEFAULT false,
    "activeServiceStart" TIMESTAMP(3),
    "activeServiceEnd" TIMESTAMP(3),
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Chair_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Service" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "price" DOUBLE PRECISION NOT NULL,
    "durationMinutes" INTEGER NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "category" "ServiceCategory" NOT NULL DEFAULT 'HAIRCUT',
    "rebookIntervalDays" INTEGER,

    CONSTRAINT "Service_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Booking" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "barberId" TEXT,
    "serviceId" TEXT NOT NULL,
    "chairId" TEXT,
    "status" "BookingStatus" NOT NULL DEFAULT 'QUEUED',
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "arrivalWindowStart" TIMESTAMP(3) NOT NULL,
    "arrivalWindowEnd" TIMESTAMP(3) NOT NULL,
    "walkIn" BOOLEAN NOT NULL DEFAULT false,
    "cancellationReason" TEXT,
    "cancelledAt" TIMESTAMP(3),
    "noShowAt" TIMESTAMP(3),

    CONSTRAINT "Booking_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "QueueEntry" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "barberId" TEXT,
    "chairId" TEXT,
    "lane" "QueueLane" NOT NULL,
    "position" INTEGER NOT NULL,
    "queueStatus" "QueueStatus" NOT NULL DEFAULT 'WAITING',
    "estimatedWaitMinutes" INTEGER NOT NULL DEFAULT 0,
    "estimatedServiceStart" TIMESTAMP(3),
    "version" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "QueueEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "QueueEvent" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "bookingId" TEXT,
    "type" "QueueEventType" NOT NULL,
    "payload" JSONB NOT NULL DEFAULT '{}',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "QueueEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChairAllocation" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "chairId" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "allocatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "releasedAt" TIMESTAMP(3),
    "activeServiceStart" TIMESTAMP(3),
    "activeServiceEnd" TIMESTAMP(3),

    CONSTRAINT "ChairAllocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Payment" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "method" "PaymentMethod" NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "transactionId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completedAt" TIMESTAMP(3),
    "idempotencyKey" TEXT,
    "refundReason" TEXT,
    "refundedAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentTransactionLog" (
    "id" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "status" "PaymentStatus" NOT NULL,
    "gatewayResponse" JSONB,
    "errorMessage" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PaymentTransactionLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WebhookEvent" (
    "id" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "processedAt" TIMESTAMP(3),
    "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WebhookEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Review" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Review_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WaitTimeMetric" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "barberId" TEXT NOT NULL,
    "category" "ServiceCategory" NOT NULL,
    "actualMinutes" INTEGER NOT NULL,
    "expectedMinutes" INTEGER NOT NULL,
    "recordedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WaitTimeMetric_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ShopAnalyticDaily" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "totalBookings" INTEGER NOT NULL DEFAULT 0,
    "totalWalkIns" INTEGER NOT NULL DEFAULT 0,
    "completedBookings" INTEGER NOT NULL DEFAULT 0,
    "cancelledBookings" INTEGER NOT NULL DEFAULT 0,
    "noShows" INTEGER NOT NULL DEFAULT 0,
    "avgWaitMinutes" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "avgServiceMinutes" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalRevenue" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "peakHour" INTEGER,
    "chairUtilizationPct" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "queueAbandonments" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ShopAnalyticDaily_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RebookingReminder" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "serviceId" TEXT NOT NULL,
    "lastVisitAt" TIMESTAMP(3) NOT NULL,
    "reminderAt" TIMESTAMP(3) NOT NULL,
    "sentAt" TIMESTAMP(3),
    "dismissed" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RebookingReminder_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventLog" (
    "id" TEXT NOT NULL,
    "type" "EventLogType" NOT NULL,
    "shopId" TEXT,
    "bookingId" TEXT,
    "userId" TEXT,
    "chairId" TEXT,
    "correlationId" TEXT,
    "payload" JSONB NOT NULL DEFAULT '{}',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EventLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_phoneNumber_key" ON "User"("phoneNumber");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "User"("role");

-- CreateIndex
CREATE INDEX "User_email_idx" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_phoneNumber_idx" ON "User"("phoneNumber");

-- CreateIndex
CREATE UNIQUE INDEX "DeviceToken_token_key" ON "DeviceToken"("token");

-- CreateIndex
CREATE INDEX "DeviceToken_userId_idx" ON "DeviceToken"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_token_key" ON "RefreshToken"("token");

-- CreateIndex
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");

-- CreateIndex
CREATE INDEX "RefreshToken_token_idx" ON "RefreshToken"("token");

-- CreateIndex
CREATE UNIQUE INDEX "Shop_slug_key" ON "Shop"("slug");

-- CreateIndex
CREATE INDEX "Shop_city_idx" ON "Shop"("city");

-- CreateIndex
CREATE INDEX "Shop_latitude_longitude_idx" ON "Shop"("latitude", "longitude");

-- CreateIndex
CREATE INDEX "Shop_ownerId_idx" ON "Shop"("ownerId");

-- CreateIndex
CREATE INDEX "Shop_slug_idx" ON "Shop"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "ShopOperatingHour_shopId_dayOfWeek_key" ON "ShopOperatingHour"("shopId", "dayOfWeek");

-- CreateIndex
CREATE INDEX "ShopPhoto_shopId_idx" ON "ShopPhoto"("shopId");

-- CreateIndex
CREATE UNIQUE INDEX "Barber_userId_key" ON "Barber"("userId");

-- CreateIndex
CREATE INDEX "Barber_shopId_idx" ON "Barber"("shopId");

-- CreateIndex
CREATE INDEX "BarberService_serviceId_idx" ON "BarberService"("serviceId");

-- CreateIndex
CREATE INDEX "Chair_shopId_reservedForBookBer_idx" ON "Chair"("shopId", "reservedForBookBer");

-- CreateIndex
CREATE INDEX "Chair_activeServiceStart_idx" ON "Chair"("activeServiceStart");

-- CreateIndex
CREATE INDEX "Chair_shop_available_idx" ON "Chair"("shopId", "status") WHERE (status = 'AVAILABLE'::"ChairStatus");

-- CreateIndex
CREATE UNIQUE INDEX "Chair_shopId_number_key" ON "Chair"("shopId", "number");

-- CreateIndex
CREATE INDEX "Service_shopId_idx" ON "Service"("shopId");

-- CreateIndex
CREATE INDEX "Booking_shopId_status_idx" ON "Booking"("shopId", "status");

-- CreateIndex
CREATE INDEX "Booking_barberId_status_idx" ON "Booking"("barberId", "status");

-- CreateIndex
CREATE INDEX "Booking_status_idx" ON "Booking"("status");

-- CreateIndex
CREATE UNIQUE INDEX "QueueEntry_bookingId_key" ON "QueueEntry"("bookingId");

-- CreateIndex
CREATE INDEX "QueueEntry_shopId_lane_position_idx" ON "QueueEntry"("shopId", "lane", "position");

-- CreateIndex
CREATE INDEX "QueueEntry_shopId_position_idx" ON "QueueEntry"("shopId", "position");

-- CreateIndex
CREATE INDEX "QueueEntry_barberId_queueStatus_idx" ON "QueueEntry"("barberId", "queueStatus");

-- CreateIndex
CREATE INDEX "QueueEntry_bookingId_idx" ON "QueueEntry"("bookingId");

-- CreateIndex
CREATE UNIQUE INDEX "QueueEntry_shopId_lane_position_key" ON "QueueEntry"("shopId", "lane", "position");

-- CreateIndex
CREATE INDEX "QueueEvent_shopId_createdAt_idx" ON "QueueEvent"("shopId", "createdAt");

-- CreateIndex
CREATE INDEX "QueueEvent_bookingId_idx" ON "QueueEvent"("bookingId");

-- CreateIndex
CREATE INDEX "ChairAllocation_chairId_activeServiceStart_idx" ON "ChairAllocation"("chairId", "activeServiceStart");

-- CreateIndex
CREATE INDEX "ChairAllocation_bookingId_idx" ON "ChairAllocation"("bookingId");

-- CreateIndex
CREATE INDEX "ChairAllocation_shopId_idx" ON "ChairAllocation"("shopId");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_bookingId_key" ON "Payment"("bookingId");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_idempotencyKey_key" ON "Payment"("idempotencyKey");

-- CreateIndex
CREATE INDEX "Payment_idempotencyKey_idx" ON "Payment"("idempotencyKey");

-- CreateIndex
CREATE INDEX "Payment_status_idx" ON "Payment"("status");

-- CreateIndex
CREATE INDEX "Payment_bookingId_idx" ON "Payment"("bookingId");

-- CreateIndex
CREATE INDEX "PaymentTransactionLog_paymentId_idx" ON "PaymentTransactionLog"("paymentId");

-- CreateIndex
CREATE INDEX "PaymentTransactionLog_action_idx" ON "PaymentTransactionLog"("action");

-- CreateIndex
CREATE INDEX "PaymentTransactionLog_createdAt_idx" ON "PaymentTransactionLog"("createdAt");

-- CreateIndex
CREATE INDEX "WebhookEvent_paymentId_idx" ON "WebhookEvent"("paymentId");

-- CreateIndex
CREATE INDEX "WebhookEvent_eventType_idx" ON "WebhookEvent"("eventType");

-- CreateIndex
CREATE INDEX "WebhookEvent_processedAt_idx" ON "WebhookEvent"("processedAt");

-- CreateIndex
CREATE INDEX "Review_shopId_idx" ON "Review"("shopId");

-- CreateIndex
CREATE INDEX "WaitTimeMetric_shopId_barberId_category_idx" ON "WaitTimeMetric"("shopId", "barberId", "category");

-- CreateIndex
CREATE INDEX "WaitTimeMetric_recordedAt_idx" ON "WaitTimeMetric"("recordedAt");

-- CreateIndex
CREATE INDEX "ShopAnalyticDaily_shopId_date_idx" ON "ShopAnalyticDaily"("shopId", "date");

-- CreateIndex
CREATE UNIQUE INDEX "ShopAnalyticDaily_shopId_date_key" ON "ShopAnalyticDaily"("shopId", "date");

-- CreateIndex
CREATE INDEX "RebookingReminder_reminderAt_idx" ON "RebookingReminder"("reminderAt");

-- CreateIndex
CREATE INDEX "RebookingReminder_userId_idx" ON "RebookingReminder"("userId");

-- CreateIndex
CREATE INDEX "RebookingReminder_shopId_idx" ON "RebookingReminder"("shopId");

-- CreateIndex
CREATE INDEX "RebookingReminder_sentAt_idx" ON "RebookingReminder"("sentAt") WHERE ("sentAt" IS NULL);

-- CreateIndex
CREATE INDEX "EventLog_type_createdAt_idx" ON "EventLog"("type", "createdAt");

-- CreateIndex
CREATE INDEX "EventLog_shopId_createdAt_idx" ON "EventLog"("shopId", "createdAt");

-- CreateIndex
CREATE INDEX "EventLog_bookingId_idx" ON "EventLog"("bookingId");

-- CreateIndex
CREATE INDEX "EventLog_correlationId_idx" ON "EventLog"("correlationId");

-- AddForeignKey
ALTER TABLE "DeviceToken" ADD CONSTRAINT "DeviceToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Shop" ADD CONSTRAINT "Shop_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ShopOperatingHour" ADD CONSTRAINT "ShopOperatingHour_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ShopPhoto" ADD CONSTRAINT "ShopPhoto_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Barber" ADD CONSTRAINT "Barber_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Barber" ADD CONSTRAINT "Barber_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BarberService" ADD CONSTRAINT "BarberService_barberId_fkey" FOREIGN KEY ("barberId") REFERENCES "Barber"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BarberService" ADD CONSTRAINT "BarberService_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "Service"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Chair" ADD CONSTRAINT "Chair_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Service" ADD CONSTRAINT "Service_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_barberId_fkey" FOREIGN KEY ("barberId") REFERENCES "Barber"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_chairId_fkey" FOREIGN KEY ("chairId") REFERENCES "Chair"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "Service"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QueueEntry" ADD CONSTRAINT "QueueEntry_barberId_fkey" FOREIGN KEY ("barberId") REFERENCES "Barber"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QueueEntry" ADD CONSTRAINT "QueueEntry_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QueueEntry" ADD CONSTRAINT "QueueEntry_chairId_fkey" FOREIGN KEY ("chairId") REFERENCES "Chair"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QueueEntry" ADD CONSTRAINT "QueueEntry_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QueueEvent" ADD CONSTRAINT "QueueEvent_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QueueEvent" ADD CONSTRAINT "QueueEvent_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChairAllocation" ADD CONSTRAINT "ChairAllocation_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChairAllocation" ADD CONSTRAINT "ChairAllocation_chairId_fkey" FOREIGN KEY ("chairId") REFERENCES "Chair"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChairAllocation" ADD CONSTRAINT "ChairAllocation_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentTransactionLog" ADD CONSTRAINT "PaymentTransactionLog_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "Payment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WebhookEvent" ADD CONSTRAINT "WebhookEvent_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "Payment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WaitTimeMetric" ADD CONSTRAINT "WaitTimeMetric_barberId_fkey" FOREIGN KEY ("barberId") REFERENCES "Barber"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RebookingReminder" ADD CONSTRAINT "RebookingReminder_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RebookingReminder" ADD CONSTRAINT "RebookingReminder_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "Service"("id") ON DELETE CASCADE ON UPDATE CASCADE;
