-- Queue-first reserved capacity system

CREATE TYPE "QueueLane" AS ENUM ('BOOKBER', 'WALKIN');

CREATE TYPE "QueueEventType" AS ENUM (
  'ENQUEUED',
  'POSITION_CHANGED',
  'WAIT_RECALCULATED',
  'CALLED',
  'IN_SERVICE',
  'COMPLETED',
  'NO_SHOW',
  'CANCELLED',
  'CHAIR_ASSIGNED',
  'CHAIR_RELEASED',
  'DELAYED',
  'OVERRUN'
);

-- BookingStatus migration
ALTER TYPE "BookingStatus" RENAME TO "BookingStatus_old";
CREATE TYPE "BookingStatus" AS ENUM (
  'QUEUED',
  'READY',
  'CALLED',
  'IN_SERVICE',
  'COMPLETED',
  'CANCELLED',
  'NO_SHOW'
);

-- QueueStatus extension
ALTER TYPE "QueueStatus" ADD VALUE IF NOT EXISTS 'CALLED';
ALTER TYPE "QueueStatus" ADD VALUE IF NOT EXISTS 'NO_SHOW';
ALTER TYPE "QueueStatus" ADD VALUE IF NOT EXISTS 'CANCELLED';

ALTER TABLE "Shop" ADD COLUMN IF NOT EXISTS "bookBerReservedChairCount" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "Barber" ADD COLUMN IF NOT EXISTS "serviceSpeedFactor" DOUBLE PRECISION NOT NULL DEFAULT 1.0;
ALTER TABLE "Barber" ADD COLUMN IF NOT EXISTS "averageServiceMinutes" INTEGER;

ALTER TABLE "Chair" ADD COLUMN IF NOT EXISTS "reservedForBookBer" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "Chair" ADD COLUMN IF NOT EXISTS "activeServiceStart" TIMESTAMP(3);
ALTER TABLE "Chair" ADD COLUMN IF NOT EXISTS "activeServiceEnd" TIMESTAMP(3);
ALTER TABLE "Chair" ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE "Booking" ALTER COLUMN "barberId" DROP NOT NULL;

ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "queueLane" "QueueLane";
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "queueStatus" "QueueStatus" NOT NULL DEFAULT 'WAITING';
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "queuePosition" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "estimatedWaitMinutes" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "arrivalWindowStart" TIMESTAMP(3);
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "arrivalWindowEnd" TIMESTAMP(3);
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "estimatedServiceStart" TIMESTAMP(3);
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "estimatedServiceEnd" TIMESTAMP(3);
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "activeServiceStart" TIMESTAMP(3);
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "activeServiceEnd" TIMESTAMP(3);
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "walkIn" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "cancellationReason" TEXT;
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "cancelledAt" TIMESTAMP(3);
ALTER TABLE "Booking" ADD COLUMN IF NOT EXISTS "noShowAt" TIMESTAMP(3);

UPDATE "Booking" SET
  "arrivalWindowStart" = COALESCE("scheduledAt", NOW()),
  "arrivalWindowEnd" = COALESCE("scheduledAt", NOW()) + INTERVAL '30 minutes',
  "queueLane" = 'BOOKBER'
WHERE "arrivalWindowStart" IS NULL;

ALTER TABLE "Booking" ALTER COLUMN "arrivalWindowStart" SET NOT NULL;
ALTER TABLE "Booking" ALTER COLUMN "arrivalWindowEnd" SET NOT NULL;
ALTER TABLE "Booking" ALTER COLUMN "queueLane" SET NOT NULL;

ALTER TABLE "Booking" DROP COLUMN IF EXISTS "scheduledAt";
ALTER TABLE "Booking" DROP COLUMN IF EXISTS "estimatedStart";
ALTER TABLE "Booking" DROP COLUMN IF EXISTS "estimatedEnd";
ALTER TABLE "Booking" DROP COLUMN IF EXISTS "actualStart";
ALTER TABLE "Booking" DROP COLUMN IF EXISTS "actualEnd";

ALTER TABLE "Booking" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "Booking" ALTER COLUMN "status" TYPE "BookingStatus" USING (
  CASE "status"::text
    WHEN 'PENDING' THEN 'QUEUED'::"BookingStatus"
    WHEN 'CONFIRMED' THEN 'QUEUED'::"BookingStatus"
    WHEN 'WAITING' THEN 'QUEUED'::"BookingStatus"
    WHEN 'IN_SERVICE' THEN 'IN_SERVICE'::"BookingStatus"
    WHEN 'COMPLETED' THEN 'COMPLETED'::"BookingStatus"
    WHEN 'CANCELLED' THEN 'CANCELLED'::"BookingStatus"
    WHEN 'NO_SHOW' THEN 'NO_SHOW'::"BookingStatus"
    ELSE 'QUEUED'::"BookingStatus"
  END
);
ALTER TABLE "Booking" ALTER COLUMN "status" SET DEFAULT 'QUEUED';

DROP TYPE "BookingStatus_old";

DROP TABLE IF EXISTS "QueueEntry";

CREATE TABLE "ActiveQueue" (
  "id" TEXT NOT NULL,
  "shopId" TEXT NOT NULL,
  "bookingId" TEXT NOT NULL,
  "barberId" TEXT,
  "lane" "QueueLane" NOT NULL,
  "position" INTEGER NOT NULL,
  "queueStatus" "QueueStatus" NOT NULL DEFAULT 'WAITING',
  "estimatedWaitMinutes" INTEGER NOT NULL DEFAULT 0,
  "estimatedServiceStart" TIMESTAMP(3),
  "version" INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "ActiveQueue_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "QueueEvent" (
  "id" TEXT NOT NULL,
  "shopId" TEXT NOT NULL,
  "bookingId" TEXT,
  "type" "QueueEventType" NOT NULL,
  "payload" JSONB NOT NULL DEFAULT '{}',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "QueueEvent_pkey" PRIMARY KEY ("id")
);

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

CREATE UNIQUE INDEX "ActiveQueue_bookingId_key" ON "ActiveQueue"("bookingId");
CREATE INDEX "ActiveQueue_shopId_lane_position_idx" ON "ActiveQueue"("shopId", "lane", "position");
CREATE INDEX "ActiveQueue_shopId_position_idx" ON "ActiveQueue"("shopId", "position");
CREATE INDEX "ActiveQueue_barberId_queueStatus_idx" ON "ActiveQueue"("barberId", "queueStatus");

CREATE INDEX "QueueEvent_shopId_createdAt_idx" ON "QueueEvent"("shopId", "createdAt");
CREATE INDEX "QueueEvent_bookingId_idx" ON "QueueEvent"("bookingId");

CREATE INDEX "ChairAllocation_chairId_activeServiceStart_idx" ON "ChairAllocation"("chairId", "activeServiceStart");
CREATE INDEX "ChairAllocation_bookingId_idx" ON "ChairAllocation"("bookingId");
CREATE INDEX "ChairAllocation_shopId_idx" ON "ChairAllocation"("shopId");

CREATE INDEX "Booking_shopId_queuePosition_idx" ON "Booking"("shopId", "queuePosition");
CREATE INDEX "Booking_barberId_queueStatus_idx" ON "Booking"("barberId", "queueStatus");
CREATE INDEX "Booking_shopId_queueLane_queueStatus_idx" ON "Booking"("shopId", "queueLane", "queueStatus");

CREATE INDEX "Chair_shopId_reservedForBookBer_idx" ON "Chair"("shopId", "reservedForBookBer");
CREATE INDEX "Chair_activeServiceStart_idx" ON "Chair"("activeServiceStart");

ALTER TABLE "ActiveQueue" ADD CONSTRAINT "ActiveQueue_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ActiveQueue" ADD CONSTRAINT "ActiveQueue_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ActiveQueue" ADD CONSTRAINT "ActiveQueue_barberId_fkey" FOREIGN KEY ("barberId") REFERENCES "Barber"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "QueueEvent" ADD CONSTRAINT "QueueEvent_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "QueueEvent" ADD CONSTRAINT "QueueEvent_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "ChairAllocation" ADD CONSTRAINT "ChairAllocation_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ChairAllocation" ADD CONSTRAINT "ChairAllocation_chairId_fkey" FOREIGN KEY ("chairId") REFERENCES "Chair"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ChairAllocation" ADD CONSTRAINT "ChairAllocation_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;
