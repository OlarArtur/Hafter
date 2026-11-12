/**
 * Pure routing, cache, and rate-limit helpers for the TMDb proxy.
 * The Cloud Function in index.ts is the only caller that talks to TMDb.
 * These helpers do not see the API key.
 */

export const SEARCH_TTL_MS = 10 * 60 * 1000;
export const DETAIL_TTL_MS = 6 * 60 * 60 * 1000;
export const MAX_QUERY_LENGTH = 200;

export interface TmdbRoute {
  /** Stable cache key. Does not include the API key. */
  cacheKey: string;
  ttlMs: number;
  /** Path beginning with / under https://api.themoviedb.org/3 */
  upstreamPath: string;
  /** Query items forwarded upstream. The API key is added by the function. */
  searchParams: Record<string, string>;
}

export function firstQueryValue(value: unknown): string | null {
  if (typeof value === "string") {
    return value;
  }
  if (Array.isArray(value) && typeof value[0] === "string") {
    return value[0];
  }
  return null;
}

/**
 * Allow only the two endpoints the iOS app calls:
 *   GET /search/movie?query=
 *   GET /movie/{numericId}
 * A leading /tmdb segment is stripped because Cloud Functions sometimes
 * includes the function name in req.path.
 */
export function resolveTmdbRoute(pathname: string, query: Record<string, unknown>): TmdbRoute | null {
  let path: string;
  try {
    path = decodeURIComponent(pathname.split("?")[0] ?? "");
  } catch {
    return null;
  }
  if (path.length > 1 && path.endsWith("/")) {
    path = path.slice(0, -1);
  }
  const lower = path.toLowerCase();
  if (lower === "/tmdb") {
    path = "/";
  } else if (lower.startsWith("/tmdb/")) {
    path = path.slice("/tmdb".length);
  }
  if (path.includes("..") || path.includes("//")) {
    return null;
  }

  if (path === "/search/movie") {
    const raw = firstQueryValue(query.query);
    if (raw == null) {
      return null;
    }
    const normalized = raw.replace(/\+/g, " ").replace(/\s+/g, " ").trim();
    if (normalized.length === 0 || normalized.length > MAX_QUERY_LENGTH) {
      return null;
    }
    return {
      cacheKey: `search:${normalized.toLowerCase()}`,
      ttlMs: SEARCH_TTL_MS,
      upstreamPath: "/search/movie",
      searchParams: { query: normalized },
    };
  }

  const movie = /^\/movie\/(\d+)$/.exec(path);
  if (movie) {
    const id = movie[1];
    return {
      cacheKey: `movie:${id}`,
      ttlMs: DETAIL_TTL_MS,
      upstreamPath: `/movie/${id}`,
      searchParams: {},
    };
  }

  return null;
}

interface Bucket {
  tokens: number;
  updated: number;
}

/**
 * Token bucket. Refills continuously over windowMs up to `limit` tokens.
 * One token is consumed per allowed call. State is per process, so the
 * limit applies to each Cloud Functions instance on its own.
 */
export class RateLimiter {
  private readonly buckets = new Map<string, Bucket>();
  private readonly limit: number;
  private readonly windowMs: number;
  private readonly maxSubjects: number;

  constructor(limit: number, windowMs: number, maxSubjects = 5000) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.maxSubjects = maxSubjects;
  }

  allow(subject: string, now = Date.now()): boolean {
    const existing = this.buckets.get(subject);
    const bucket: Bucket = existing ?? { tokens: this.limit, updated: now };
    const elapsed = Math.max(0, now - bucket.updated);
    const refill = (elapsed / this.windowMs) * this.limit;
    bucket.tokens = Math.min(this.limit, bucket.tokens + refill);
    bucket.updated = now;
    if (bucket.tokens < 1) {
      this.remember(subject, bucket);
      return false;
    }
    bucket.tokens -= 1;
    this.remember(subject, bucket);
    return true;
  }

  private remember(subject: string, bucket: Bucket): void {
    // Re-insert so the oldest subject is evicted first when the map is full.
    this.buckets.delete(subject);
    this.buckets.set(subject, bucket);
    while (this.buckets.size > this.maxSubjects) {
      const oldest = this.buckets.keys().next().value;
      if (oldest === undefined) {
        break;
      }
      this.buckets.delete(oldest);
    }
  }
}

export interface CachedResponse {
  expires: number;
  status: number;
  body: string;
  contentType: string;
}

export class ResponseCache {
  private readonly entries = new Map<string, CachedResponse>();
  private readonly maxEntries: number;

  constructor(maxEntries = 500) {
    this.maxEntries = maxEntries;
  }

  get(key: string, now = Date.now()): CachedResponse | null {
    const entry = this.entries.get(key);
    if (!entry) {
      return null;
    }
    if (entry.expires <= now) {
      this.entries.delete(key);
      return null;
    }
    // Refresh recency.
    this.entries.delete(key);
    this.entries.set(key, entry);
    return entry;
  }

  set(key: string, entry: CachedResponse): void {
    this.entries.delete(key);
    this.entries.set(key, entry);
    while (this.entries.size > this.maxEntries) {
      const oldest = this.entries.keys().next().value;
      if (oldest === undefined) {
        break;
      }
      this.entries.delete(oldest);
    }
  }
}
