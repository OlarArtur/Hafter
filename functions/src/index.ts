/**
 * TMDb proxy. Holds the v3 API key in the Cloud Functions secret TMDB_API_KEY
 * and forwards only the endpoints Hafter actually calls.
 *
 * Deploy steps, the Blaze plan requirement, and the client contract are in
 * functions/README.md.
 */

import { initializeApp } from "firebase-admin/app";
import { getAppCheck } from "firebase-admin/app-check";
import { getAuth } from "firebase-admin/auth";
import { defineSecret } from "firebase-functions/params";
import { onRequest } from "firebase-functions/v2/https";
import { RateLimiter, ResponseCache, resolveTmdbRoute } from "./tmdbProxy.js";

initializeApp();

const tmdbApiKey = defineSecret("TMDB_API_KEY");

const TMDB_ORIGIN = "https://api.themoviedb.org/3";
const RATE_LIMIT = 120;
const RATE_WINDOW_MS = 60 * 1000;
const UPSTREAM_TIMEOUT_MS = 10_000;
const MAX_CACHED_BODY = 1_000_000;

const limiter = new RateLimiter(RATE_LIMIT, RATE_WINDOW_MS);
const cache = new ResponseCache();

async function callerSubject(authorization: string | undefined, appCheckToken: string | undefined): Promise<string | null> {
  if (authorization) {
    const match = /^Bearer\s+(\S+)$/i.exec(authorization);
    if (!match) {
      return null;
    }
    try {
      const decoded = await getAuth().verifyIdToken(match[1]);
      return `uid:${decoded.uid}`;
    } catch {
      // A presented token that does not verify is a hard failure. Do not
      // fall through to App Check, or a bad Authorization header could be
      // paired with a captured App Check token to look legitimate.
      return null;
    }
  }

  if (appCheckToken) {
    try {
      const decoded = await getAppCheck().verifyToken(appCheckToken);
      const subject = decoded.token.sub || decoded.appId;
      return `appcheck:${subject}`;
    } catch {
      return null;
    }
  }

  return null;
}

export const tmdb = onRequest(
  {
    region: "us-central1",
    secrets: [tmdbApiKey],
    cors: false,
    invoker: "public",
    memory: "256MiB",
    timeoutSeconds: 30,
    maxInstances: 20,
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.set("Allow", "GET");
      res.status(405).send("Method not allowed");
      return;
    }

    const subject = await callerSubject(req.header("authorization"), req.header("x-firebase-appcheck"));
    if (!subject) {
      res.status(401).send("Sign in or App Check is required");
      return;
    }
    if (!limiter.allow(subject)) {
      res.set("Retry-After", String(Math.ceil(RATE_WINDOW_MS / 1000)));
      res.status(429).send("Too many requests");
      return;
    }

    const route = resolveTmdbRoute(req.path || "/", req.query as Record<string, unknown>);
    if (!route) {
      res.status(404).send("Unknown TMDb route");
      return;
    }

    const hit = cache.get(route.cacheKey);
    if (hit) {
      res.set("Cache-Control", `private, max-age=${Math.floor(route.ttlMs / 1000)}`);
      res.set("Vary", "Authorization");
      res.status(hit.status).type(hit.contentType).send(hit.body);
      return;
    }

    const upstream = new URL(TMDB_ORIGIN + route.upstreamPath);
    for (const [key, value] of Object.entries(route.searchParams)) {
      upstream.searchParams.set(key, value);
    }
    upstream.searchParams.set("api_key", tmdbApiKey.value());

    let upstreamResponse: Response;
    try {
      upstreamResponse = await fetch(upstream, { signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS) });
    } catch (error) {
      console.error(JSON.stringify({ kind: route.upstreamPath, error: error instanceof Error ? error.name : "fetch" }));
      res.status(502).send("TMDb is unavailable");
      return;
    }

    const body = await upstreamResponse.text();
    const contentType = upstreamResponse.headers.get("content-type") ?? "application/json; charset=utf-8";
    if (upstreamResponse.ok && body.length <= MAX_CACHED_BODY) {
      cache.set(route.cacheKey, {
        expires: Date.now() + route.ttlMs,
        status: upstreamResponse.status,
        body,
        contentType,
      });
    }

    console.info(JSON.stringify({ kind: route.upstreamPath, status: upstreamResponse.status, bytes: body.length }));
    res.set("Cache-Control", `private, max-age=${Math.floor(route.ttlMs / 1000)}`);
    res.set("Vary", "Authorization");
    res.status(upstreamResponse.status).type(contentType).send(body);
  },
);
