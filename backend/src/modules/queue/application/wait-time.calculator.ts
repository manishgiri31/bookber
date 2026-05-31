import type { ServiceCategory } from "@prisma/client";
import type {
  BarberRuntimeState,
  BookingWaitSnapshot,
  CategoryAverages,
  WaitEstimateResult,
  WaitShopConfig
} from "../domain/wait-time.types.js";

const HISTORICAL_WEIGHT = 0.7;
const RECENT_WEIGHT = 0.3;

export type WaitCalculationInput = {
  now: Date;
  config: WaitShopConfig;
  entries: BookingWaitSnapshot[];
  shopHistorical: CategoryAverages;
  shopRecent: CategoryAverages;
  barberHistorical: Map<string, CategoryAverages>;
  barberRecent: Map<string, CategoryAverages>;
  barberState: Map<string, BarberRuntimeState>;
  barberSpeedFactors: Map<string, number>;
  activeChairs: number;
};

/**
 * Blend shop + barber category averages:
 *   newEstimate = historical * 0.7 + recent * 0.3
 * Fallback: catalog duration on service.
 */
export function blendCategoryDurationMinutes(args: {
  category: ServiceCategory;
  catalogDurationMinutes: number;
  shopHistorical: CategoryAverages;
  shopRecent: CategoryAverages;
  barberHistorical?: CategoryAverages;
  barberRecent?: CategoryAverages;
  speedFactor?: number;
}): number {
  const shopHist = args.shopHistorical[args.category];
  const shopRec = args.shopRecent[args.category];
  const barberHist = args.barberHistorical?.[args.category];
  const barberRec = args.barberRecent?.[args.category];

  const historical =
    barberHist ?? shopHist ?? args.catalogDurationMinutes;
  const recent =
    barberRec ?? shopRec ?? args.catalogDurationMinutes;

  const blended = Math.round(historical * HISTORICAL_WEIGHT + recent * RECENT_WEIGHT);
  const factored = Math.round(blended * (args.speedFactor ?? 1));
  return Math.max(1, factored);
}

function inServiceRemainingMinutes(entry: BookingWaitSnapshot, now: Date): number {
  if (entry.queueStatus !== "IN_SERVICE" && entry.queueStatus !== "CALLED") {
    return entry.inServiceRemainingMinutes;
  }
  if (entry.inServiceRemainingMinutes > 0) {
    return entry.inServiceRemainingMinutes;
  }
  const startMs = Date.parse(entry.estimatedServiceStartIso);
  if (Number.isNaN(startMs)) return 0;
  const elapsed = Math.max(0, (now.getTime() - startMs) / 60_000);
  return Math.max(0, Math.round(entry.catalogDurationMinutes - elapsed));
}

function delayForBarber(
  barberId: string | null,
  barberState: Map<string, BarberRuntimeState>
): number {
  if (!barberId) return 0;
  return barberState.get(barberId)?.delayMinutes ?? 0;
}

function overrunForBarber(
  barberId: string | null,
  barberState: Map<string, BarberRuntimeState>
): number {
  if (!barberId) return 0;
  return barberState.get(barberId)?.overrunMinutes ?? 0;
}

/**
 * Core wait algorithm:
 *
 *   estimatedWait =
 *     ceil( sum(remaining durations ahead) / activeChairs )
 *     + cleaningBuffer
 *     + delayCompensation
 *     + overrunCompensation
 *
 * IN_SERVICE/CALLED entries ahead consume effective chair capacity via remaining time.
 */
export function calculateLaneWaitEstimates(input: WaitCalculationInput): WaitEstimateResult[] {
  const chairCount = Math.max(1, input.activeChairs);
  const sorted = [...input.entries].sort((a, b) => a.position - b.position);
  const cleaningBuffer = input.config.cleaningBufferMinutes;

  const loadAheadMinutes: number[] = [];

  return sorted.map((entry, index) => {
    const speed = entry.barberId
      ? input.barberSpeedFactors.get(entry.barberId) ?? 1
      : 1;

    const effectiveDuration = (() => {
      const blendArgs: Parameters<typeof blendCategoryDurationMinutes>[0] = {
        category: entry.serviceCategory,
        catalogDurationMinutes: entry.catalogDurationMinutes,
        shopHistorical: input.shopHistorical,
        shopRecent: input.shopRecent,
        speedFactor: speed
      };
      if (entry.barberId) {
        const barberHist = input.barberHistorical.get(entry.barberId);
        const barberRec = input.barberRecent.get(entry.barberId);
        if (barberHist !== undefined) blendArgs.barberHistorical = barberHist;
        if (barberRec !== undefined) blendArgs.barberRecent = barberRec;
      }
      return blendCategoryDurationMinutes(blendArgs);
    })();

    const remaining =
      entry.queueStatus === "IN_SERVICE" || entry.queueStatus === "CALLED"
        ? inServiceRemainingMinutes(entry, input.now)
        : effectiveDuration;

    const aheadSum = loadAheadMinutes.reduce((s, m) => s + m, 0);
    const baseWait = Math.ceil(aheadSum / chairCount);
    const delayComp = delayForBarber(entry.barberId, input.barberState);
    const overrunComp = overrunForBarber(entry.barberId, input.barberState);

    const estimatedWaitMinutes =
      baseWait + cleaningBuffer + delayComp + overrunComp;

    const estimatedServiceStart = new Date(
      input.now.getTime() + estimatedWaitMinutes * 60_000
    );

    loadAheadMinutes.push(remaining);

    return {
      bookingId: entry.bookingId,
      position: index + 1,
      estimatedWaitMinutes,
      estimatedServiceStart,
      effectiveDurationMinutes: effectiveDuration,
      cleaningBufferMinutes: cleaningBuffer,
      delayCompensationMinutes: delayComp,
      overrunCompensationMinutes: overrunComp
    };
  });
}

export function arrivalWindowFromWait(
  estimatedServiceStart: Date,
  bufferMinutes = 15
): { start: Date; end: Date } {
  const start = new Date(estimatedServiceStart.getTime() - bufferMinutes * 60_000);
  const end = new Date(estimatedServiceStart.getTime() + bufferMinutes * 60_000);
  return { start, end };
}

/** EWMA update for recent average store (α = 0.3) */
export function updateRecentAverage(current: number | undefined, sampleMinutes: number): number {
  if (current == null || current <= 0) return Math.round(sampleMinutes);
  return Math.round(current * 0.7 + sampleMinutes * 0.3);
}

/** Slow historical drift toward sample (α = 0.1) for DB persistence */
export function updateHistoricalAverage(current: number | undefined, sampleMinutes: number): number {
  if (current == null || current <= 0) return Math.round(sampleMinutes);
  return Math.round(current * 0.9 + sampleMinutes * 0.1);
}
