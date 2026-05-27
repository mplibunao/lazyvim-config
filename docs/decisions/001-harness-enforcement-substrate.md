# ADR-001: Harness enforcement substrate

**Status:** accepted
**Date:** 2026-05-27

## Context

nvim-lazy was convention-rich but enforcement-free: a clean router `CLAUDE.md`,
indexed docs, and manually-run snippets in `docs/workflows.md`, but no
automated validation runner, no Lua linter, no doc validator, no git hook, and
no CI. Every rule was prose-only.

The harness engineering adoption plan
(`exec-plans/active/harness-engineering-adoption-2026-05-27.md`) adds the
missing enforcement layer. Before writing a single script, four core
choices needed locking:

1. **Runner:** what orchestrates all checks locally and in CI?
2. **Logic check language:** where do checks with real parsing or validation
   logic live?
3. **Hook strategy:** what runs at commit time, and how much?
4. **CI strategy:** is a CI backstop worth the overhead for a personal config
   repo?

## Decision

**Runner: `justfile`.** One `just check` aggregates all gates. Per-domain
recipes (`just fmt`, `just lint`, `just docs`, `just guard`, `just prose`,
`just nvim`, `just test`, `just vet`) are independently runnable. Thin
tool-wrappers are inline recipes; only logic-heavy checks get their own files
under `scripts/`.

**Logic checks: Go (stdlib-only), module at `scripts/`.** Checks with real
parsing logic (the doc validator, future structural checks) are written in Go.
`go.mod` lives under `scripts/` (not at repo root), keeping the root clean
and separating harness tooling from the `test-fixtures/go/` fixture module.
No external deps, no `go.sum`. `gofmt`, `go vet`, and `go test` are bundled in
the toolchain, so the logic layer is formatted, linted, and tested with zero
additional tooling. Validator `_test.go` files wire into `just test`, so the
harness tests its own tooling.

**Hook: full gate, every commit.** `.githooks/pre-commit` delegates to
`just check` with no independent logic. The hook runs every named recipe on every commit. The no-drift guarantee is structural: both
local and CI invoke the same `just` recipe definitions. CI may omit `just nvim`
by deliberate scoping (see CI decision below and Risks); that is an explicit
subset choice, not silent parity drift.

**CI: deliberate backstop.** `.github/workflows/ci.yml` runs a deterministic
subset on push/PR, explicitly omitting `just nvim` until headless nvim is
stable in CI. CI catches commits that bypassed the local hook. The subset is a
named decision, not silent drift; both surfaces share the same `just` recipe
definitions. Kept as best-practice regardless of repo size.

**Remediation-first failures.** Every check prints what to fix, where, and why.
Failure messages inject the fix into agent context automatically, per
`docs/design-docs/core-beliefs.md`.

## Alternatives considered

**TS + bun with vite-plus/vitest.** The right choice for claude-toolkit (a TS
monorepo), but adds `package.json`, `node_modules`, and a lockfile to a repo
that is not primarily TypeScript. Go erases that footprint entirely, and the
repo already targets Go via `test-fixtures/go/`, gopls, and neotest-go.
Rejected.

**Makefile.** Functional but less composable than `justfile`. `just` offers
clearer recipe syntax, named dependencies, and built-in `--list`. No capability gap for this use case. Rejected in favor of `just`.

**Shell scripts under `scripts/`.** Workable for thin wrappers but no bundled
formatter, linter, or test runner. Logic-heavy checks in shell become fragile
and untestable. Rejected for logic-heavy checks; inline `just` recipes cover
the thin-wrapper case.

**Minimal merge gate (fast subset only).** A deliberately cheap pre-commit
check (format only, or nothing) with CI as the enforcement backstop. Rejected: local
and CI behavior would diverge, and agents iterating on changes would not get
immediate feedback without manual CI triggers.

**Product-scale machinery** (observability stacks, per-worktree app boot,
Chrome DevTools runtime, ports-and-adapters architecture, agent-to-agent PR
review) solves problems a personal config repo does not have. Rejected as out
of scope; not deferred.

## Consequences

- Zero npm footprint in this repo. `go.mod` is the only new project-manifest
  file.
- `gofmt`, `go vet`, and `go test` are all built-in; the logic layer's quality
  bar is enforced without adding tools.
- The full pre-commit gate adds per-commit latency (especially the headless nvim
  check). Accepted cost for complete local validation on every commit.
- CI deliberately omits `just nvim` until a cached lazy.nvim bootstrap is
  stable in CI. This is an explicit scope decision recorded here; both surfaces
  use the same named recipe definitions.
- Per-domain recipes (`just lint`, `just docs`, etc.) let agents and humans run
  fast subsets while iterating; `just check` remains the final local gate.
- All future checks wire into `just check` first; the hook inherits them
  automatically. CI runs a deliberate subset via `just ci` (`fmt lint docs guard
  prose test vet`); any new check that belongs in CI must be added to that
  recipe deliberately, keeping the subset declaration in the justfile rather
  than duplicated in the workflow YAML.

## Migration

Rollout sequence is owned by the adoption plan
(`exec-plans/active/harness-engineering-adoption-2026-05-27.md`).

Shape in brief: toolchain provisioned first; `justfile` and `go.mod` added as
the runner spine; per-gate recipes wired in one at a time; pre-commit hook
added locally; CI added as the push backstop. Each step is independently
reversible.

## Risks

- **Headless nvim is slow in CI.** Mitigated by running a deterministic subset
  in CI (omitting `just nvim`) until a cached lazy.nvim bootstrap is stable;
  the full gate stays local.
- **Go toolchain must be on PATH.** Already provisioned via
  Nix (this repo targets Go via test-fixtures/go and gopls); confirmed during
  toolchain provisioning.
- **selene std false-positives.** The Neovim standard library definition must
  cover all injected globals (`vim`, `LazyVim`, `Snacks`, etc.). Addressed when
  wiring `selene.toml`.
