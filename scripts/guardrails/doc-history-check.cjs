#!/usr/bin/env bun
"use strict";

const fs = require("node:fs");
const path = require("node:path");

const FLAGS_WITH_VALUES = new Set(["--policy", "--output", "--baseline", "--path"]);

function failUsage(message) {
  console.error(message);
  process.exit(2);
}

function readFlagValue(argv, index, flag) {
  const value = argv[index + 1];
  if (!value || value.startsWith("--")) {
    failUsage(`${flag} requires a non-empty value`);
  }
  return value;
}

function readEqualsValue(arg, flag) {
  const value = arg.slice(`${flag}=`.length);
  if (!value) {
    failUsage(`${flag} requires a non-empty value`);
  }
  return value;
}

function parseArgs(argv) {
  const args = { policy: path.join("guardrails", "doc-history", "policy.json"), output: "json" };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--policy") {
      args.policy = readFlagValue(argv, i, arg);
      i += 1;
    } else if (arg.startsWith("--policy=")) {
      args.policy = readEqualsValue(arg, "--policy");
    } else if (arg === "--output") {
      args.output = readFlagValue(argv, i, arg);
      i += 1;
    } else if (arg.startsWith("--output=")) {
      args.output = readEqualsValue(arg, "--output");
    } else if (arg === "--baseline") {
      readFlagValue(argv, i, arg);
      i += 1;
    } else if (arg.startsWith("--baseline=")) {
      readEqualsValue(arg, "--baseline");
    } else if (arg === "--path") {
      readFlagValue(argv, i, arg);
      i += 1;
    } else if (arg.startsWith("--path=")) {
      readEqualsValue(arg, "--path");
    } else if (FLAGS_WITH_VALUES.has(arg.split("=", 1)[0])) {
      failUsage(`${arg.split("=", 1)[0]} requires a non-empty value`);
    } else {
      failUsage(`Unknown argument: ${arg}`);
    }
  }
  return args;
}

function loadPolicy(policyPath) {
  const resolved = path.resolve(policyPath);
  try {
    return JSON.parse(fs.readFileSync(resolved, "utf8"));
  } catch (error) {
    console.error(`Unable to read policy at ${resolved}: ${error.message}`);
    process.exit(2);
  }
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.output !== "json") {
    failUsage("doc-history-check currently supports only --output=json");
  }

  const policy = loadPolicy(args.policy);
  if (Object.hasOwn(policy, "forbidden_tokens") && !Array.isArray(policy.forbidden_tokens)) {
    console.error("policy-shape error: forbidden_tokens must be an array when present");
    process.exit(2);
  }
  const forbiddenTokens = policy.forbidden_tokens ?? [];

  if (forbiddenTokens.length > 0) {
    console.error(
      "policy.json defines forbidden_tokens, but nvim-lazy has not adopted a repo-specific regex scanner yet. " +
        "Remove the tokens or replace scripts/guardrails/doc-history-check.cjs with a scanner that enforces them.",
    );
    process.exit(2);
  }

  // nvim-lazy currently relies on Vale plus RepoPrompt review for Doc Garden.
  // This scanner keeps the CLI bridge valid while failing closed if future
  // policy adds regex rules without an implementation.
  console.log(JSON.stringify({ findings: [] }));
}

main();
