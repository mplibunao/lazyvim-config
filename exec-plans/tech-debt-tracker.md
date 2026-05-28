# Tech-Debt Tracker

Durable home for deferred work items. Items are added at plan-write time; each
subsection carries the original reasoning so future maintainers know what was
declined vs. deferred.

## Status conventions

| Status | Meaning |
|---|---|
| **Deferred** | Valid goal; not worth doing yet. Has a trigger condition that should prompt revisiting. |
| **Declined** | Assessed and rejected. Reopen only if the stated trigger fires. |
| **Closed** | Complete or superseded. |

## TD-001: Interactive / visual smoke harness

**Status:** Deferred; headless harness first (Item 2).
**Deferred from:** `exec-plans/active/harness-engineering-adoption-2026-05-27.md`, Item 1

The current `docs/workflows.md` smoke-test checklist is interactive (opens
fixtures in a live Neovim session). Automating the visual parts of that
checklist (render-markdown rendering, Copilot suggestions, DAP UI) is
desirable but not cost-justified until the headless harness (Item 2) lands and
its coverage is known.

**Trigger:** If the headless harness misses a plugin-update regression that
would have been caught visually, revisit this. Otherwise keep the checklist
interactive and the headless harness deterministic.

## TD-002: ast-grep rule-catalog growth and `sg test` / `__snapshots__` harness

**Status:** Deferred; start with flat `sg scan`; revisit when the rule count grows.
**Deferred from:** `exec-plans/active/harness-engineering-adoption-2026-05-27.md`, Items 1 and 5

The full `sg test` + `__snapshots__/` apparatus (see surf-cli's
`guardrails/ast-grep/tests/core/`) is sized for a large rule catalog. With 1 to 3
rules, a flat `sg scan` (just `just guard`) is sufficient. As the catalog grows,
the snapshot harness adds regression protection for rule-match accuracy.

**Trigger:** When `guardrails/ast-grep/rules/` grows beyond ~5 rules, or any
rule has produced false positives requiring refinement.

## TD-004: Extract gofmt check to a helper script

**Status:** Deferred; inline is fine while the `fmt` recipe is the only shell-heavy check.
**Deferred from:** `exec-plans/active/harness-engineering-adoption-2026-05-27.md`, Item 2

The gofmt check in the `fmt` justfile recipe is inline shell. This is the right
tradeoff while it's the only multi-step shell block in the file.

**Trigger:** If Item 4 adds more shell-heavy Go checks, revisit extracting a
`scripts/check-gofmt.sh` helper to avoid recipe bloat.

## TD-006: Upstream doc-garden audit table newline rendering

**Status:** Deferred; upstream shared-tool issue discovered during Item 9 verification.
**Deferred from:** `exec-plans/active/harness-engineering-adoption-2026-05-27.md`, Item 9

The generated Doc Garden Markdown audit table can break rows when a Vale token contains a newline, including a token spanning two wrapped words in a current-state doc. The JSON sidecar remains valid, and generated audit Markdown is not hand-edited in this repo. The durable fix belongs in the shared `claude-toolkit/packages/doc-garden` renderer, where table cells should sanitize embedded newlines before writing `docs/generated/doc-garden/audit-*.md`. The owning upstream tracker item is `claude-toolkit/docs/exec-plans/tech-debt-tracker.md` TD-058.

**Trigger:** When updating the shared doc-garden package, sanitize multiline table cells in the renderer and rerun a consumer audit that includes a multiline Vale token.
