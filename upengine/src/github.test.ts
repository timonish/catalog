// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { afterEach, describe, expect, spyOn, test } from "bun:test";
import { fetchRetry, matchGlob } from "./github.ts";

describe("matchGlob", () => {
  test("matches literally without a wildcard", () => {
    expect(matchGlob("envoy-gateway-crds.yaml", "envoy-gateway-crds.yaml")).toBe(true);
    expect(matchGlob("envoy-gateway-crds.yaml", "envoy-gateway-crds.yaml.sig")).toBe(false);
  });

  test("expands wildcards anywhere and anchors both ends", () => {
    expect(matchGlob("v*", "v1.9.1")).toBe(true);
    expect(matchGlob("v*", "helm-chart-v1.9.1")).toBe(false);
    expect(matchGlob("*.yaml", "crds.yaml")).toBe(true);
    expect(matchGlob("*.yaml", "crds.yaml.sig")).toBe(false);
    expect(matchGlob("bundle-*-crds.yaml", "bundle-v1-crds.yaml")).toBe(true);
    expect(matchGlob("*", "")).toBe(true);
  });

  test("treats regex metacharacters in the pattern literally", () => {
    expect(matchGlob("a.b", "axb")).toBe(false);
    expect(matchGlob("c++-*", "c++-1")).toBe(true);
    expect(matchGlob("(x)|y", "(x)|y")).toBe(true);
    expect(matchGlob("(x)|y", "y")).toBe(false);
  });
});

describe("fetchRetry", () => {
  const originalFetch = globalThis.fetch;
  let sleep: ReturnType<typeof spyOn> | undefined;

  function stubFetch(responses: (Response | Error)[]): string[] {
    const calls: string[] = [];
    globalThis.fetch = (async (url: string | URL | Request) => {
      calls.push(String(url));
      const next = responses.shift();
      if (next === undefined) {
        throw new Error("unexpected fetch call");
      }
      if (next instanceof Error) {
        throw next;
      }
      return next;
    }) as typeof fetch;
    sleep = spyOn(Bun, "sleep").mockResolvedValue(undefined);
    return calls;
  }

  afterEach(() => {
    globalThis.fetch = originalFetch;
    sleep?.mockRestore();
  });

  const status = (code: number, headers: Record<string, string> = {}) =>
    new Response(null, { status: code, headers });

  test("returns a successful response without retrying", async () => {
    const calls = stubFetch([status(200)]);
    const res = await fetchRetry("https://example.test/ok");
    expect(res.status).toBe(200);
    expect(calls).toEqual(["https://example.test/ok"]);
    expect(sleep).not.toHaveBeenCalled();
  });

  test("retries 429 and 5xx with exponential backoff", async () => {
    const calls = stubFetch([status(429), status(503), status(200)]);
    const res = await fetchRetry("https://example.test/flaky");
    expect(res.status).toBe(200);
    expect(calls).toHaveLength(3);
    expect(sleep!.mock.calls).toEqual([[1000], [2000]]);
  });

  test("returns the last error response once the retries are exhausted", async () => {
    stubFetch([status(500), status(500), status(502)]);
    const res = await fetchRetry("https://example.test/down");
    expect(res.status).toBe(502);
  });

  test("retries network errors and rethrows the last one", async () => {
    stubFetch([new Error("ECONNRESET"), new Error("ECONNRESET"), new Error("ETIMEDOUT")]);
    await expect(fetchRetry("https://example.test/net")).rejects.toThrow("ETIMEDOUT");
    expect(sleep!.mock.calls).toEqual([[1000], [2000]]);
  });

  test("does not retry client errors", async () => {
    const calls = stubFetch([status(404)]);
    const res = await fetchRetry("https://example.test/missing");
    expect(res.status).toBe(404);
    expect(calls).toHaveLength(1);
  });

  test("honors a capped Retry-After on a secondary rate limit", async () => {
    const calls = stubFetch([status(403, { "retry-after": "600" }), status(200)]);
    const res = await fetchRetry("https://example.test/secondary");
    expect(res.status).toBe(200);
    expect(calls).toHaveLength(2);
    expect(sleep!.mock.calls).toEqual([[60_000]]);
  });

  test("reports an exhausted API rate limit instead of a bare 403", async () => {
    stubFetch([status(403, { "x-ratelimit-remaining": "0" })]);
    await expect(fetchRetry("https://example.test/limited")).rejects.toThrow(
      "GitHub API rate limit exceeded; set GITHUB_TOKEN",
    );
    expect(sleep).not.toHaveBeenCalled();
  });

  test("returns a plain 403 without retrying", async () => {
    const calls = stubFetch([status(403)]);
    const res = await fetchRetry("https://example.test/forbidden");
    expect(res.status).toBe(403);
    expect(calls).toHaveLength(1);
  });
});
