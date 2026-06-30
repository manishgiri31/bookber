-- Round 1: roles, scheduling, barber break, shop staff, booking reference images

-- AlterEnum: UserRole += OWNER, RECEPTION
ALTER TYPE "UserRole" ADD VALUE 'OWNER';
ALTER TYPE "UserRole" ADD VALUE 'RECEPTION';

-- AlterEnum: BookingStatus += SCHEDULED
ALTER TYPE "BookingStatus" ADD VALUE 'SCHEDULED';

-- AlterEnum: QueueEventType += SCAN_CHECK_IN, PROMOTED
ALTER TYPE "QueueEventType" ADD VALUE 'SCAN_CHECK_IN';
ALTER TYPE "QueueEventType" ADD VALUE 'PROMOTED';

-- AlterEnum: EventLogType += BOOKING_SCHEDULED, LEAVE_NOW_SENT, RECEPTION_CHECKIN
ALTER TYPE "EventLogType" ADD VALUE 'BOOKING_SCHEDULED';
ALTER TYPE "EventLogType" ADD VALUE 'LEAVE_NOW_SENT';
ALTER TYPE "EventLogType" ADD VALUE 'RECEPTION_CHECKIN';

-- AlterTable: Booking += scheduledStart, travelMinutes
ALTER TABLE "Booking" ADD COLUMN "scheduledStart" TIMESTAMP(3);
ALTER TABLE "Booking" ADD COLUMN "travelMinutes" INTEGER;

-- AlterTable: Barber += onBreak
ALTER TABLE "Barber" ADD COLUMN "onBreak" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable: ShopStaff
CREATE TABLE "ShopStaff" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ShopStaff_pkey" PRIMARY KEY ("id")
);

-- CreateTable: BookingReferenceImage
CREATE TABLE "BookingReferenceImage" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BookingReferenceImage_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: Booking.scheduledStart
CREATE INDEX "Booking_scheduledStart_idx" ON "Booking"("scheduledStart");

-- CreateUniqueIndex: ShopStaff
CREATE UNIQUE INDEX "ShopStaff_shopId_userId_key" ON "ShopStaff"("shopId", "userId");
CREATE INDEX "ShopStaff_shopId_idx" ON "ShopStaff"("shopId");
CREATE INDEX "ShopStaff_userId_idx" ON "ShopStaff"("userId");

-- CreateIndex: BookingReferenceImage
CREATE INDEX "BookingReferenceImage_bookingId_idx" ON "BookingReferenceImage"("bookingId");

-- AddForeignKey: ShopStaff
ALTER TABLE "ShopStaff" ADD CONSTRAINT "ShopStaff_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ShopStaff" ADD CONSTRAINT "ShopStaff_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: BookingReferenceImage
ALTER TABLE "BookingReferenceImage" ADD CONSTRAINT "BookingReferenceImage_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;
