-- CreateEnum
CREATE TYPE "EventLogType" AS ENUM ('BOOKING_CREATED', 'BOOKING_CANCELLED', 'QUEUE_JOINED', 'QUEUE_LEFT', 'CHAIR_ASSIGNED', 'CHAIR_RELEASED');

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
CREATE INDEX "EventLog_type_createdAt_idx" ON "EventLog"("type", "createdAt");

-- CreateIndex
CREATE INDEX "EventLog_shopId_createdAt_idx" ON "EventLog"("shopId", "createdAt");

-- CreateIndex
CREATE INDEX "EventLog_bookingId_idx" ON "EventLog"("bookingId");

-- CreateIndex
CREATE INDEX "EventLog_correlationId_idx" ON "EventLog"("correlationId");
