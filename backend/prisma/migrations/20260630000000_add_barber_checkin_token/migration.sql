-- AlterTable: add checkInToken to Barber (nullable + unique)
ALTER TABLE "Barber" ADD COLUMN "checkInToken" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "Barber_checkInToken_key" ON "Barber"("checkInToken");
