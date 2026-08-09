// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { fileURLToPath } from "node:url";

/** Repo root, derived from this file's location (upengine/src/paths.ts). */
export const ROOT_DIR = fileURLToPath(new URL("../../", import.meta.url));

export const MODULES_DIR = join(ROOT_DIR, "modules");
export const BUNDLES_DIR = join(ROOT_DIR, "test/bundles");
export const HISTORY_DIR = join(ROOT_DIR, "upengine/history");
export const README_PATH = join(ROOT_DIR, "README.md");
