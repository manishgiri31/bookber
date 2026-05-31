-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add location column to Shop table for geospatial indexing
ALTER TABLE "Shop" ADD COLUMN IF NOT EXISTS location geometry(Point,4326);

-- Create GIST index on location column for spatial queries
CREATE INDEX IF NOT EXISTS "Shop_location_idx" ON "Shop" USING GIST (location);

-- Update existing shops to populate location column from latitude and longitude
UPDATE "Shop" 
SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
WHERE location IS NULL AND latitude IS NOT NULL AND longitude IS NOT NULL;

-- Create trigger to automatically update location when latitude/longitude changes
CREATE OR REPLACE FUNCTION update_shop_location()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS shop_location_update_trigger ON "Shop";
CREATE TRIGGER shop_location_update_trigger
BEFORE INSERT OR UPDATE OF latitude, longitude ON "Shop"
FOR EACH ROW EXECUTE FUNCTION update_shop_location();
