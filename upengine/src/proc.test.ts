import { describe, expect, test } from "bun:test";
import { mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { retryRun } from "./proc";

/** A command that appends one line to `file` and exits 1 printing `message`. */
function failing(file: string, message: string): string[] {
  const script = `require("node:fs").appendFileSync(${JSON.stringify(file)}, "x\\n"); console.error(${JSON.stringify(message)}); process.exit(1);`;
  return ["bun", "-e", script];
}

describe("retryRun", () => {
  test("stops retrying on a definitive error", async () => {
    const dir = mkdtempSync(join(tmpdir(), "upengine-proc-"));
    const file = join(dir, "attempts");
    await expect(
      retryRun(failing(file, "GET ...: MANIFEST_UNKNOWN: Failed to fetch \"v0\""), 3, 0, {
        giveUpOn: /\bMANIFEST_UNKNOWN\b/,
      }),
    ).rejects.toThrow("MANIFEST_UNKNOWN");
    expect(readFileSync(file, "utf8")).toBe("x\n");
  });

  test("retries transient errors up to the attempt count", async () => {
    const dir = mkdtempSync(join(tmpdir(), "upengine-proc-"));
    const file = join(dir, "attempts");
    await expect(
      retryRun(failing(file, "connection reset"), 3, 0, { giveUpOn: /\bMANIFEST_UNKNOWN\b/ }),
    ).rejects.toThrow("did not succeed");
    expect(readFileSync(file, "utf8")).toBe("x\nx\nx\n");
  });
});
