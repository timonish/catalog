// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, test } from "bun:test";
import { stripSchemaComments } from "./vendor.ts";

describe("stripSchemaComments", () => {
  test("drops comment-only lines, indented included", () => {
    const source = [
      "// Package doc.",
      "package v1",
      "",
      "#Pod: {",
      "\t// The pod spec.",
      "\tspec?: #PodSpec",
      "}",
    ].join("\n");
    expect(stripSchemaComments(source)).toBe(
      ["package v1", "", "#Pod: {", "\tspec?: #PodSpec", "}"].join("\n"),
    );
  });

  test("keeps trailing comments on code lines", () => {
    const source = 'kind: "Pod" // always Pod';
    expect(stripSchemaComments(source)).toBe(source);
  });

  test("keeps comment-looking lines inside multiline strings", () => {
    const source = [
      "doc: \"\"\"",
      "\t// not a comment",
      "\t\"\"\"",
      "// a comment",
      "x: 1",
    ].join("\n");
    expect(stripSchemaComments(source)).toBe(
      ["doc: \"\"\"", "\t// not a comment", "\t\"\"\"", "x: 1"].join("\n"),
    );
  });
});
