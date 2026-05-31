CREATE TYPE "ServiceCategory" AS ENUM ('HAIRCUT', 'BEARD', 'COMBO');

ALTER TABLE "Service" ADD COLUMN IF NOT EXISTS "category" "ServiceCategory" NOT NULL DEFAULT 'HAIRCUT';

CREATE INDEX IF NOT EXISTS "Service_shopId_category_idx" ON "Service"("shopId", "category");
