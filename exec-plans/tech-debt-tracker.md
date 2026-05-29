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

## TD-008: Migrate CI tool provisioning from manual installs to mise

**Status:** Deferred; current manual installs in `.github/workflows/ci.yml` work and the PR shipped green. Switch is high-leverage but not urgent.
**Deferred from:** PR review discussion, 2026-05-28.
**Active plan:** `exec-plans/active/mise-tooling-and-changelog-2026-05-29.md`

CI currently installs `selene`, `stylua`, `ast-grep`, `vale`, and `go` via per-tool curl/install blocks. Local versions come from Nix (`dotfiles/nix/home/mp/modules/`). The Nix module and the CI workflow can pin different versions. Drift causes "passes locally, fails CI" (or vice versa) bugs; the `41ccc8d` selene install-permissions fix was a symptom of this surface, not the last one we'll hit.

A `mise.toml` collapses both sides to one pinned version per tool, consumed by `jdx/mise-action` in CI and `mise install` locally. The result is a single version source with fewer install scripts, plus a lighter CI bootstrap than Nix-in-CI would give.

The split heuristic recorded for future tool decisions:
- **mise** owns tools whose exact version determines a CI gate's behavior or output (formatters, linters, prose checkers, language toolchains used by repo scripts).
- **Nix** owns machine-baseline tools by default (`gh`, shell, editors, window manager). Repo gate runners such as `just` may be pinned by mise when their version affects the harness or when repo isolation is explicitly desired.
- **Edge case (Vale):** Vale is consumed by repos without repo-local config too (via the `doc-garden` skill running against arbitrary repos). Vale needs to be available globally via Nix and pinned per-repo via mise. mise shims win inside this repo; Nix Vale is the fallback elsewhere. Same pattern applies to `ast-grep` for ad-hoc cross-repo searches.

**Original trigger conditions:** These conditions started the migration plan; keep them here as history until TD-008 is closed during plan closeout.
- A 6th tool is about to be added to `ci.yml`'s install steps.
- A CI/local version mismatch produces a "passes locally, fails CI" failure.
- A Nix package version bumps in dotfiles and we forget to update the CI install URL (or vice versa).
