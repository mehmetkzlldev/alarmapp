/**
 * Timezone helpers for daily AI missions.
 *
 * We use Intl (no extra deps) to compute the user's *local* calendar day and the
 * end-of-day boundary used for mission expiry. This keeps "today" correct for a
 * user in Tokyo even though the server runs in UTC.
 */

/** Return the YYYY-MM-DD calendar date in `timezone` for the given instant. */
export function localDateString(timezone: string, now: Date = new Date()): string {
  // en-CA formats as YYYY-MM-DD, which is exactly what we want.
  const fmt = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  return fmt.format(now);
}

/**
 * Compute the UTC instant corresponding to the END of the user's local day
 * (i.e. 23:59:59.999 local). Used as the mission's expiresAt.
 *
 * Strategy: take the local date, find local midnight of the *next* day, then
 * subtract 1ms. We derive the UTC offset for that timezone via the formatted
 * parts trick.
 */
export function endOfLocalDayUtc(
  timezone: string,
  now: Date = new Date(),
): Date {
  const dateStr = localDateString(timezone, now); // YYYY-MM-DD (local)
  const [y, m, d] = dateStr.split('-').map(Number);

  // Local midnight of the *next* day expressed as a naive wall-clock time.
  const nextDayWallMs = Date.UTC(y, m - 1, d + 1, 0, 0, 0, 0);

  // Determine the timezone's offset (minutes east of UTC) at that wall time by
  // formatting a probe instant and comparing components.
  const offsetMin = timezoneOffsetMinutes(timezone, new Date(nextDayWallMs));

  // Real UTC instant of next local midnight = wallClock - offset.
  const nextMidnightUtcMs = nextDayWallMs - offsetMin * 60_000;
  return new Date(nextMidnightUtcMs - 1); // 23:59:59.999 local
}

/**
 * Offset in minutes (east of UTC, positive) for `timezone` at instant `at`.
 * e.g. Asia/Tokyo => +540, America/New_York (EST) => -300.
 */
export function timezoneOffsetMinutes(timezone: string, at: Date): number {
  const dtf = new Intl.DateTimeFormat('en-US', {
    timeZone: timezone,
    hour12: false,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
  const parts = dtf.formatToParts(at);
  const get = (type: string) =>
    Number(parts.find((p) => p.type === type)?.value);
  const asUtc = Date.UTC(
    get('year'),
    get('month') - 1,
    get('day'),
    get('hour') === 24 ? 0 : get('hour'),
    get('minute'),
    get('second'),
  );
  return Math.round((asUtc - at.getTime()) / 60_000);
}

/**
 * Returns true if it is currently within the first hour AFTER local midnight in
 * `timezone`. Used by the hourly scheduler to pick which users to generate for
 * "now", so each user is generated exactly once per local day.
 */
export function isLocalMidnightHour(
  timezone: string,
  now: Date = new Date(),
): boolean {
  const fmt = new Intl.DateTimeFormat('en-US', {
    timeZone: timezone,
    hour12: false,
    hour: '2-digit',
  });
  const hour = Number(fmt.format(now));
  return hour === 0; // 00:00–00:59 local
}
