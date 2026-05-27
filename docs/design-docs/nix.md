# Nix

Baseline `.nix` support (filetype, treesitter, formatting, and the `statix`
linter) comes from LazyVim's `lang.nix` extra. `lua/plugins/nix.lua` overrides
that extra to use this repo's preferred toolchain and is the source of truth for
the wiring. This doc covers the reasoning behind those choices.

All Nix tool binaries come from Nix Home Manager (on PATH), not Mason. See
[tooling-policy.md](tooling-policy.md) for why, and the sibling language docs
[go.md](go.md) and [kotlin.md](kotlin.md).

## LSP (nixd)

The extra wires `nil_ls` by default. `lua/plugins/nix.lua` disables it and uses
`nixd` instead. `nixd` is eval-based and offers module-options completion for
nix-darwin and home-manager, which helps when editing the dotfiles flake.

Options completion needs `settings.nixd.options` pointed at the flake with an
absolute path. The `nixd` binary comes from Home Manager, so the server is
fenced off from Mason with `mason = false`. The exact `settings` expressions
live in `lua/plugins/nix.lua`.

## Formatting (nixfmt)

`nixfmt` runs via conform.nvim, which owns format-on-save. `nixfmt` is the
official RFC-166 formatter. nixd's own LSP formatting is left unset so the two
do not double-format.

## Linting (statix and deadnix)

Two linters run via nvim-lint:

- `statix` catches Nix anti-patterns and can auto-fix with `statix fix`. It is
  wired by the `lang.nix` extra.
- `deadnix` reports dead code such as unused bindings and unused function
  arguments. The extra does not include it, so `lua/plugins/nix.lua` adds it
  alongside `statix`.

## Validating changes

`test-fixtures/nix/default.nix` is the smoke-test fixture. It triggers filetype
detection, treesitter highlighting, and a `nixd` attach, and deliberately
carries one `statix` finding and two `deadnix` findings so both linters can be
confirmed wired. See [workflows.md](../workflows.md) for the checklist.
