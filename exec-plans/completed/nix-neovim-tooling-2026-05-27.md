# Nix language tooling for Neovim: Plan

## Goal

Make this LazyVim config first-class for editing Nix code (LSP, formatting, linting, and treesitter for `.nix` files) by **wiring Neovim to the Nix tools already installed via Home Manager**, plus adding the one that is missing, following the repo's existing one-file-per-language convention.

## Background

### Reframe: an integration task, not an install task

The user is new to Nix and assumed nothing was set up. In fact most binaries are already declared via Home Manager, and Neovim just does not use them for `.nix` files. There is **no `lang.nix` extra enabled and zero `nix` references** in `lua/`. The work is integration, not bulk installation. A few small tooling choices are settled under Decisions.

### Current Neovim per-language pattern (in-workspace recon)

The repo uses **one file per language** under `lua/plugins/`. A new `lua/plugins/nix.lua` would follow these patterns:

- **LSP tuning**: append under `opts.servers.<name>`, which LazyVim deep-merges. Server *enablement* comes from the lang extra, and local files only tune. Template: `lua/plugins/go.lua:46-59`, `lua/plugins/kotlin.lua:49-69`.
- **Formatter**: `conform.nvim` `formatters_by_ft`, with `optional = true`. Template: `lua/plugins/go.lua:16-23`.
- **Linter**: `mfussenegger/nvim-lint` `linters_by_ft`, with `optional = true`. Template: `lua/plugins/go.lua:25-32`.
- **Treesitter**: no local `ensure_installed` anywhere. Parsers come from the lang extra (`docs/workflows.md:45`). Never list parsers locally.
- **Mason**: enabled (`lua/plugins/disabled.lua` only disables bufferline). Tools register via `vim.list_extend(opts.ensure_installed, {...})` (`lua/plugins/go.lua:4-15`).
- **Mason-vs-Nix split is currently ad-hoc, not a policy**: `gotestsum` is "managed via nix (`nix/home/mp/packages/tier2.nix`), not Mason" (`docs/go.md:22`), but most Go tools (`goimports`, `gofumpt`, `golangci-lint`, `delve`) are Mason-installed (`go.lua:4-15`). `gopls` is declared in Nix `tier2.nix` while also likely auto-installed by Mason via the `lang.go` extra (**probable duplicate, to verify**). The current state is inconsistent. This plan extends Nix ownership to Nix's own tooling and formalizes the policy (DECIDED, see Work Item 0) so the boundary stops being implicit.
- **Enabled extras** (`lazyvim.json:8-15`): `lang.go/json/kotlin/markdown/terraform/toml/typescript`. **No `lang.nix`.**

### The user's Nix setup (insertion points and what already exists)

Single-host Determinate Nix, nix-darwin, and Home Manager flake. The host key is `m5-mbp` (machine hostname is `MPs-MacBook-Pro`, but the `--flake .#m5-mbp` selector is what matters). Dev tooling (LSPs, formatters, linters) is installed **declaratively via Nix, not Mason**.

Already installed (three of four target tools plus an existing Nix LSP):

| Tool | Status | Declared in |
|---|---|---|
| `nil` (Nix LSP) | ✅ | `dotfiles/nix/home/mp/modules/neovim.nix:17` |
| `nixfmt` | ✅ | `neovim.nix:26` |
| `statix` | ✅ | `dotfiles/nix/home/mp/modules/nix-ops-tools.nix:25` |
| `deadnix` | ✅ | `nix-ops-tools.nix:24` |
| `nixd` (Nix LSP) | ❌ missing | not present |

- **Insertion point for `nixd`**: the `home.packages` `with pkgs; [ ... ]` list in `neovim.nix:14-28`, beside `nil` (at `:17`). Add a bare attribute line (`nixd`). **Leave the `nixfmt` attr (`:26`) as-is.** On the flake's `nixpkgs-unstable` pin, bare `nixfmt` is the official RFC-style formatter, and `nixfmt-rfc-style` is now a deprecation alias that warns from 26.05 (verified upstream), so switching to it would be backwards.
- **Apply command** (requires explicit user approval per the nix skill's safety boundary): `sudo darwin-rebuild switch --flake .#m5-mbp`. Pre-apply verification ladder (run in `dotfiles/nix/`, `git add` new files first): `nix flake check --no-build --all-systems`, then `nixfmt . ; statix check ; deadnix`, then `darwin-rebuild build --flake .#m5-mbp`. The `nix-verify` wrapper runs Levels 0-2.
- **Key caveat**: `neovim.nix` sets `programs.neovim.enable = true` (Nix manages the `nvim` binary), but the LazyVim config lives separately under `~/.config/nvim`. Nix supplies the *binaries*, and the LazyVim side must be told to use them and **not let Mason fetch a duplicate LSP**.

### External landscape (2025-2026): the nil-vs-nixd decision

- **nixd** (v2.9.1, Apr 2026, nix-community): eval-based diagnostics, goto-def into nixpkgs, hover, and the headline feature, **module options completion** for NixOS, home-manager, **nix-darwin**, and flake-parts. That feature helps a Nix beginner editing their own darwin or home-manager config. It **requires** a `settings.nixd` block with `options.*.expr` pointing at the flake (`builtins.getFlake`). Without it you get package completion but no options completion.
- **nil** (oxalica, snapshot 2025-06): strong incremental analysis and flake support, lower-friction, but **no options completion**. Maintenance cadence has slowed, and community momentum is on nixd.
- **Formatter**: the official RFC-166 formatter (nixfmt v1.2.0) is what nixpkgs enforces. **On `nixpkgs-unstable` (this flake's pin), the canonical attribute is now bare `nixfmt`.** `nixfmt-rfc-style` became a deprecation alias that warns from 26.05, and `pkgs.nixfmt-classic` is the old style. `alejandra` and `nixpkgs-fmt` are preference or legacy.
- **Linters**: `statix` (anti-patterns plus `statix fix`) and `deadnix` (dead bindings) via **nvim-lint**, the live path. none-ls and null-ls are legacy, with null-ls archived.
- **LazyVim `lang.nix` extra** ([source](https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/lang/nix.lua)): wires `nil_ls` (not nixd), `nixfmt` (conform), `statix` (nvim-lint), and treesitter `nix`. Root file is `flake.nix`. **deadnix is not included by default.** To use nixd you override the extra's LSP entry.
- **`settings.nixd` block shape** (LazyVim path: `opts.servers.nixd.settings`):
  ```lua
  settings = {
    nixd = {
      nixpkgs = { expr = "import <nixpkgs> { }" },
      -- Use the ABSOLUTE flake path; `./.` resolves to nixd's cwd, which is rarely the flake dir.
      options = {
        -- nix-darwin top-level options (system.defaults.*, etc.):
        darwin = { expr = '(builtins.getFlake "/Users/mp/Projects/personal/dotfiles/nix").darwinConfigurations."m5-mbp".options' },
        -- home-manager options (where MP mostly edits) nest at .options.home-manager.users.mp.*,
        -- so a SEPARATE entry is needed for completion in HM module files; exact sub-options expr TBD in impl.
      },
      -- formatting left to conform.nvim; do NOT set formatting.command (double-format)
    },
  }
  ```
- **Formatting routing**: pick ONE. Either conform.nvim runs `nixfmt` (the LazyVim default, recommended since LazyVim owns format-on-save), or nixd's LSP runs `formatting.command`. Do not enable both (double-format).

## Approach

A **targeted three-layer integration**, not a refactor. Sequence the external Nix package change first (so `nixd` is on PATH), enable LazyVim's `lang.nix` extra for the free baseline, then add one local override file to switch the LSP to `nixd` and add `deadnix`. LazyVim keeps owning format-on-save via conform.nvim and `nixfmt`, and `nixd` LSP formatting stays off to avoid double-format.

| Layer | What it does | Owner |
|---|---|---|
| **Home Manager** (`dotfiles/nix`, in-workspace) | Adds `nixd`, removes `nil`, and **leaves `nixfmt` as-is** (already RFC-style on unstable). `statix` and `deadnix` already present. No Nix tools via Mason. | `home/mp/modules/neovim.nix` |
| **LazyVim baseline** | `lang.nix` extra adds treesitter `nix`, conform `nixfmt`, nvim-lint `statix`, and default `nil_ls` wiring | `lazyvim.json` |
| **Local override** | Switches the LSP to `nixd` (with options-completion `settings`) and adds the `deadnix` linter. Formatting stays with conform. | `lua/plugins/nix.lua` (new) |

**Key behavior decisions** (the chosen path; resolved decisions are listed under Decisions):
- **LSP: `nixd` with options completion, `nil` removed** (DECIDED). Only `nixd` gives nix-darwin and home-manager module-options completion. Wire `settings.nixd.options` with an **absolute** flake path (not `./.`). The `darwin` entry (`darwinConfigurations."m5-mbp".options`) covers nix-darwin top-level options. **home-manager options nest at `.options.home-manager.users.mp.*`, so a separate entry is needed** for completion in HM module files (where MP mostly edits), and the exact sub-options expr is an impl detail. Drop the now-redundant `nil` binary (single source of truth per the tooling policy), and still disable the extra's `nil_ls` so nvim does not try to attach a missing binary.
- **Formatting: conform.nvim and `nixfmt`** (DECIDED, reversed after verification). **Leave the Home Manager `nixfmt` attr as-is.** On `nixpkgs-unstable`, bare `nixfmt` is already the official RFC-style formatter, and `nixfmt-rfc-style` is a deprecation alias warning from 26.05, so switching would be backwards. LazyVim owns format-on-save, so leave `settings.nixd.formatting.command` unset (double-format ownership).
- **Linting: `statix` and `deadnix`** (DECIDED). `statix` comes from the extra, and `deadnix` is added locally (installed but unwired today, with no overlap with statix).
- **Treesitter: owned by the extra.** Never list parsers locally (repo convention).
- **Tool provisioning: Nix-authoritative, Mason fenced** (DECIDED). For committed languages, LSP, formatter, and linter binaries come from Nix Home Manager. Mason stays enabled only as a scratchpad for *experimental* languages not yet in the flake, and must never shadow a Nix-provided server. This plan writes that rule down as a design doc (Work Item 0) and applies it to Nix support. Retrofitting Go and Kotlin is a tracked follow-up (see Deferred).

## Work Items

### Item 0: Formalize the Nix-vs-Mason tooling policy (design doc) ✅ DONE
**Goal:** Turn the implicit, ad-hoc tool-provisioning split into a written, durable repo convention, so future changes (and agents) know where each tool comes from and Mason cannot silently shadow Nix.
**Done when:** A design doc (proposed `docs/tooling-policy.md`) states four things. First, Nix Home Manager is authoritative for LSPs, formatters, and linters of *committed* languages. Second, Mason stays enabled only for experimental or uncommitted languages and must not shadow a Nix-provided server (the `mason = false` fence). Third, graceful degradation is the portability story (a missing binary means the LSP just does not attach), so non-Nix machines work in reduced form rather than breaking. Fourth, the rebuild-tax tradeoff is named. The doc inventories current state and **explicitly flags the probable duplicate `gopls`** (Nix `tier2.nix` plus Mason via `lang.go`). `docs/index.md` and the `CLAUDE.md` "Where to read" table link it, and the router stays within size guidance.
**Key files:** new `docs/tooling-policy.md`; `docs/index.md`; `CLAUDE.md` "Where to read" table; references `docs/go.md:22`, `docs/architecture.md`.
**Dependencies:** None. The rest of the plan builds on this policy, so author it early. Item 4's Mason fence is the first application of it.
**Size:** Small.

### Item 1: Update Home Manager: add `nixd`, drop `nil` ✅ DONE (edit + static verify; rebuild gated to user)
**Goal:** Make `nixd` available on PATH and remove the redundant `nil`, before Neovim is wired to use them.
**Done when:** in `home/mp/modules/neovim.nix` `home.packages`, `nixd` is added and `nil` is removed. After rebuild, `nixd --version` works and `nil` is gone from PATH, while `nixfmt`, `statix`, and `deadnix` still resolve. The Neovim config is not yet changed to require `nixd`.
The `nixfmt` attr (`:26`) stays untouched, because on `nixpkgs-unstable` it is already the RFC-style formatter (`nixfmt-rfc-style` is a deprecation alias warning from 26.05) and needs no edit.
**Key files:** `/Users/mp/Projects/personal/dotfiles/nix/home/mp/modules/neovim.nix:14-28` (in-workspace root, `nil` at `:17`).
**Dependencies:** None in-repo. Requires explicit user approval before `sudo darwin-rebuild switch --flake .#m5-mbp` (nix skill safety boundary). Run the verify ladder (`nix flake check`, then `nixfmt . ; statix check ; deadnix`, then `darwin-rebuild build`) before switch.
**Size:** Small.

### Item 2: Verify the Nix package-side toolchain ✅ DONE (nixd 2.9.0 on PATH; nil gone; nixfmt/statix/deadnix resolve)
**Goal:** Confirm the external toolchain is ready before editor integration begins.
**Done when:** from the shell that launches Neovim, `command -v` finds `nixd`, `nixfmt`, `statix`, and `deadnix`. `nixd` is the binary Neovim will inherit via PATH, and no Mason duplicate is introduced.
**Key files:** None. Runtime checks after Home Manager activation.
**Dependencies:** Item 1.
**Size:** Small.

### Item 3: Enable LazyVim's Nix extra ✅ DONE
**Goal:** Turn on baseline `.nix` support (filetype, treesitter, `nixfmt`, `statix`, default LSP wiring).
**Done when:** `lazyvim.plugins.extras.lang.nix` is in the `extras` array. `:Lazy sync` has run and `lazy-lock.json` is reviewed. Opening a `.nix` file gives filetype and treesitter highlighting, and no local parser entry is added.
**Key files:** `lazyvim.json:8-15` (add beside the other `lang.*`).
**Dependencies:** Item 2 (so package checks are known-good before editor wiring).
**Size:** Small.

### Item 4: Add local Nix plugin override (`lua/plugins/nix.lua`) ✅ DONE (Review Gate 1 passed; nixpkgs.expr pinned per review)
**Goal:** Make the extra use the repo's preferred toolchain: `nixd` for LSP, and `deadnix` alongside `statix` for linting.
**Done when:** new `lua/plugins/nix.lua` follows the one-language-per-file convention. `nixd` is configured under `nvim-lspconfig` `opts.servers` with `settings.nixd` using an **absolute** flake path (not `./.`). Options completion includes both a `darwin` entry and a `home-manager` entry (so HM-module files get completion). `nil_ls` is prevented from attaching, and `nixd` is excluded from Mason auto-install (PATH binary). `deadnix` is added to `linters_by_ft.nix` with `statix` retained, and no `nixd` formatting command is set.
**Key files:** new `lua/plugins/nix.lua`; templates `lua/plugins/go.lua:4-15` (Mason pattern, to AVOID here), `go.lua:16-32` (conform/nvim-lint), `go.lua:46-59` and `kotlin.lua:49-69` (LSP `opts.servers`), `kotlin.lua:33-44` (nvim-lint mutation).
**Confirmed mechanisms** (verified against current LazyVim upstream): `opts.servers.nil_ls = { enabled = false }` is honored (the server is skipped and added to `mason_exclude`), and `opts.servers.nixd = { mason = false }` is honored (skips Mason auto-install). The `lang.nix` extra does set `nil_ls = {}`, so the disable is necessary.
**Sequencing note:** land Item 4 right after Item 3. Between enabling the extra (which wires `nil_ls`) and this override (which disables it), `nil` is already gone, so `nil_ls` just fails to attach. That is benign log noise, not an error.
**Dependencies:** Items 2 and 3.
**Size:** Medium.

### Item 5: Add a Nix test fixture ✅ DONE (statix+deadnix confirmed flagging intentional constructs)
**Goal:** Minimal `.nix` file so agents can validate treesitter, format, lint, and LSP without the external dotfiles repo.
**Done when:** `test-fixtures/nix/default.nix` exists and triggers filetype detection, treesitter highlighting, `nixd` attach, the `statix` and `deadnix` lint paths, and `nixfmt` formatting. `test-fixtures/README.md` lists `nix/`.
**Key files:** new `test-fixtures/nix/default.nix`; `test-fixtures/README.md`.
**Dependencies:** Items 3 and 4.
**Size:** Small.

### Item 6: Document Nix language support ✅ DONE
**Goal:** Concise user-facing doc for how Nix support works and where tools are managed.
**Done when:** `docs/nix.md` documents the `nixd` LSP, `nixfmt` via conform, `statix` and `deadnix` via nvim-lint, tools from Home Manager rather than Mason, and conform owning formatting. `docs/index.md` links it, and `CLAUDE.md` "Where to read" links it if still within the router's size guidance.
**Key files:** new `docs/nix.md`; `docs/index.md`; `CLAUDE.md` "Where to read" table; reference `docs/go.md`, `docs/kotlin.md`.
Item 0 also touches `docs/index.md` and `CLAUDE.md` "Where to read". Make one combined edit per file (policy-doc and nix-doc links together) rather than two passes.
**Dependencies:** Items 3 and 4.
**Size:** Small.

### Item 7: Extend validation workflow for the Nix fixture ✅ DONE
**Goal:** Make future plugin updates test Nix support the way they test Go, Kotlin, and others.
**Done when:** the `docs/workflows.md` smoke-test checklist includes `test-fixtures/nix/default.nix` and verifies that `nixd` attaches, treesitter highlights, `statix` and `deadnix` are configured for `nix`, and manual format uses `nixfmt`. Headless and tmux examples stay consistent with `NVIM_APPNAME=nvim-lazy`.
**Key files:** `docs/workflows.md` (fixture checklist and headless examples).
**Dependencies:** Item 5.
**Size:** Small.

### Item 8: Run editor-side validation ✅ DONE (headless: nixd attached not nil_ls; lint={statix,deadnix}; conform={nixfmt}; both options exprs deliver + nix-eval to real option trees. Live completion popup UX left to user.)
**Goal:** Prove the integration works end-to-end.
**Done when:** `stylua` passes. `:Lazy sync` is done and the lockfile reviewed. Headless startup on the fixture succeeds. The tmux LSP smoke test shows **`nixd` (not `nil_ls`)** attached. nvim-lint for `nix` includes both `statix` and `deadnix`, and conform for `nix` resolves to `nixfmt`. A real `.nix` file in the dotfiles flake gets nix-darwin option completion from `nixd`.
**Key files:** `docs/workflows.md` (headless and tmux guidance); `test-fixtures/nix/default.nix`; a real `.nix` file in the dotfiles flake (options completion needs flake context).
**Dependencies:** Items 1-7.
**Size:** Medium.

## Risks

- **Duplicate LSP:** the extra enables `nil_ls` by default, so the override must ensure only `nixd` attaches.
- **PATH ordering:** `nixd` must exist before the Neovim override lands, or LSP validation fails (so Items 1-2 come first).
- **Formatting ownership:** never enable both conform and `nixd` formatting.
- **Flake-context:** `nixd` module-options completion may only fully work inside the dotfiles flake, so validate both the fixture and a real dotfiles `.nix` file.

## Decisions (resolved during planning)

Resolved during the Mid-flow check-in (2026-05-27):

1. **LSP: nixd with options completion, remove `nil`.** Wire `settings.nixd.options` with an absolute flake path. A `darwin` entry covers nix-darwin options, and a separate `home-manager` entry (options nest at `.options.home-manager.users.mp.*`) is needed for HM-module completion. Drop the redundant `nil` binary, and still disable the extra's `nil_ls`.
2. **Linting: statix and deadnix** (both wired in `linters_by_ft.nix`).
3. **Formatter attribute: leave `nixfmt` as-is** (reversed after upstream verification). On `nixpkgs-unstable`, bare `nixfmt` is already the RFC-style formatter, and `nixfmt-rfc-style` is a deprecation alias warning from 26.05. The earlier "switch to nixfmt-rfc-style" pick was based on stale research, so no formatter edit is needed.

No open questions remain that block the build.

## Deferred follow-ups

- **Retrofit Go and Kotlin to the new tooling policy** (deferred from this plan to keep scope on Nix).
  - **Go gopls duplicate: RESOLVED (2026-05-27, fence-only follow-up).** Confirmed the duplicate by inspecting both repos (Nix `tier2.nix` + Mason via `lang.go`). Fenced with `gopls = { mason = false }` in `lua/plugins/go.lua`, removed the redundant Mason tool list there, and uninstalled the orphaned Mason copy. Neovim now uses the Nix `gopls`, verified via `vim.fn.exepath`. Go's helper tools (`goimports`, `gofumpt`, `golangci-lint`, `delve`, `gomodifytags`, `impl`) were **deliberately kept on Mason** as a sanctioned partial (fencing non-LSP tools needs a silently-failing filter; not worth it for non-duplicated tools that work fine). Rationale and the full-move path are recorded in `docs/tooling-policy.md`.
  - **Still deferred:** the optional full move of Go's helper tools to Nix (all six verified available in nixpkgs), and the Kotlin retrofit (LSP + ktlint still Mason-only). The policy doc inventories current state so a later pass can act on it.

## References

- LazyVim Nix extra: <https://www.lazyvim.org/extras/lang/nix> · [source](https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/lang/nix.lua)
- nixd: <https://github.com/nix-community/nixd> · [configuration.md](https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md)
- nil: <https://github.com/oxalica/nil>
- nixfmt (RFC 166): <https://github.com/NixOS/nixfmt> · [Enforcing Nix formatting in Nixpkgs](https://discourse.nixos.org/t/enforcing-nix-formatting-in-nixpkgs/49506)
- Practical nixd-in-Neovim incl. darwin expr: <https://sbulav.github.io/vim/neovim-setting-up-nixd/>
- In-repo templates: `lua/plugins/go.lua`, `lua/plugins/kotlin.lua`; tool-split precedent `docs/go.md:22`
- Nix insertion points: `dotfiles/nix/home/mp/modules/neovim.nix:14-28`, `nix-ops-tools.nix:23-26`
