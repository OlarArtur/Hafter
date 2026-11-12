import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { RateLimiter, ResponseCache, resolveTmdbRoute } from "./tmdbProxy.ts";

describe("resolveTmdbRoute", () => {
  it("accepts a movie search and normalizes the query", () => {
    const route = resolveTmdbRoute("/search/movie", { query: "  The+Matrix  " });
    assert.ok(route);
    assert.equal(route.cacheKey, "search:the matrix");
    assert.equal(route.upstreamPath, "/search/movie");
    assert.deepEqual(route.searchParams, { query: "The Matrix" });
  });

  it("accepts the function-name prefix Cloud Functions sometimes adds", () => {
    const route = resolveTmdbRoute("/tmdb/movie/550", {});
    assert.ok(route);
    assert.equal(route.cacheKey, "movie:550");
    assert.equal(route.upstreamPath, "/movie/550");
  });

  it("rejects other TMDb endpoints, ids, and client api_key values", () => {
    assert.equal(resolveTmdbRoute("/movie/550/credits", {}), null);
    assert.equal(resolveTmdbRoute("/movie/not-a-number", {}), null);
    assert.equal(resolveTmdbRoute("/search/person", { query: "ada" }), null);
    assert.equal(resolveTmdbRoute("/search/movie", { query: "x", api_key: "stolen" })?.searchParams.api_key, undefined);
    assert.equal(resolveTmdbRoute("/search/movie", {}), null);
    assert.equal(resolveTmdbRoute("/search/movie", { query: "   " }), null);
    assert.equal(resolveTmdbRoute("/../search/movie", { query: "x" }), null);
  });

  it("rejects an oversized search", () => {
    assert.equal(resolveTmdbRoute("/search/movie", { query: "a".repeat(201) }), null);
  });
});

describe("RateLimiter", () => {
  it("allows a burst up to the limit and then refuses until the window refills", () => {
    const limiter = new RateLimiter(2, 1_000);
    assert.equal(limiter.allow("uid:a", 0), true);
    assert.equal(limiter.allow("uid:a", 0), true);
    assert.equal(limiter.allow("uid:a", 0), false);
    assert.equal(limiter.allow("uid:b", 0), true);
    assert.equal(limiter.allow("uid:a", 1_000), true);
  });
});

describe("ResponseCache", () => {
  it("returns a fresh entry, drops an expired one, and evicts the oldest", () => {
    const cache = new ResponseCache(2);
    cache.set("a", { expires: 100, status: 200, body: "a", contentType: "application/json" });
    cache.set("b", { expires: 100, status: 200, body: "b", contentType: "application/json" });
    assert.equal(cache.get("a", 50)?.body, "a");
    cache.set("c", { expires: 100, status: 200, body: "c", contentType: "application/json" });
    assert.equal(cache.get("b", 50), null);
    assert.equal(cache.get("a", 150), null);
  });
});
