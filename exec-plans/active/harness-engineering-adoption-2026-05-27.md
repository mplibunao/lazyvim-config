# Harness-Engineering Adoption for nvim-lazy: Plan

> Plan location note: rp-deep-plan defaults to `docs/plans/`, but this repo's CLAUDE.md makes `exec-plans/active/` the home for in-progress plans (matching `exec-plans/completed/nix-neovim-tooling-2026-05-27.md`, `plugin-update-infra.md`). Repo convention wins.

## Goal

Build out the **mechanical-enforcement harness** that the OpenAI "harness engineering" approach calls for, adapted to this LazyVim config repo so it stays legible and self-correcting for AI agents. The repo is already strong on *structure* (router CLAUDE.md, indexed docs, exec-plans, test-fixtures). This plan adds the missing *enforcement* layer end to end: a runnable check harness, formatting plus Lua linting, structural ast-grep guardrails, deterministic doc validation, a Vale prose lane, agent-driven doc-gardening, an ADR decision layer, a `docs/design-docs/` restructure, and a local hook plus CI backstop. It still rejects product-scale *runtime* machinery (observability stacks, per-worktree boot, CDP, ports-and-adapters) that solves problems a config repo does not have.

> **Decisions locked with MP (Phase-5 checkpoint + refinement rounds):**
> - Scope: pull Selene, ast-grep guardrails, ADRs, doc-garden, and CI into this pass. Multi-agent execution is the intended path, so scope breadth is acceptable.
> - Runner: `justfile`. Logic-heavy checks are written in **Go** (`gofmt`, `go vet`, `go test` are all built in, zero `node_modules`); thin tool-wrappers are inline `just` recipes, not separate scripts.
> - Hook: pre-commit runs the **full** gate (format, lint, docs, guard, prose, self-tests, headless nvim).
> - Docs: adopt a `docs/design-docs/` directory and move the existing topic docs into it (Item 3). A flat `docs/` plus `decisions/` was rejected as awkward.
> - Absolute paths: only add the ban once a sanctioned pattern and migration exist (Item 6). A rule without a solution just bounces the problem back to the maintainer.
> - Prose: one cleanup pass over all docs when the Vale lane lands (little documentation today).
> - CI: kept; best-practice regardless of repo size.
> - Knip: declined (tracker TD-003, with reasoning).

## Implementation progress

- **Item 0 complete:** dotfiles prerequisite committed on branch `doc-garden-setup-vale-v111` as `c2da93c` (`selene`, Go toolchain, and global Vale vocab terms).
- **Items 1 and 3 complete:** nvim-lazy docs foundation landed in the docs-foundation commit: tech-debt tracker, root `ARCHITECTURE.md`, `docs/design-docs/`, `docs/decisions/`, and router/index link updates.
- **Item 2 complete:** just + Go runner spine landed: `justfile` (check/fmt/lint/nvim/test/vet), `selene.toml` + `lazyvim_extras.toml` (vim+lazyvim_extras std covering LazyVim/Snacks globals), `scripts/go.mod` + `scripts/tooling.go` + `scripts/tooling_test.go` (stdlib-only Go module at scripts/), `scripts/check-nvim.lua` (data-driven headless checker with 5-fixture table, Nix invariants, bounded LSP timeouts, graceful binary-absent skips). `docs/workflows.md` updated with quick-validation block.
- **Item 4 complete:** deterministic docs validation landed in `scripts/check-docs.go` with unit coverage in `scripts/check-docs_test.go`; `just docs` validates hand-authored docs coverage through `docs/index.md` or directory indexes, excludes `docs/generated/` and `docs/reviews/`, and checks local Markdown links while ignoring external URLs, `mailto:`, bare anchors, and `~` home paths.
- **Item 5 complete:** ast-grep guardrail infra landed under `guardrails/ast-grep/`, with `just guard` wired into `just check`; the first hygiene rule keeps LazyVim plugin disables in `lua/plugins/disabled.lua` with `enabled = false`.
- **Item 6 complete:** ADR-002 records the home-path literal policy; `lua/plugins/nix.lua` and `lua/plugins/picker.lua` now use `vim.fn.expand("~/...")`; ast-grep bans hardcoded `/Users/...` and `/home/...` Lua string literals with remediation pointing at ADR-002.
- **Item 7 complete:** Vale prose lane landed. `.vale.ini` is authoritative via `--no-global`; `just prose` owns file discovery over tracked hand-authored Markdown; explicit error pins for AI-tells and em-dashes are intentional. Prose-scope exclusions are generated/review output, legacy plans, fixtures, demos, and the `AGENTS.md` symlink.
- **Item 8 complete:** local hook gate landed. `.githooks/pre-commit` resolves the repo root and delegates directly to `just check`; `just install-hooks` sets local `core.hooksPath` to `.githooks`; `docs/workflows.md` covers fresh-clone setup. Optional `commit-msg` validation is deferred to TD-005 until this repo records its commit-message policy and the needed Vale `COMMIT_EDITMSG` mapping.
- **Item 9 complete:** nvim-lazy is wired as a doc-garden consumer with `guardrails/doc-history/policy.json`, `scripts/guardrails/doc-history-check.cjs`, and `docs/generated/doc-garden/.gitkeep`. The policy scopes only current-state Markdown surfaces, excludes generated/review/historical surfaces, and defines no repo-specific `forbidden_tokens` yet. The scanner intentionally returns zero regex findings while the policy has no tokens, and fails closed if future policy adds tokens before scanner support exists. Verification ran the deterministic Doc Garden audit plus RepoPrompt review; generated audit/review outputs are ignored under `docs/generated/doc-garden/`, so only the directory placeholder and local ignore rule are commit candidates.

## Background

### Source article: transferable themes (`docs/references/harness-engineering.md` once added; canonical copy at `/Users/mp/Projects/personal/ai/claude-toolkit/docs/references/harness-engineering.md`)
The article's load-bearing ideas, filtered to what a *config repo* can use:
1. **Map, not manual.** Short `AGENTS.md` (~100 lines) as a table of contents; deep knowledge in a structured `docs/`. Progressive disclosure. nvim-lazy already does this well.
2. **Mechanically enforce the knowledge base.** Linters and CI validate that docs are current, cross-linked, and structured; a recurring "doc-gardening" agent opens fix-up PRs for stale docs.
3. **Enforce invariants, not implementations.** Custom lints plus structural tests for "taste invariants" (naming, file-size, structured logging). Error messages inject remediation instructions into agent context.
4. **Agent legibility is the goal.** "What the agent cannot see in-context does not exist." Make app behavior (here: nvim health, LSP, plugin load) inspectable and assertable by the agent.
5. **Plans and tech-debt are first-class versioned artifacts.** `exec-plans/{active,completed}` plus a `tech-debt-tracker`.
6. **Golden principles plus garbage collection.** Opinionated mechanical rules plus recurring cleanup so agent-replicated drift is paid down continuously, not in bursts.

**Explicitly NOT transferable to this repo** (named so the plan does not cargo-cult): per-worktree app boot, full observability stack (Vector/Victoria/LogQL), Chrome DevTools runtime, layered ports-and-adapters domain architecture, minimal-merge-gate throughput philosophy, agent-to-agent PR review. These solve problems a personal config repo does not have.

### nvim-lazy current harness surface: "convention-first, enforcement-zero" (explore audit)
**Has (structure):**
- Router `CLAUDE.md` (~100-line cap, explicitly "a router, not a manual") plus `AGENTS.md` symlink. Cleaner than both sibling repos.
- `docs/`: `architecture.md`, `workflows.md`, `go.md`, `kotlin.md`, `nix.md`, `tooling-policy.md`, `index.md` (catalog), empty `reviews/` (design-agent output sink).
- `docs/index.md:7-14` placement rules including "Every doc here must be linked from this index"; `docs/workflows.md:32` says "verify referenced paths exist". Both are prose-only.
- `exec-plans/active/` (empty) plus `exec-plans/completed/` (3 plans, including `plugin-update-infra.md` which produced the test-fixtures harness).
- `test-fixtures/{go,kotlin,json,markdown,nix}`: minimal per-language scaffolds to trigger plugin chains; `test-fixtures/README.md:1-6`. Walked manually via the smoke checklist in `docs/workflows.md:57-68`.
- `stylua.toml` (indent 2 spaces, column 120); `ktlint.editorconfig` (Kotlin).
- `docs/workflows.md:70-102`: inline headless-nvim bash snippets (startup exit-0 check; tmux LSP-attach probe; nixd/statix/deadnix probe).
- Known absolute-path literals (the migration targets for Item 6): `lua/plugins/nix.lua:10` (dotfiles flake path), `lua/plugins/picker.lua:87-88` (two `vim.g.X or "/Users/mp/..."` overridable defaults).

**Missing (enforcement): the gaps this plan closes:**
- No `.github/`, no `.githooks/`/`.husky/`/`.pre-commit-config`, no `Makefile`/`justfile`, no scripts dir. Zero automation runner. (search: 0 matches)
- No Lua linter (no `selene.toml`/`.luacheckrc`); `stylua` is manual-only and is a formatter, not a linter.
- No doc-freshness/cross-link/structure validator; the "every doc linked" plus "paths exist" rules are unenforced.
- No committed runnable validation scripts; the workflows.md snippets are copy-paste prose with no exit-code aggregation, no single `check` entrypoint.
- No tech-debt tracker; decision history lives only in `exec-plans/`, with no standing "later" home. (MP's global CLAUDE.md mandates persisting deferrals to a tracker, so this gap directly bites.)

### Prior art: surf-cli (`/Users/mp/references/ai/surf-cli`)
- **Gap-analysis model worth copying for this plan's shape:** `docs/investigations/surf-cli-harness-engineering-gap-analysis.md` benchmarks across ~12 harness dimensions, marks each PRESENT/PARTIAL/ABSENT, then tiers fixes with reasoning.
- **guardrails/ shape:** each guardrail system is scanner plus JSON `policy.json` plus `baseline.json` plus README. `guardrails/ast-grep/rules/{boundaries,contracts,hygiene}/` (category dir plus `category:` key), with a test harness `guardrails/ast-grep/tests/core/*.yml` plus `__snapshots__/` and `sgconfig.yml` (`ruleDirs` plus `testConfigs`). Recommendation quoted: "every mechanical rule must carry a remediation hint that names (a) the owner module / correct path, (b) the reason." The `boundaries/` rules are the path-scoped-exclusion precedent for Item 6.
- **Runner:** `package.json` `guardrails` fan-out (`sg scan` plus `sg test` plus custom `.cjs` scanners); `check = vp check && pnpm guardrails`; `.vite-hooks/` pre-commit installs the gate. A separate `doc-prose-check.cjs` Vale lane and a commit-msg Vale hook (the precedent for Items 7 and 9).
- **docs/ subdirs:** `decisions/` (ADRs, no frontmatter, Context/Decision/Alternatives/Consequences), `design/`, `references/`, `investigations/`, `exec-plans/{active,completed,artifacts}`, `generated/doc-garden/`, top-level `tech-debt-tracker.md`.
- **CI:** `.github/workflows/ci.yml` with a `guardrails` job running the full fan-out plus installing Vale (`vale sync`).

### Prior art: claude-toolkit (`/Users/mp/Projects/personal/ai/claude-toolkit`)
- **Pre-commit hook IS the gate** (`.githooks/pre-commit` to `.husky/pre-commit`): runs staged check, tests, `sg scan` ast-grep guardrails, `verify:skills`. (Its own checks are TypeScript via bun; nvim-lazy instead uses Go for logic checks, see Approach, but the hook-as-gate shape is the precedent.)
- **ast-grep:** `guardrails/ast-grep/sgconfig.yml` plus `severity: error` rules carrying remediation strings; some use `kind: program` plus `regex` for path-scoped string checks.
- **doc-garden** (`packages/doc-garden/` plus skill): current-state doc audits are a deterministic regex+Vale floor, then a RepoPrompt review pass; writes to `docs/generated/doc-garden/`; runs against *consumer* repos gated on a per-repo `policy.json` (typically `guardrails/doc-history/policy.json`). MP owns this skill; nvim-lazy becomes a consumer.
- **automations/codex/:** scheduled-automation specs (`automation.toml` with `rrule`, `prompt`, `status=PAUSED`), the recurring-cleanup substitute. Principle: TOML is the reasoning/cadence layer, skill is the execution layer.
- **ADR shape:** `docs/decisions/NNN-*.md` numbered plus `template.md` plus `index.md` link registry.
- **design-docs:** `docs/design-docs/` holds end-to-end system flows and `index.md` plus `core-beliefs.md` (the precedent for Item 3 and the core-beliefs doc).
- **tech-debt-tracker:** `docs/exec-plans/tech-debt-tracker.md`, a durable home for deferred work; deferrals added at plan-write time, one subsection per item.

### Tool provisioning (cross-cutting dependency)
nvim-lazy has no `package.json`/pnpm; checks are invoked via `just`. The new tools (`selene`, `ast-grep`/`sg`, `vale`) must be provisioned the same way `stylua`/`nixd`/`nixfmt`/`statix`/`deadnix` already are: via MP's Nix Home-Manager modules in the **dotfiles** repo (`dotfiles/nix/home/mp/modules/neovim.nix`, `nix-ops-tools.nix`). `go` is almost certainly already provisioned (the repo targets Go via `test-fixtures/go`, gopls, and neotest-go). This is a cross-repo prerequisite for the lint/guardrail/prose/doc-garden items, and CI must install the same tools.

## Approach

Add a **full mechanical-enforcement harness**, sharing one runner across a local hook and a CI backstop. Decisions locked with MP:

- **`justfile` as the runner.** One `just check` aggregates all gates; per-domain recipes (`just fmt`, `just lint`, `just docs`, `just guard`, `just prose`, `just nvim`, `just test`, `just vet`) stay independently runnable. Thin tool-wrappers are inline recipes (for example `just fmt` runs `stylua --check` directly); only logic-heavy checks get their own files.
- **Go for logic checks.** Checks with real parsing logic (the doc validator) are Go, with `go test` unit tests, `gofmt` formatting, and `go vet` linting, all folded into `just check`. The harness tests its own tooling. Footprint is minimal by construction: a stdlib-only validator needs only a `go.mod` (no `node_modules`, no lockfile; fmt, lint, and test all live in the toolchain). Go was chosen over TS+bun precisely because it erases the npm-project footprint for a repo that is not primarily TypeScript, and `go` is already in the repo's world (test-fixtures, gopls).
- **One gate, two triggers.** `.githooks/pre-commit` delegates to `just check` (the full gate: format, Lua lint, doc validation, ast-grep guard, Vale prose, `go test`/`go vet`, and headless nvim). `.github/workflows/ci.yml` shares the same recipe definitions but runs an explicit deterministic subset via `just ci` (`fmt lint docs guard prose test vet`), omitting `just nvim` until headless nvim is stable in CI; the workflow calls `just ci` so the subset declaration lives in the justfile, not duplicated in the YAML. The no-drift guarantee is structural — both surfaces use the same named `just` recipes — not behavioral. The pre-commit hook runs the full gate (MP's call: accepts the per-commit cost for complete local validation).
- **CI is a confirmed backstop.** Local hook catches issues first; CI runs a deterministic subset on push so a skipped local hook cannot hide drift. CI provisions the same tools. MP affirmed CI as best-practice regardless of repo size.
- **Remediation-first failures.** Every check prints text naming what to fix and where, plus the reason (the surf-cli principle), so the message injects the fix into agent context.
- **Graceful degradation is a contract.** Per `docs/design-docs/tooling-policy.md`, a missing *optional* language binary is a skip, not a failure; only config-load errors and present-but-broken tooling fail.
- **Guardrails enforce invariants, not taste, and only when a sanctioned pattern exists.** A mechanical ban ships only alongside its solution and a migration of existing violations (Item 6 is the worked example).

**Sequencing rationale:** stand up the tracker and core-beliefs (durable homes), then the `just` plus Go runner spine, then restructure docs into `design-docs/` and `decisions/` so later docs land in the final shape, then the doc validator over that shape, then guardrails, then the absolute-paths invariant (which needs both the ast-grep infra and the decisions dir), then the prose lane and its one-pass cleanup, then wire the hook, then doc-garden, then CI, and finish by adding the reference article and re-pointing the workflow docs.

**Out of scope (rejected, not deferred):** per-worktree app boot, observability stacks (Vector/Victoria/LogQL/PromQL), Chrome DevTools runtime, layered ports-and-adapters architecture, agent-to-agent PR review, minimal-merge-gate philosophy.

## Work Items

### Item 0: Provision the toolchain (cross-repo prerequisite)
**Goal:** Make `selene`, `ast-grep` (`sg`), `vale`, and `go` available before any item that calls them, the same way `stylua`/`statix`/`deadnix` already are.
**What it does:** Add the tools to MP's Nix Home-Manager modules in the **dotfiles** repo (`dotfiles/nix/home/mp/modules/nix-ops-tools.nix` or a sibling), rebuild/activate, confirm each is on PATH. `go` is almost certainly already provisioned (the repo targets Go via `test-fixtures/go`, gopls, and neotest-go); just confirm it. The Go validator is stdlib-only, so there are no external Go deps to manage. `vale` is also already globally provisioned (`dotfiles/nix/home/mp/modules/vale.nix`, with the `ai-tells` package), so for `vale` and `go` this is a confirm, not an add; only `selene` and `ast-grep` are genuinely new. Cross-repo change and a hard blocker for Items 2, 4, 5, 6, 7, 9.
**Done when:** `selene`, `sg`, `vale`, and `go` are on PATH via an activated Nix profile.
**Key files (cross-repo):** `dotfiles/nix/home/mp/modules/*.nix`
**Dependencies:** None.
**Size:** Small.

### Item 1: Seed the tech-debt tracker plus core-beliefs doc plus doc taxonomy
**Goal:** Stand up the durable "later" home and the operating-principles doc before implementation leans on them. (Closes a standing gap: MP's global convention mandates a tracker for deferrals; the repo has none.)
**What it does:** New `exec-plans/tech-debt-tracker.md` (claude-toolkit style: one subsection per item, deferrals added at plan-write time). Seed: **TD-001** interactive tmux/visual smoke harness (headless first; automate visual checks only if headless misses a plugin-update regression); **TD-002** ast-grep rule-catalog growth plus the `sg test`/`__snapshots__` harness (start with a flat scan; add the snapshot apparatus when the catalog grows beyond a couple of rules); **TD-003** Knip dead-code analysis (declined: Knip only analyzes JS/TS, but this repo is Lua plus a tiny Go tooling layer with no JS/TS; Selene covers Lua unused-bindings, `go vet`/the compiler cover the Go side, and LazyVim auto-loads every `lua/plugins/` file so there are no orphan modules. Trigger: only if a JS/TS layer is ever introduced). Also add `core-beliefs.md` (this is a config repo not a product; one check command over scattered snippets; docs are maps not duplicated code; mechanical rules carry remediation and ship only with a sanctioned pattern; optional tools degrade gracefully; no runtime/CI machinery beyond this harness unless scale changes). It lands at `docs/design-docs/core-beliefs.md` after the Item 3 restructure (or move it there as part of Item 3). Add a short **doc taxonomy** to `docs/index.md` mapping harness-engineering doc concepts to where they live here: root `ARCHITECTURE.md` is the top-level map (separate from design docs, per the article), `docs/design-docs/` is per-area design/policy plus core-beliefs, `decisions/` is ADRs, `references/` is external distillations, `exec-plans/` is plans plus tech-debt.
**Done when:** `exec-plans/tech-debt-tracker.md` (seeded TD-001 to TD-003) and the core-beliefs doc exist; the doc-taxonomy note is in `docs/index.md`; both linked.
**Key files:** `exec-plans/tech-debt-tracker.md`, `docs/design-docs/core-beliefs.md`, `docs/index.md`, `CLAUDE.md`
**Dependencies:** None (core-beliefs final location coordinates with Item 3).
**Size:** Small.

### Item 2: Add the `just` plus Go runner with format/lint/nvim recipes
**Goal:** Give agents and humans a single local command for validation, the spine everything wires into.
**What it does:** `justfile` exposing `check` (full aggregate, fail-fast) plus `fmt`, `lint`, `nvim`, `test`, `vet` (and `docs`, `guard`, `prose` as later items add them). Thin wrappers are inline recipes: `just fmt` runs `stylua --check` over `init.lua` plus `lua/**/*.lua` using `stylua.toml` (plus `gofmt -l` over the Go tooling); missing `stylua` fails with remediation (activate the Nix profile, confirm on PATH, do not Mason-install). `just lint` runs `selene` over `init.lua` plus `lua/**` using a `selene.toml` whose Neovim standard-library definition must cover all injected globals (`vim`, `LazyVim`, `Snacks`, and so on), not just `vim`, or it false-positives across the tree; std tuning is expected here. `scripts/check-nvim.lua` (driven by `just nvim` via `nvim --headless`) asserts config loads cleanly plus each `test-fixtures/` file opens with the expected filetype, and applies the Nix invariants from `lua/plugins/nix.lua` (nvim-lint has statix plus deadnix for nix; nil_ls inactive; nixd expected only when its binary is executable). Drive it from a data-driven fixture table, one entry per fixture: `{ path, filetype, optional_lsp = { client, binary }, extra_assertions }`. Optional LSP attach is bounded by an explicit per-fixture timeout (~8s) and skips gracefully when the binary is absent. This is the committed, exit-code-aggregating replacement for the inline snippets at `docs/workflows.md:70-102`. **Tooling substrate (decided with MP):** logic-heavy checks (the doc validator, Item 4) are written in **Go**, chosen over TS+bun because Go's toolchain bundles formatter (`gofmt`), linter (`go vet`), and test runner (`go test`) with zero external deps, which suits a repo that is not primarily TypeScript. Add a `go.mod` (stdlib-only, so no `go.sum`, no vendored deps, no `node_modules`) plus `just test` (`go test ./...`) and `just vet` (`go vet ./...`) recipes folded into `just check`; `gofmt -l` joins the format lane and fails on unformatted Go. The validator and its `_test.go` are strict and tested by construction. The rejected TS+bun (and vite-plus/vitest) alternative and its reasoning are in the Considered-not-adopted list and ADR-001.
**Done when:** `just check` runs the aggregate (including `just lint`, `just test`, `just vet`); `just fmt`/`just lint`/`just nvim` run independently; `just fmt` enforces stylua plus `gofmt`; `just lint` runs Selene with a tuned neovim std; `just nvim` does startup plus per-fixture filetype assertions with graceful skips; a trivial `go test` passes to prove the Go substrate works.
**Key files:** `justfile`, `go.mod`, `selene.toml` (plus neovim std file), `scripts/check-nvim.lua`, `stylua.toml`, `test-fixtures/**`, `docs/design-docs/tooling-policy.md`
**Dependencies:** Item 1; Item 0 (go, selene).
**Size:** Medium.

### Item 3: Promote `ARCHITECTURE.md` to root, restructure docs into `design-docs/` plus `decisions/`
**Goal:** Match the article's layout (a top-level `ARCHITECTURE.md` map, separate from `docs/design-docs/`) and group the remaining design/policy docs so `docs/` scales by category instead of accumulating flat.
**What it does:** (1) Move `docs/architecture.md` to a repo-root **`ARCHITECTURE.md`** (matklad/article convention: the high-level map of load chain, ownership, and customization clusters lives at root beside `CLAUDE.md`/`AGENTS.md`, NOT inside design-docs). (2) Create `docs/design-docs/` with `index.md` plus `core-beliefs.md`, and move the per-area design/policy docs into it: `tooling-policy.md`, `go.md`, `kotlin.md`, `nix.md`. (`workflows.md` is operational; lean toward keeping it at `docs/` root as a runbook. The exact per-file split is an adjustable call.) (3) Create `docs/decisions/` with `template.md` (claude-toolkit/surf-cli shape: no frontmatter, bold status/date, Context/Decision/Alternatives/Consequences), `index.md` link registry, and **ADR-001 seeded from this plan** (the harness enforcement substrate: justfile plus Go, the Go tooling choice [Go's built-in `gofmt`/`go vet`/`go test` over TS+bun/vite-plus/vitest, with reasoning], full-gate hook, CI, remediation-first guardrails, and the rejected product-scale alternatives). Update every inbound link: the `CLAUDE.md` "Where to read" table and `docs/index.md` catalog plus taxonomy. `docs/reviews/` and `docs/generated/` stay where they are.
**Done when:** `ARCHITECTURE.md` is at repo root; per-area docs live under `docs/design-docs/` with an `index.md` plus `core-beliefs.md`; `docs/decisions/{template.md,index.md,001-*.md}` exist; all links in `docs/index.md` and `CLAUDE.md` resolve to the new paths; nothing references the old `docs/architecture.md` path.
**Key files:** `ARCHITECTURE.md`, `docs/design-docs/*`, `docs/decisions/*`, `docs/index.md`, `CLAUDE.md`
**Dependencies:** Item 1 (taxonomy).
**Size:** Medium.

### Item 4: Add deterministic docs validation
**Goal:** Mechanically enforce the currently prose-only `docs/index.md` rules over the final doc structure.
**What it does:** `scripts/check-docs.go` (Go, with a `check-docs_test.go` beside it) enforces for v1: (a) every hand-authored doc under `docs/**` except `index.md` is linked from `docs/index.md` (or a dir-level `index.md`), excluding machine/agent-output dirs `docs/generated/` and `docs/reviews/` (not hand-authored, must not be index-linked); (b) local Markdown links in `docs/**/*.md` resolve to existing files (ignoring external URLs, `mailto:`, bare anchors, `~` home paths). Deliberately not parsing every inline backtick path (fragile prose-parsing, false positives). Failures point at the offending file with a fix. Wire `just docs` into `just check`.
**Done when:** `scripts/check-docs.go` validates index coverage (recursive over `design-docs/`, `decisions/`, `references/`, with `generated/` plus `reviews/` excluded) plus local links, is in `just check`, emits remediation on failure, and has `go test` unit tests covering coverage plus link-resolution plus the exclusions.
**Key files:** `scripts/check-docs.go`, `scripts/check-docs_test.go`, `go.mod`, `justfile`, `docs/index.md`
**Dependencies:** Item 2 (runner plus Go), Item 3 (validates the final doc shape).
**Size:** Medium.

### Item 5: Add ast-grep structural guardrails (infra plus first rule)
**Goal:** Stand up the ast-grep guardrail infra and the one rule that is a clean Lua AST invariant.
**What it does:** `guardrails/ast-grep/sgconfig.yml` (`ruleDirs: [rules]`) plus `rules/hygiene/` (the relevant category for a flat config repo; `boundaries`/`contracts` are product concepts, omit except for the path-scoped pattern reused in Item 6). First rule: **LazyVim disables only via `lua/plugins/disabled.lua` with `enabled = false`** (per CLAUDE.md), which is path-scoped and a good ast-grep fit. The rule carries a `category:` key plus remediation naming the owner path plus reason. The plugin-spec-location idea is **declined as an ast-grep rule**: specs are plain `{ "owner/repo" }` tables with no syntactic marker, so it would be a false-positive-prone heuristic; skip it or revisit as a path/shell check under TD-002. Keep the apparatus lean for 1 to 3 rules: a flat `sg scan` is enough now; the `sg test` plus `__snapshots__/` harness is deferred to TD-002. Wire `just guard` (`sg scan`) into `just check`.
**Done when:** `sgconfig.yml` plus the disabled.lua rule with remediation exist and pass on a clean tree; `just guard` runs `sg scan` and is part of `just check`.
**Key files:** `guardrails/ast-grep/sgconfig.yml`, `guardrails/ast-grep/rules/hygiene/*.yml`, `justfile`
**Dependencies:** Items 2 and 0. (Independent of Items 3 and 4.)
**Size:** Medium.

### Item 6: Migrate hardcoded home paths to `~`-expansion, then add the rule
**Goal:** Remove the brittle part of the existing absolute paths (the `/Users/mp` home prefix, which breaks across users/machines/OS) and add a rule that stays green, so the ban ships with its solution rather than bouncing the issue back to the maintainer.
**What it does:** The problem is the hardcoded home prefix, not the repo path: all three current literals point at *external* dirs under `$HOME` (`nix.lua:10` dotfiles flake; `picker.lua:87-88` the two `vim.g.X or "/Users/mp/..."` defaults), so `~`-expansion is the fix. Three parts, in order. (1) **ADR-002 in `docs/decisions/`** records the decision: never hardcode the home prefix; use `vim.fn.expand("~/...")` / `vim.env.HOME`. As a noted escape hatch (not built now), a genuinely non-`~` machine-specific value would go in one sanctioned `lua/config/paths.lua` module; create it only if such a value appears. (2) **Migrate the three violations** to `vim.fn.expand("~/...")` (the picker sites keep their `vim.g.X or ...` override shape; the `m5-mbp` hostname in `nix.lua:11` is not a path, out of scope). (3) **Add the ast-grep rule** banning `/Users/`, `/home/`, and absolute-home literals in `lua/**`. Because the violations are migrated, the rule passes on a clean tree with no baseline. If the optional paths module ever exists, path-exclude it (the surf-cli `boundaries/` pattern). Add `sg test` cases if the snapshot harness exists by then (else under TD-002).
**Done when:** ADR-002 exists; `nix.lua` and `picker.lua` use `~`-expansion with no `/Users/` literals remaining; the rule passes on a clean tree and fails on a newly introduced hardcoded home path with remediation pointing at the ADR; `just check` stays green; the picker commands and the flake path still resolve after migration.
**Key files:** `docs/decisions/002-absolute-paths.md`, `lua/plugins/nix.lua`, `lua/plugins/picker.lua`, `guardrails/ast-grep/rules/hygiene/no-hardcoded-home-path.yml` (`lua/config/paths.lua` only if a non-`~` value appears)
**Dependencies:** Item 5 (ast-grep infra), Item 3 (decisions dir).
**Size:** Small-Medium.

### Item 7: Add the Vale AI-tells prose lane plus one-pass cleanup
**Status:** Complete; this as-built contract supersedes the original global-config layering plan.
**Goal:** Mechanically catch AI-tells and em-dashes in tracked hand-authored Markdown.
**What it does:** `.vale.ini` is authoritative because `just prose` invokes Vale with `--no-global`. `just prose` owns file discovery with `git ls-files -z -- '*.md'` and exact exclusions for generated/review output, legacy plans, fixtures, demos, and the `AGENTS.md` symlink. Explicit `error` pins for `EmDashUsage`, `OverusedVocabulary`, and `OverusedVocabularyVerbs` are intentional so upstream default severity drift cannot weaken the gate.
**Done when:** `just prose` runs in `just check`, scans tracked hand-authored Markdown, and passes after the one-pass cleanup.
**Key files:** `justfile`, `.vale.ini`, `docs/**`
**Dependencies:** Item 2 (runner), Item 3 (final doc paths). Cross-repo E-Prime coordination is bypassed by `--no-global`.
**Size:** Small-Medium.

### Item 8: Add the pre-commit hook gate (full)
**Status:** Complete; commit-message validation is out of scope and deferred to TD-005.
**Goal:** Make the full local gate automatic at commit time.
**What it does:** `.githooks/pre-commit` resolves repo root and delegates to `just check` with no independent logic (cannot drift from manual). A `just install-hooks` recipe validates that `.githooks/pre-commit` exists and is executable, then runs `git config --local core.hooksPath .githooks` and prints confirmation. Per MP's decision the hook runs the full gate (format, lint, docs, guard, prose, test/vet, headless nvim). Commit-message validation is not part of Item 8; TD-005 tracks a future `commit-msg` hook once this repo records its commit-message policy and Vale `COMMIT_EDITMSG` mapping. `docs/workflows.md` documents that fresh clones run `just install-hooks`.
**Done when:** `.githooks/pre-commit` delegates to `just check`; `just install-hooks` sets `core.hooksPath`; workflow doc covers setup.
**Key files:** `.githooks/pre-commit`, `justfile`, `docs/workflows.md`
**Dependencies:** Items 2 to 7 (the checks it gates).
**Size:** Small.

### Item 9: Wire nvim-lazy as a doc-garden consumer
**Goal:** Add the recurring agent-driven doc-currency mechanism (the article's "doc-gardening agent") on top of the deterministic validator and prose lane.
**What it does:** Add the consumer-side artifacts the `doc-garden` skill expects: `guardrails/doc-history/policy.json` with current-state doc scope, a scanner bridge, the shared Vale config from Item 7, and a visible `docs/generated/doc-garden/` artifact directory. For nvim-lazy, Doc Garden currently relies on Vale plus the required RepoPrompt review layer; the scanner bridge emits no regex findings while policy has no `forbidden_tokens`, and fails closed if future regex rules are added before scanner support exists. Recurring *scheduling* (claude-toolkit `automations/codex/`) stays cross-repo and is invoked manually for now. **Refactor coordination:** the `doc-garden` skill is mid-refactor (see `dotfiles/.plans/vale-config-improvements.md`, which moves Vale vocab/E-Prime into the doc-garden flow and its canonical `vale-config-template.ini`). Confirm the consumer contract (the `policy.json` shape and how Vale is wired) against the **post-refactor** skill before building, and reference the canonical template rather than copying it. This makes Item 9 the most refactor-sensitive item; sequence it after the doc-garden refactor settles.
**Design-critique note (retained per MP):** the deterministic validator (Item 4) plus prose lane (Item 7) already cover linkage, link-resolution, and AI-tells, so doc-garden is the heavier layer; kept per MP's Phase-5 decision for the agent-driven review pass.
**Done when:** `/doc-garden audit` runs against nvim-lazy via its `policy.json` plus Vale config and writes an audit under `docs/generated/doc-garden/`.
**Key files:** `guardrails/doc-history/policy.json`, `docs/generated/doc-garden/` (output), `docs/index.md`; cross-repo: claude-toolkit doc-garden skill
**Dependencies:** Items 4 and 7 (deterministic floor plus Vale), Item 0 (`vale`); cross-repo: the doc-garden refactor and global Vale changes (`dotfiles/.plans/vale-config-improvements.md`).
**Size:** Medium.

### Item 10: Add the GitHub Actions CI backstop
**Goal:** Re-run the gate on push so a skipped local hook cannot hide drift. **Decided: kept; MP confirms CI is best-practice regardless of repo size.**
**Status:** Complete.
**What it does:** `.github/workflows/ci.yml` provisions the toolchain (direct installs of stylua/selene/ast-grep/vale/go) and delegates to `just ci` (`fmt lint docs guard prose test vet`), omitting `just nvim` (decision in ADR-001). `just ci` is the authoritative subset declaration; the workflow file just calls it.
**Done when:** `.github/workflows/ci.yml` runs on push/PR, provisions tools, and executes the deterministic subset (`fmt`, `lint`, `docs`, `guard`, `prose`, `test`, `vet`) green on a clean tree.
**Key files:** `.github/workflows/ci.yml`, `justfile`
**Dependencies:** Items 2 to 7 plus Item 0 (CI installs the same tools independently).
**Size:** Medium.

### Item 11: Add the harness-engineering reference plus finalize docs
**Status:** Complete.
**Prose exclusion decision (persisted here):** Verbatim external payload files in `docs/references/` are excluded from `just prose` (Vale) by explicit per-file entries in the `justfile` prose recipe. Currently excluded: `docs/references/harness-engineering.md`. Adding a new payload requires a matching targeted exclusion in the `justfile`; the directory is not blanket-excluded. `docs/references/index.md` and any framing prose are hand-authored and prose-checked as normal. `just docs` (index coverage + link validation) still applies to all files in `docs/references/`.
**Goal:** Add cheap agent-legibility docs and re-point the workflow docs at the new gate.
**What it does:** `docs/references/harness-engineering.md`, a local copy of the article (from `claude-toolkit/docs/references/harness-engineering.md`) with the "external reference" framing (this is the file the original task pointed at, which does not yet exist). `docs/workflows.md` leads with `just check` as the default validation command and demotes the inline tmux/headless snippets to a manual/debugging deep-dive section (the plugin-update smoke checklist stays). `CLAUDE.md` gets router links only (core-beliefs, `just check` workflow, tracker, design-docs/, decisions/) and must not grow into a manual. Update this active plan with resolved decisions. All new docs must pass `just docs` plus `just prose`.
**Done when:** the article copy exists and is linked; `docs/workflows.md` leads with `just check`; `CLAUDE.md` references the new surfaces without expanding into reference content; `just check` passes with all new docs present.
**Key files:** `docs/references/harness-engineering.md`, `docs/workflows.md`, `docs/index.md`, `CLAUDE.md`, `exec-plans/active/harness-engineering-adoption-2026-05-27.md`
**Dependencies:** Items 3, 4, 7, 9, 10 (new docs/dirs must satisfy the validator and be indexed; finalizes the CI decision).
**Size:** Medium.

## Verification

Task-specific checks the implementer runs before declaring done (beyond "it runs"):
1. **Positive full gate:** `just check` from a clean shell runs format, lint, docs, guard, prose, `go test`/`go vet`, and nvim, and exits `0`.
2. **Docs negative test:** add a temporary unlinked `docs/*.md` and a broken relative link; confirm `just docs` fails with remediation pointing at the offending file; remove them; confirm pass.
3. **Absolute-path negative test (Item 6):** after migration, add a temporary `/Users/...` literal in a `lua/` file; confirm `just guard` fails with remediation pointing at the ADR/pattern; confirm a `vim.fn.expand("~/...")` equivalent passes. If `lua/config/paths.lua` is introduced later for non-`~` machine-specific paths, add and test the explicit exemption then.
4. **Hook parity test:** run `.githooks/pre-commit` directly with staged Lua/doc changes; confirm it produces the same failure text as `just check`.
5. **Graceful-degradation test:** run `just nvim` with an optional binary (for example `gopls`) absent from PATH; confirm a skip per `tooling-policy.md` while a genuine config-load error still fails.
6. **CI parity:** the CI job's chosen gate passes on a clean tree and fails on the same negative tests as local (at least docs plus guard).
7. **Tooling self-test:** `go test` covers the doc validator's branches (orphan doc, broken link, excluded dir); `gofmt -l` and `go vet` are clean. Prove the prose lane by adding an em-dash/AI-tell to a doc and confirming `just prose` flags it.
8. **Link-integrity after restructure (Item 3):** grep the repo for references to the old `docs/<topic>.md` paths; confirm none remain and that `just docs` passes on the moved tree.

## Risks and Mitigations
- **Cross-repo tool provisioning** (selene/ast-grep/vale/go live in dotfiles Nix): the lint/guard/prose/doc-garden items are blocked until provisioned. Provision early (Item 0); CI installs the same tools independently.
- **Docs restructure breaks links** (Item 3): many inbound links in `index.md` and `CLAUDE.md`. Mitigation: the doc validator (Item 4) plus Verification #8 catch any missed reference; do the move before later doc items land.
- **Absolute-path migration changes runtime behavior** (Item 6): `vim.fn.expand` must resolve identically. Mitigation: verify the picker commands and the nix flake path still resolve after migration.
- **Hook is local state:** fresh clones do not gate until `just install-hooks` runs. Document in `docs/workflows.md`; the CI backstop covers the gap.
- **Full gate in pre-commit is slow** (headless nvim per commit): MP accepted this for no-drift confidence. Keep `just nvim` headless plus timeout-bounded; per-domain recipes let agents run a fast subset while iterating.
- **Headless nvim in CI is bootstrap-heavy:** CI deliberately omits `just nvim` (decision in ADR-001); a cached lazy.nvim bootstrap is the follow-up if `nvim` is later added to the CI subset.
- **Selene false-positives on Neovim globals:** the std must cover all injected globals (`vim`, `LazyVim`, `Snacks`, and so on), not just `vim`. Tune `selene.toml` plus the neovim std up front.
- **Vale and doc-garden are mid-refactor cross-repo** (`dotfiles/.plans/vale-config-improvements.md`): Item 7's prose lane and one-pass cleanup must land after the global E-Prime-off plus vocab change (else noise drowns the AI-tells signal), and Item 9's consumer contract must be confirmed against the post-refactor doc-garden skill. Mitigation: sequence Items 7 and 9 after that work; cross-repo tool terms (`ast-grep`/`sg`, `just`, `gofmt`) go to the global named vocab (dotfiles), and nvim-lazy-specific Lua terms (`selene`, `stylua`) go in nvim-lazy's repo-local vocab.

## Considered from the reference repos, not adopted (with why)
- **Knip dead-code analysis:** declined; tracked TD-003. Knip only analyzes JS/TS, but the repo is Lua with a near-zero TS tooling layer; Selene plus LazyVim's auto-loader already cover the real dead-code surface.
- **Secret scanning (gitleaks):** skipped; a Neovim config holds no secrets (the hardcoded paths are not secrets). Revisit only if that changes.
- **Quality-score doc grading domains:** skipped; the article's per-domain quality grades assume many product domains, which a flat config repo lacks.
- **File-size / structured-logging "taste" lints:** skipped for now; low yield on a small Lua tree. A file-size hygiene check could be a future ast-grep/shell rule (folds under TD-002) if a `lua/plugins/*.lua` bloats.
- **Hermetic install-shape CI job** (surf-cli): not applicable; nothing is packaged or published here.
- **ast-grep `sg test` plus `__snapshots__` harness:** deferred to TD-002; the full apparatus is sized for surf-cli's dozens of rules, not this repo's 1 to 3.
- **TS + bun (and vite-plus/vitest) for the logic checks:** considered and not adopted. Right for claude-toolkit's TS monorepo, but they impose an npm-project footprint (`package.json`, `node_modules`, lockfile) on a repo that is not primarily TypeScript. Go was chosen instead: `gofmt`/`go vet`/`go test` are built in with zero external deps. Recorded in ADR-001.

## Open Questions
- **Selene std strictness and provenance:** a community neovim selene std versus a hand-rolled one, and which globals to include. Tactical; resolve when wiring `selene.toml`.
- **Vale style strictness:** which AI-tell/em-dash rules error versus warn, and whether to reuse MP's existing Vale styles from dotfiles/claude-toolkit or keep a nvim-lazy-local config. Tactical; decide at implementation.
- **`workflows.md` placement:** move into `design-docs/` (design) or keep at `docs/` root (operational runbook). Lean: keep at root as a runbook; confirm during Item 3.
- **Go module location:** resolved — `scripts/go.mod`. Keeps root clean; separates harness tooling from `test-fixtures/go/`. Recorded in ADR-001.

## References
- Article: <https://openai.com/index/harness-engineering/> (local copy: `/Users/mp/Projects/personal/ai/claude-toolkit/docs/references/harness-engineering.md`)
- surf-cli gap analysis: `/Users/mp/references/ai/surf-cli/docs/investigations/surf-cli-harness-engineering-gap-analysis.md`
- surf-cli guardrails/CI: `/Users/mp/references/ai/surf-cli/guardrails/`, `.github/workflows/ci.yml`
- claude-toolkit hooks/guardrails/ADRs/design-docs/doc-garden: `/Users/mp/Projects/personal/ai/claude-toolkit/.githooks/pre-commit`, `guardrails/ast-grep/`, `docs/decisions/`, `docs/design-docs/`, `packages/{toolkit-lint,doc-garden}/`, `automations/codex/`
- nvim-lazy current: `CLAUDE.md`, `docs/index.md`, `docs/workflows.md`, `exec-plans/completed/plugin-update-infra.md`, `test-fixtures/README.md`, `lua/plugins/nix.lua:10`, `lua/plugins/picker.lua:87-88`
- Tool provisioning precedent: `dotfiles/nix/home/mp/modules/neovim.nix`, `nix-ops-tools.nix`
- In-flight Vale/doc-garden refactor (coordination): `/Users/mp/Projects/personal/dotfiles/.plans/vale-config-improvements.md`; global Vale config `dotfiles/nix/home/mp/modules/vale.nix`; canonical template `claude-toolkit/.claude/skills/doc-garden/references/vale-config-template.ini`
