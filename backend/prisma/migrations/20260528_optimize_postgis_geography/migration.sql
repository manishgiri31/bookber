-- Optimize PostGIS for high-performance nearby barber search.
-- Aligns with the current Prisma schema:
--   Shop.location geography(Point,4326)
--   QueueEntry replaces the obsolete ActiveQueue table

CREATE EXTENSION IF NOT EXISTS postgis;

-- The earlier PostGIS migration created Shop.location as geometry(Point,4326).
-- Current Prisma schema uses geography(Point,4326) for accurate meter-based distance queries.
ALTER TABLE "Shop"
  ADD COLUMN IF NOT EXISTS "location" geography(Point,4326);

DROP INDEX IF EXISTS "Shop_location_idx";
DROP INDEX IF EXISTS "Shop_location_geography_idx";

ALTER TABLE "Shop"
  ALTER COLUMN "location" TYPE geography(Point,4326)
  USING CASE
    WHEN "location" IS NULL THEN NULL
    ELSE "location"::geography
  END;

-- Backfill existing shop rows from latitude/longitude.
UPDATE "Shop"
SET "location" = ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography
WHERE "location" IS NULL
  AND "latitude" IS NOT NULL
  AND "longitude" IS NOT NULL;

-- Keep location synchronized when coordinates change.
CREATE OR REPLACE FUNCTION update_shop_location()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."latitude" IS NOT NULL AND NEW."longitude" IS NOT NULL THEN
    NEW."location" = ST_SetSRID(ST_MakePoint(NEW."longitude", NEW."latitude"), 4326)::geography;
  ELSE
    NEW."location" = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS shop_location_update_trigger ON "Shop";
CREATE TRIGGER shop_location_update_trigger
BEFORE INSERT OR UPDATE OF "latitude", "longitude" ON "Shop"
FOR EACH ROW EXECUTE FUNCTION update_shop_location();

-- Spatial and filter indexes used by nearby shop search.
CREATE INDEX IF NOT EXISTS "Shop_location_idx"
  ON "Shop" USING GIST ("location");

CREATE INDEX IF NOT EXISTS "Shop_active_location_idx"
  ON "Shop" ("isActive")
  WHERE "location" IS NOT NULL;

CREATE INDEX IF NOT EXISTS "Shop_city_idx"
  ON "Shop" ("city");

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'Shop'
      AND column_name = 'isAcceptingBookings'
  ) AND EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'Shop'
      AND column_name = 'isAcceptingWalkIns'
  ) THEN
    EXECUTE '
      CREATE INDEX IF NOT EXISTS "Shop_accepting_location_idx"
        ON "Shop" ("isAcceptingBookings", "isAcceptingWalkIns")
        WHERE "location" IS NOT NULL
    ';
  END IF;
END;
$$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'Shop'
      AND column_name = 'bookBerReservedChairCount'
  ) THEN
    EXECUTE '
      CREATE INDEX IF NOT EXISTS "Shop_premium_chairs_idx"
        ON "Shop" ("bookBerReservedChairCount")
        WHERE "bookBerReservedChairCount" > 0
    ';
  END IF;
END;
$$;

-- Current schema uses QueueEntry, not the obsolete ActiveQueue table.
-- Use a guarded block so this optimization migration remains safe while older
-- migration history is being reconciled in shadow databases.
DO $$
BEGIN
  IF to_regclass('"QueueEntry"') IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = current_schema()
        AND table_name = 'QueueEntry'
        AND column_name = 'shopId'
    )
    AND EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = current_schema()
        AND table_name = 'QueueEntry'
        AND column_name = 'estimatedWaitMinutes'
    )
    AND EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = current_schema()
        AND table_name = 'QueueEntry'
        AND column_name = 'queueStatus'
    )
  THEN
    EXECUTE '
      CREATE INDEX IF NOT EXISTS "QueueEntry_shop_wait_idx"
        ON "QueueEntry" ("shopId", "estimatedWaitMinutes")
        WHERE "queueStatus" IN (''WAITING'', ''READY'', ''CALLED'')
    ';
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS "Chair_shop_available_idx"
  ON "Chair" ("shopId", "status")
  WHERE "status" = 'AVAILABLE';

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'BookingStatus'
      AND e.enumlabel = 'QUEUED'
  ) THEN
    EXECUTE '
      CREATE INDEX IF NOT EXISTS "Booking_shop_status_idx"
        ON "Booking" ("shopId", "status")
        WHERE "status" IN (''QUEUED'', ''READY'', ''CALLED'', ''IN_SERVICE'')
    ';
  END IF;
END;
$$;
