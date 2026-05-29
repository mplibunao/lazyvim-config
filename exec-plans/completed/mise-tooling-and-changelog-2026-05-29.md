# Completion note

Completed on 2026-05-30 after Item 6 validation. The migration now uses `mise.toml`/`mise.lock` for local harness pins, `jdx/mise-action` for CI provisioning, and local docs/ADR/changelog updates for operator guidance. Local validation evidence from the orchestrator run: `just ci` and `just check` passed under a mise-first PATH. CI evidence: PR #3 was green in workflow job `Gate (just ci)`, run/job URL <https://github.com/mplibunao/lazyvim-config/actions/runs/26651770519/job/78551711321>. This plan was archived from `exec-plans/active/` to `exec-plans/completed/`.

# Migrate harness tooling to mise + add CHANGELOG.md: Plan

> Plan location note: rp-deep-plan defaults to `docs/plans/`, but this repo's
> `CLAUDE.md:23` makes `exec-plans/active/` the home for in-progress plans. Repo
> convention wins (matches `exec-plans/completed/*`).

## Goal

Close **TD-008** by moving nvim-lazy's harness toolchain (stylua, selene, vale,
ast-grep, go, just) to **mise** so versions are (1) isolated from the global Nix
profile and from other repos, (2) provisioned in CI by one step instead of
per-tool curl/npm blocks, and (3) identical between local and CI from a single
pinned source. Separately, add a root **`CHANGELOG.md`** modeled on
claude-toolkit's format.

## Background

_Curated from 8 explore probes (2026-05-29). Load-bearing evidence with refs._

### TD-008 (the driver)
`exec-plans/tech-debt-tracker.md:61-80`. Status: **Deferred**. CI installs
`selene, stylua, ast-grep, vale, go` via per-tool curl/install blocks; local
versions come from Nix. Version "truth" is duplicated (Nix module vs CI YAML) →
drift bugs (the `41ccc8d` selene install-permissions fix was a symptom).
Recorded split heuristic: **mise** owns tools whose exact version determines a CI
gate's behavior; **Nix** owns machine-baseline tools (`just`, `gh`, shell,
editors). Edge case: Vale + ast-grep are also used cross-repo (doc-garden, ad-hoc
search) so they stay globally available via Nix *and* pinned per-repo via mise
(mise shims win inside the repo). Triggers: 6th CI tool, a local/CI mismatch, or
a Nix bump that desyncs CI. **NOTE:** the user's task brief explicitly wants
`just` isolated too ("if nix's just... does a breaking change, we're not required
to migrate") — this *extends* TD-008's heuristic, which had parked `just` in Nix.
Resolved: `just` is pinned in mise for repo isolation, with Nix remaining a bootstrap fallback.

### Tool inventory + current sourcing (`justfile`)
Master list of binaries each recipe needs:
- `fmt` (`justfile:38-53`): **stylua** (`--config-path stylua.toml --check`), **gofmt**
- `lint` (`justfile:55-57`): **selene** (`--config selene.toml`)
- `docs`/`test`/`vet` (`justfile:59-98`): **go** (`go run .`, `go test ./...`, `go vet ./...`)
- `guard` (`justfile:63-65`): **sg** (ast-grep) `sg scan --config guardrails/ast-grep/sgconfig.yml`
- `prose` (`justfile:72-85`, deps `setup-vale`): **vale** `--no-global --config .vale.ini --minAlertLevel=error`
- `nvim` (`justfile:87-90`): **nvim** headless — **local-only, excluded from `just ci`**
- aggregates: `check = fmt lint docs guard prose test vet nvim` (`justfile:18`); `ci = fmt lint docs guard prose test vet` (`justfile:23`)
- `git`, `sh` are universal (no pinning needed).
Current provisioning: **all from global PATH (Nix Home Manager)** — justfile
header `justfile:14-16` says "Harness gate tools come from Nix Home Manager… If
selene, stylua, vale, or just are absent, activate your Nix profile first." **No
repo-local pins exist**: no `.tool-versions`, no `mise.toml`, no `flake.nix`.
`selene.toml`/`stylua.toml` carry style options only; `scripts/go.mod:7` has
`go 1.22` as a language floor, not a toolchain pin.

### CI today (`.github/workflows/ci.yml`)
Single job `gate` on `ubuntu-latest` runs `just ci` (`ci.yml:90`). Provisioning:
- Pins in `env:` block (`ci.yml:11-14`): `STYLUA_VERSION 0.20.0`, `SELENE_VERSION 0.27.1`, `VALE_VERSION 3.14.1`, `SG_VERSION 0.36.0`.
- Go: `actions/setup-go@v5` from `go-version-file: scripts/go.mod`, `cache:false` (`ci.yml:24-29`).
- just: `extractions/setup-just@v2` (`ci.yml:31-32`, unpinned).
- stylua/selene/vale: curl GitHub release → unzip/tar → `sudo mv` / `sudo install -m 755` (`ci.yml:36-64`).
- ast-grep: `npm install -g @ast-grep/cli@${SG_VERSION}` (`ci.yml:53-55`).
- **Vale style-package cache** (`actions/cache@v4`, `ci.yml:66-84`): caches `styles/{ai-tells,write-good,alex}` + `styles/.vale-config-hash`; key `vale-styles-${VALE_VERSION}-${hashFiles('.vale.ini','scripts/setup-vale.sh','styles/config/vocabularies/**')}`; **excludes** `styles/config/vocabularies/` (tracked). This step is independent of binary provisioning and **stays**.
mise is **not** referenced anywhere today.
Hooks: `.githooks/pre-commit` → `just check`; `.githooks/commit-msg` → `go run ./commitmsg` (both resolve tools from PATH).

### Vale binary-vs-sync split (critical nuance)
`.vale.ini`: `StylesPath = styles` (`.vale.ini:3`); `Packages = write-good, alex, <ai-tells v1.11.0 zip>` (`.vale.ini:4`); `--no-global`+`--minAlertLevel` passed at call site (`justfile:89`). `scripts/setup-vale.sh` content-hashes `.vale.ini` (`git hash-object`) into `styles/.vale-config-hash` and runs `vale sync` only when stale or a package dir is missing. `.gitignore:13-15` tracks `styles/config/` (vocab), ignores downloaded package dirs.
**Therefore: mise pins only the `vale` *binary*. The synced style packages
(ai-tells/write-good/alex) stay driven by `setup-vale.sh` + the CI cache, outside
mise's scope.** ai-tells version is pinned in `.vale.ini` independently.

### MP's existing mise patterns (model on these)
- A private `infra` repo: `.tool-versions` (asdf-compat, bare `name version`) is the version source of truth; `mise.toml` is lockfile-only (`[settings] lockfile = true`); committed `mise.lock` for checksum pinning. CI (Bitbucket) bootstraps mise with pinned version+sha, `MISE_FROZEN=1 mise install`, `mise activate bash --shims`.
- `dotfiles` ADR-020 (`nix/docs/decisions/020-nodejs-via-mise.md`): mise replaced fnm; **mise binary comes from Nix (tier2)**; activated in `fish.nix` (`mise activate fish | source`, lines 250-253) and shims dir `~/.local/share/mise/shims` is on `sessionPath` (`common.nix:39`) for non-interactive PATH. Availability(Nix) vs behavior(mise) split. Global node pin is imperative to keep `~/.config/mise/config.toml` writable.

### mise registry coverage (external, with sources)
All six pinned tools install via mise; `gofmt` comes from the pinned Go SDK. Backends: `just`/`stylua`/`selene`/`ast-grep`/`vale` → **aqua** (prebuilt, no Rust/Python toolchain); `go` → **core** backend (manages GOROOT/GOPATH, **gofmt ships inside the Go SDK** — free, no separate install); registry short names match tool names (`ast-grep` binary is still `sg`). Config: `mise.toml [tools]` wins over `.tool-versions`; both readable. Trust: CI auto-trusts when `CI=true`; no `mise trust` needed under the action. **`jdx/mise-action@v4`** (current; Node24) installs mise, runs `mise install`, caches the install dir keyed on config-file hash, uses `github.token` to avoid rate limits; supports `version:` (pin mise) + `cache:true`. Sources: mise.jdx.dev/registry.html, /dev-tools/, /lang/go.html, /continuous-integration.html, github.com/jdx/mise-action.

### CHANGELOG reference (claude-toolkit)
`claude-toolkit/CHANGELOG.md` (152 lines): `# Changelog` + intro stating it's a
personal toolkit (**no semver**); `## Unreleased`; then `## YYYY-MM-DD — Milestone
Title` entries with `### Added`/`### Changed`/`### Fixed` (no `Removed`) + a custom
`### Key PRs` linking GitHub PRs; newest-first; short outcome bullets pointing to
exec plans/ADRs, not implementation narration. **100% manual** — no CI/hook
automation. Policy lives in its own ADR (`docs/decisions/002-changelog-policy.md`),
framed as an opt-in human obligation, not an enforced gate.
nvim-lazy already enforces conventional commits (`scripts/commitmsg/main.go:12`,
types: feat, fix, docs, refactor, test, chore, style, perf, ci, build) — categories
map cleanly to changelog sections.

### Conventions + docs that go stale
- Plans: `exec-plans/active/` → `exec-plans/completed/` on done; filename `<slug>-YYYY-MM-DD.md` (`CLAUDE.md:23`). No `exec-plans/README.md`.
- Work-item field shape (from `exec-plans/completed/harness-engineering-adoption-2026-05-27.md`): `### Item N: <title>` then bold inline labels **Goal / What it does / Done when / Key files / Dependencies / Size** (optional **Status:**).
- ADRs: `docs/decisions/`, **next number 003** (001 harness, 002 home-path). Template (`docs/decisions/template.md`): Status | Date | Context | Decision | Alternatives considered | Consequences | Migration | Risks.
- **Stale on migration:** ADR-001 `001-harness-enforcement-substrate.md:71` ("Go… Already provisioned via Nix"); `ci.yml` env+install steps; `justfile:14-16` header. `docs/design-docs/tooling-policy.md` + `nix.md` are scoped to **Neovim language tooling (Mason vs Nix)** — not the harness toolchain — so they need at most a one-line clarifying note, not a rewrite.

## Approach

Targeted provisioning migration, **not** a harness refactor. Keep the `justfile`
recipes, `.githooks/*`, Go tooling under `scripts/`, the Vale sync script, and the
CI gate shape exactly as they are. Replace only **who owns tool versions** and
**how CI installs them**.

Decisions:

1. **Config shape — single `mise.toml`.** Pin versions directly in
   `mise.toml [tools]` and enable `[settings] lockfile = true`; commit `mise.lock`
   for lockfile pinning, with checksums where available. One file rather than the
   `infra` repo's `.tool-versions` + lockfile-only split — fewer files for this
   small toolchain, still lockfile-pinned. `mise.toml [tools]` is mise's documented default and wins over
   any `.tool-versions`.
2. **Pin all six harness gate tools in `mise.toml [tools]`** (versions match current CI):
   `stylua 0.20.0`, `selene 0.27.1`, `vale 3.14.1`, `ast-grep 0.36.0` (binary
   `sg`), `go 1.26` (latest supported — **not** the EOL `go.mod` floor; see Item 1). `just` is currently
   unpinned — pin it to the current stable resolved at implementation time
   (`mise ls-remote just`). `gofmt` is **not** listed — it ships inside the Go SDK.
3. **`just` moves to mise too.** This extends TD-008's older heuristic (which
   parked `just` in Nix). The user's brief explicitly wants `just` isolated from
   global-Nix breaking changes. Global Nix `just` stays installed as a bootstrap
   fallback; the mise shim wins on PATH inside the repo.
4. **Nix's role shrinks to availability, not version authority.** Nix still
   provides the `mise` binary (dotfiles tier2) and shim activation; repo-local
   gate behavior comes from mise. `nvim` (the editor, local-only, excluded from
   `just ci`) stays a Nix/machine concern — not in mise.
5. **Vale stays split.** mise pins only the `vale` *binary*. The `vale sync` style
   packages (ai-tells/write-good/alex) remain owned by `scripts/setup-vale.sh` +
   `.vale.ini` + the CI cache step. Do not move style packages into mise.
6. **CI uses one `jdx/mise-action@v4` step** (mise version pinned, cache on),
   replacing the `env:` version block + `setup-go` + `setup-just` + the curl/npm
   installs. Set frozen behavior (`MISE_FROZEN=1`) so CI fails fast if `mise.toml`
   and `mise.lock` drift. Keep the existing Vale style-package cache step; its
   cache key + `restore-keys` need updating now that `VALE_VERSION` is gone (see
   Item 2).
7. **One root `CHANGELOG.md`**, claude-toolkit format, maintained manually. No
   separate changelog ADR for now (the file + a brief `CLAUDE.md` pointer is
   enough; revisit only if policy grows).

## Work Items

> Order: **Item 1 is the front-loaded gate** — its hook-PATH probe and Go-resolution
> check can invalidate the whole approach, so run them first. Items 3, 4, 5 are
> independent of each other and can land in parallel once Item 1 is done. Item 6 is
> the definition-of-done gate; Item 7 (closeout) runs **only after** Item 6 is green.

### Item 1: Add mise files + prove the harness runs on mise-only tools
**Goal:** Make mise the local source of truth for harness binary versions, and prove the existing gate passes using mise-provided tools rather than global Nix.
**Done when:** `mise.toml` (`[tools]` pins + `[settings] lockfile = true`) and committed `mise.lock` exist; `mise install` succeeds; `just ci` passes with every gate binary resolving through mise; the git hooks resolve their tools through mise in a real (non-interactive) commit.
**Key files:** `mise.toml`, `mise.lock` (new); `scripts/go.mod` (floor bump); `justfile` (no behavior change)
**Dependencies:** None. **(Front-load — see verification 3 & 4.)**
**Size:** Medium.
**Details:** Six pins under `[tools]`: `stylua 0.20.0`, `selene 0.27.1`, `vale 3.14.1`, `ast-grep 0.36.0` (binary is `sg`), `go 1.26` (latest; see Go upgrade below), `just` (current stable, resolved at implementation via `mise ls-remote just`). `gofmt` is **not** listed — it ships in the Go SDK. Generate `mise.lock` via mise (never hand-edit checksums). Run one-time `mise trust`.
  - **Go upgrade to latest (DECIDED):** `scripts/go.mod`'s `go 1.22` floor is inherited from work tooling and is long EOL — only Go 1.25/1.26 are supported as of 2026. mise lets this repo own a current Go regardless of work. Pin `go = "1.26"` (latest supported; mise freezes the exact patch in `mise.lock`). Entailment: (1) bump `scripts/go.mod` `go 1.22` → `go 1.26` so the language floor matches what we run; (2) set `GOTOOLCHAIN=local` in `mise.toml [env]` so Go never silently self-downloads a toolchain that bypasses the mise pin — drift errors loudly instead (mirrors `MISE_FROZEN`); (3) scripts are stdlib-only so the bump is low-risk, but a newer toolchain can add `go vet` checks or (rarely) change `gofmt` output, so re-verify fmt/vet/test (verification 5).
**Verification:**
1. `mise install` then `mise current` reports all six tools at the pinned versions; each tool's `--version` matches.
2. In `/Users/mp/.config/nvim-lazy`, `which just stylua selene vale sg go` resolves to mise shims/install paths (not `/run/current-system` or `~/.nix-profile`).
3. `just ci` passes. **Isolation proof:** re-run with the Nix profile pruned from PATH, e.g. `env -i HOME=$HOME PATH="$HOME/.local/share/mise/shims:/usr/bin:/bin" mise exec -- just ci` — proves zero dependence on global tool versions.
4. **Hook-PATH probe (riskiest seam, front-load):** drive a throwaway `git commit` on a scratch change so `.githooks/pre-commit` and `.githooks/commit-msg` run in the *real* non-interactive git environment, and assert the tools they invoke (`vale`, `go`) resolve to `~/.local/share/mise/shims` there — not merely when the hooks are run by hand from an activated shell. If shims do not win non-interactively, fix PATH ordering (note: shims-on-PATH, not `mise activate`, is the non-interactive mechanism) before any other item.
5. **Go-upgrade sanity:** after pinning `go 1.26`, bumping the `go.mod` floor, and setting `GOTOOLCHAIN=local`, run `just fmt` (gofmt check), `just vet`, and `just test` — confirm the newer toolchain surfaces no new gofmt diffs or vet findings.

### Item 2: Rewrite GitHub Actions provisioning to use mise
**Goal:** Collapse CI provisioning to the same `mise.toml` + `mise.lock` source used locally.
**Done when:** CI has one mise provisioning step (no per-tool installs, no `env:` version block), keeps the Vale style-package cache, and runs `just ci` green.
**Key files:** `.github/workflows/ci.yml`
**Dependencies:** Item 1 (local proof must pass before rewiring CI).
**Size:** Medium.
**Details:** Remove the `env:` version pins (`STYLUA_VERSION`/`SELENE_VERSION`/`VALE_VERSION`/`SG_VERSION`), `actions/setup-go@v5`, `extractions/setup-just@v2`, the stylua/selene/vale curl blocks, and the `npm install -g @ast-grep/cli` step. Add `jdx/mise-action@v4` (pin its `version:`, `cache: true`), set `MISE_FROZEN=1`. Keep the `actions/cache@v4` Vale step.
  - **Vale cache-key constraint (implementer owns the exact expression):** the key must (a) change when the Vale binary or `.vale.ini`/`setup-vale.sh`/vocab change, (b) carry no duplicated version literal now that `VALE_VERSION` is gone, and (c) keep a working `restore-keys` fallback — the current `restore-keys` at `ci.yml:85-88` reference the deleted `VALE_VERSION` and the `vale-styles-` prefix and **must be updated too**. Prefer keying on `mise.lock` (which pins the Vale binary checksum) over hashing all of `mise.toml`, which over-invalidates the style cache on any of the six tool bumps.
**Verification:**
1. Grep the workflow: no `*_VERSION` env pins, no per-tool install steps, and no dangling `VALE_VERSION` in the cache key or `restore-keys`.
2. The GitHub run shows exactly one mise provisioning step + the Vale cache step + a passing `just ci`.

### Item 3: Update local provisioning wording (justfile + workflows doc)
**Goal:** Make repo guidance match the new source of truth.
**Done when:** Setup docs say mise owns repo-local gate tools, with Nix only as bootstrap/global fallback.
**Key files:** `justfile:14-16` (header), `docs/workflows.md`
**Dependencies:** Item 1. Parallel with Items 4, 5.
**Size:** Small.
**Details:** Rewrite the justfile header ("come from Nix Home Manager… activate your Nix profile first") to mise-first. Update `docs/workflows.md` fresh-clone steps to: `mise trust` → `mise install` → `just install-hooks`. Update any "missing go/vale → activate Nix" remediation to point at `mise install`. No recipe behavior changes.
**Verification:**
1. `just --list` still discovers all recipes.
2. `just prose` passes on the changed Markdown.

### Item 4: Add ADR-003 + correct stale decision docs
**Goal:** Record the harness-toolchain versioning decision in the ADR system.
**Done when:** ADR-003 exists (repo's 8-section template), the index links it, and stale Nix-provisioning wording is corrected.
**Key files:** `docs/decisions/003-mise-harness-toolchain.md` (new), `docs/decisions/index.md`, `docs/decisions/001-harness-enforcement-substrate.md:71`, `docs/design-docs/tooling-policy.md`
**Dependencies:** Item 1 (decision settled). Parallel with Items 3, 5.
**Size:** Medium.
**Details:** ADR-003 records the decision — *mise owns repo-local harness gate tools (`stylua`, `selene`, `vale` binary, `ast-grep`, `go`, `just`); Nix owns baseline availability + the mise binary/activation.* Fill the template's 8 sections (Status, Date, Context = local/CI drift + TD-008, Decision, Alternatives = keep manual CI installs / Nix-in-CI / `.tool-versions` split, Consequences, Migration, Risks = hook PATH + lockfile drift); leave the prose to the implementer. Record the Go-to-latest call too: mise pins `go 1.26`, the `go.mod` floor is bumped off the EOL work-inherited `1.22`, and `GOTOOLCHAIN=local` keeps mise authoritative. Also: update ADR-001:71 ("Already provisioned via Nix") → repo-pinned via mise, Nix as fallback; add one line to `tooling-policy.md` scoping it to Neovim language tooling, not harness gate tools.
**Verification:**
1. `just docs` validates links + ADR index coverage.
2. `just prose` passes on changed Markdown.

### Item 5: Add the root CHANGELOG.md
**Goal:** Create a concise, manually-maintained history index modeled on claude-toolkit.
**Done when:** Root `CHANGELOG.md` exists with `## Unreleased` and the two seeded milestone entries; a `CLAUDE.md` pointer references it.
**Key files:** `CHANGELOG.md` (new), `CLAUDE.md` (one-line pointer), optionally `docs/index.md`
**Dependencies:** None beyond the settled decision — independent of ADR-003. Parallel with Items 3, 4.
**Size:** Small–Medium.
**Details:** Structure: `# Changelog` + a short "personal config repo, not semver release notes" note + `## Unreleased` + newest-first dated milestones using `### Added`/`### Changed`/`### Fixed`. Seed two milestones: (a) `2026-05-29 — Mise harness toolchain + changelog` (mise migration + this changelog), (b) `2026-05-28 — Harness engineering adoption` linking `exec-plans/completed/harness-engineering-adoption-2026-05-27.md`. Omit `### Key PRs` unless real PR links exist. Keep bullets outcome-focused; point to plans/ADRs instead of restating them.
**Verification:**
1. `just prose` lints `CHANGELOG.md` clean.
2. Format diff against `claude-toolkit/CHANGELOG.md` — same heading/section shape.

### Item 6: Final local + CI validation (definition-of-done gate)
**Goal:** Prove the migration is complete from both local and CI perspectives before any closeout.
**Done when:** Local gate passes on mise-only tools **and** CI is green on the new provisioning path.
**Key files:** none (validates all touched files)
**Dependencies:** Items 1–5.
**Size:** Small.
**Verification:**
1. `just ci` (and `just check` if headless Neovim validation is practical locally).
2. GitHub Actions run is green with one mise step + the Vale cache step.

### Item 7: Close TD-008 + archive this plan
**Goal:** Mark the deferred debt complete and move the plan to completed.
**Done when:** TD-008 status is Closed with an outcome summary; this plan lives under `exec-plans/completed/`.
**Key files:** `exec-plans/tech-debt-tracker.md:61-80`; during closeout, this plan was archived from `exec-plans/active/mise-tooling-and-changelog-2026-05-29.md` to `exec-plans/completed/mise-tooling-and-changelog-2026-05-29.md`.
**Dependencies:** Item 6 (do not close/archive until validation is green).
**Size:** Small.
**Details:** Flip TD-008 Status Deferred → Closed; summarize outcome (`mise.toml` + `mise.lock`, mise CI action, docs, changelog). Move the plan file and add a completion note at its top.
**Verification:**
1. No `mise-tooling-and-changelog-2026-05-29.md` remains under `exec-plans/active/`.
2. `just docs` passes (the tracker/plan are tracked Markdown with links).

## Risks & migration notes

- **Bootstrap:** `just` is now repo-pinned, but setup commands still need a `just`/`mise` to exist. Nix-provided mise + shims (and global Nix `just`) remain the bootstrap path; document `mise install` as the first step.
- **Hook PATH (riskiest):** Git hooks run non-interactively and rely on mise shims being on PATH (dotfiles `common.nix` prepends `~/.local/share/mise/shims`) — *shims*, not `mise activate` (interactive only). Verify with Item 1's real-commit probe, not by running hooks from an activated shell. If shims lose to global Nix here, the migration's core claim fails — fix before everything else.
- **Lockfile drift:** `MISE_FROZEN=1` in CI makes `mise.toml` changes without a matching `mise.lock` fail fast — intentional.
- **Vale cache churn:** see Item 2 — key on `mise.lock` to avoid over-invalidating the style cache on unrelated tool bumps; keep a `restore-keys` fallback.
- **Prose gate on this plan:** this doc uses em-dashes, which the repo's `ai-tells.EmDashUsage = error` rule flags. `just prose` currently excludes `exec-plans/active/**` and `exec-plans/completed/**`; cleanup is needed if prose scope changes later or if this plan moves into a checked scope.

## Open Questions

_Resolved at the mid-flow check-in: `just` is pinned in mise (isolated, Nix as fallback); config uses a single `mise.toml [tools]` + committed `mise.lock` (not the `.tool-versions` split); CHANGELOG is the file + a `CLAUDE.md` pointer (no ADR); seed both milestones. None block implementation._

## References

- TD-008: `exec-plans/tech-debt-tracker.md:61-80`
- V2 stack investigation: `/Users/mp/Projects/personal/ai/claude-toolkit/docs/investigations/personal-project-stack-defaults-v2-2026-05-29.md`
- dotfiles ADR-020 (mise for node): `/Users/mp/Projects/personal/dotfiles/nix/docs/decisions/020-nodejs-via-mise.md`
- `infra` repo mise setup (reference): `mise.toml`, `.tool-versions`, `scripts/ci/install-tools.sh`
- claude-toolkit CHANGELOG + policy: `CHANGELOG.md`, `docs/decisions/002-changelog-policy.md`
- mise docs: https://mise.jdx.dev/dev-tools/ · https://mise.jdx.dev/lang/go.html · https://mise.jdx.dev/continuous-integration.html · https://github.com/jdx/mise-action
