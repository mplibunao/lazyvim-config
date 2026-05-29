# Tooling provisioning policy: Nix vs Mason

This config draws language tooling (LSP servers, formatters, linters, debug
adapters) from two sources: Nix Home Manager and Mason. This doc defines which
source owns what, so the split stops being ad-hoc and future changes know where
each tool belongs.

This policy covers Neovim language tooling only; harness gate tools such as
`stylua`, `selene`, `vale`, `ast-grep`, Go, and `just` are governed by
[ADR-003](../decisions/003-mise-harness-toolchain.md).

## Policy

### 1. Nix Home Manager is authoritative for committed languages

A language is *committed* when it has a `lang.*` extra enabled in `lazyvim.json`
and a `lua/plugins/<lang>.lua` file. For committed languages, the LSP server,
formatter, and linter binaries come from Nix Home Manager, declared in the
dotfiles flake. Nix is the single source of truth for those binaries. The
Neovim side only tunes behavior (LSP settings, conform and nvim-lint routing);
it does not fetch the binaries.

The user's machine provisions dev tooling declaratively through Nix. Pinning
tool versions in the flake gives reproducible,
version-locked tooling that matches the rest of the system, rather than a
second, drifting copy managed by Mason.

### 2. Mason stays enabled, fenced to experimental languages

Mason remains enabled (only `bufferline.nvim` is disabled, in
`lua/plugins/disabled.lua`). Its role is a scratchpad for languages not yet
committed to the flake: trying a new language, or reaching for a one-off tool
not worth a rebuild.

Mason must never shadow a Nix-provided server. When a language's tooling moves
to Nix, fence Mason off for that server with `mason = false` in the
`nvim-lspconfig` `opts.servers.<server>` entry. That stops Mason from
auto-installing a duplicate that competes with the Nix binary on PATH. The Nix
support added by the Nix tooling work is the first language built to this rule
(`opts.servers.nixd = { mason = false }`, plus `nil_ls = { enabled = false }`
to keep the extra's default server from attaching).

### 3. Graceful degradation is the portability story

A missing tool binary does not break the config. If a Nix-provided binary is
absent (as on a machine without this Nix setup), the affected LSP does
not attach, and conform or nvim-lint cannot run that tool. The config keeps loading;
the affected LSP, formatter, or linter is simply unavailable and may emit a
tool-specific diagnostic when invoked. Editing still works in a reduced form.

This is what keeps the config portable despite leaning on Nix. A non-Nix
machine gets a degraded but functional editor (treesitter, keymaps, and any
Mason-installed tools still work), rather than a hard failure. conform and
nvim-lint formatter and linter entries use `optional = true` for this reason,
and an LSP with no binary on PATH stays detached without breaking startup.

### 4. The rebuild-tax tradeoff

Routing tooling through Nix has a cost. Adding, removing, or upgrading a tool
means editing the flake and running `darwin-rebuild switch`, which is slower and
heavier than Mason's `:MasonInstall`. Tool changes are coupled to a system
rebuild instead of an in-editor action.

This is the accepted price for reproducibility and a single source of truth.
Mason stays available so experimental work can skip the rebuild tax until a
language is worth committing.

## Current state inventory

The policy above is the target. Nix support fully follows it. Go's LSP (gopls)
follows it too: gopls comes from Nix with Mason fenced. Go's helper tools
(formatters, linter, debug adapter) intentionally stay on Mason as a sanctioned
partial (see the Go decision below). Kotlin predates the policy and still draws
its LSP and linter from Mason. Retrofitting Kotlin, and optionally moving Go's
helper tools to Nix, is a tracked follow-up (see the Deferred section of
`exec-plans/completed/nix-neovim-tooling-2026-05-27.md`).

Committed languages and where each tool comes from today:

| Language | Tool | Type | Source today |
|---|---|---|---|
| Go | gopls | LSP | Nix `tier2.nix`; Mason fenced (`mason = false`) |
| Go | goimports, gofumpt | Formatter | Mason |
| Go | golangci-lint | Linter | Mason |
| Go | delve | DAP | Mason |
| Go | gotestsum | Test runner | Nix `tier2.nix` (per `go.md`) |
| Kotlin | kotlin_language_server | LSP | Mason (via `lang.kotlin`) |
| Kotlin | ktlint | Formatter and linter | Mason (via `lang.kotlin`) |
| Kotlin | kotlin-debug-adapter | DAP | Mason |
| Nix | nixd | LSP | Nix `neovim.nix` |
| Nix | nixfmt | Formatter | Nix `neovim.nix` |
| Nix | statix, deadnix | Linter | Nix `nix-ops-tools.nix` |

The JSON, Markdown, Terraform, TOML, and TypeScript extras are enabled but carry
no local tool overrides; their tooling comes from Mason via the stock extras.

## Go: a sanctioned partial

Go's LSP (gopls) is Nix-provisioned with Mason fenced (`mason = false`). Its
helper tools (`goimports`, `gofumpt`, `golangci-lint`, `delve`, plus
`gomodifytags` and `impl`) stay on Mason, installed by the `lang.go` extra.
This is a deliberate exception, not an oversight: those tools are not duplicated,
and they work fine from Mason. Fencing non-LSP tools requires a hardcoded filter
on the extra's `ensure_installed` list that fails silently if it goes stale across
LazyVim updates. All six exist in nixpkgs, so a full move is a
low-effort follow-up if cross-machine reproducibility later warrants it.

Resolution history and deferred follow-ups: `exec-plans/completed/nix-neovim-tooling-2026-05-27.md`.

## Applying the policy to a new language

When committing a language to this config:

1. Declare its LSP, formatter, and linter in the dotfiles flake (Home Manager),
   not Mason.
2. Enable the `lang.*` extra in `lazyvim.json` for treesitter, filetype
   detection, and baseline wiring.
3. In `lua/plugins/<lang>.lua`, set `mason = false` on each Nix-provided server
   so Mason does not install a duplicate. Disable any extra-wired server you are
   replacing with `enabled = false`.
4. Keep conform and nvim-lint entries `optional = true` so the config degrades
   gracefully where the binary is absent.
