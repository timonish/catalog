// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, test } from "bun:test";
import { recordRelease } from "./history.ts";

describe("recordRelease", () => {
  test("starts the record for a first release", () => {
    expect(recordRelease(undefined, "1.0.0-0", "2026-08-12T06:00:00.000Z")).toEqual([
      { version: "1.0.0-0", releasedAt: "2026-08-12T06:00:00.000Z" },
    ]);
  });

  test("prepends a newer version", () => {
    expect(
      recordRelease(
        [
          { version: "1.0.0-1", releasedAt: "2026-08-02T00:00:00.000Z" },
          { version: "1.0.0-0", releasedAt: "2026-08-01T00:00:00.000Z" },
        ],
        "1.1.0-0",
        "2026-08-03T00:00:00.000Z",
      ),
    ).toEqual([
      { version: "1.1.0-0", releasedAt: "2026-08-03T00:00:00.000Z" },
      { version: "1.0.0-1", releasedAt: "2026-08-02T00:00:00.000Z" },
      { version: "1.0.0-0", releasedAt: "2026-08-01T00:00:00.000Z" },
    ]);
  });

  test("keeps the original release time on a forced re-sync", () => {
    expect(
      recordRelease(
        [{ version: "1.0.0-0", releasedAt: "2026-08-01T00:00:00.000Z" }],
        "1.0.0-0",
        "2026-08-12T00:00:00.000Z",
      ),
    ).toEqual([{ version: "1.0.0-0", releasedAt: "2026-08-01T00:00:00.000Z" }]);
  });

  test("orders numeric build suffixes numerically", () => {
    const at = "2026-08-12T00:00:00.000Z";
    expect(
      recordRelease(
        [
          { version: "0.9.0-4", releasedAt: at },
          { version: "0.9.0-10", releasedAt: at },
        ],
        "0.9.0-2",
        at,
      ).map((r) => r.version),
    ).toEqual(["0.9.0-10", "0.9.0-4", "0.9.0-2"]);
  });
});
