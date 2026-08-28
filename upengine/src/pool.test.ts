// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, test } from "bun:test";
import { runBoundedPool } from "./pool.ts";

describe("runBoundedPool", () => {
  test("keeps the input order and reports every failure", async () => {
    const results = await runBoundedPool(["a", "b", "c", "d"], 2, async (item, index) => {
      // Finish out of order: the earlier items take longer.
      await Bun.sleep((4 - index) * 5);
      if (item === "b") {
        throw new Error(`${item} failed`);
      }
      return item.toUpperCase();
    });
    expect(results).toEqual([
      { index: 0, item: "a", value: "A" },
      { index: 1, item: "b", error: new Error("b failed") },
      { index: 2, item: "c", value: "C" },
      { index: 3, item: "d", value: "D" },
    ]);
  });

  test("never exceeds the concurrency bound", async () => {
    let inFlight = 0;
    let peak = 0;
    const results = await runBoundedPool([1, 2, 3, 4, 5, 6, 7], 3, async (item) => {
      inFlight++;
      peak = Math.max(peak, inFlight);
      await Bun.sleep(2);
      inFlight--;
      return item * 2;
    });
    expect(peak).toBe(3);
    expect(results.map((r) => ("value" in r ? r.value : r.error))).toEqual([2, 4, 6, 8, 10, 12, 14]);
  });

  test("handles an empty input and a bound above the input size", async () => {
    expect(await runBoundedPool([], 4, async () => 1)).toEqual([]);
    const results = await runBoundedPool(["x"], 8, async (item) => item);
    expect(results).toEqual([{ index: 0, item: "x", value: "x" }]);
  });

  test("rejects an invalid concurrency", async () => {
    await expect(runBoundedPool([1], 0, async () => 1)).rejects.toThrow("positive integer");
    await expect(runBoundedPool([1], 1.5, async () => 1)).rejects.toThrow("positive integer");
  });
});
