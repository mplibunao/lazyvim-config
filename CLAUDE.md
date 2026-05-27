# CLAUDE.md

This file is a **router, not a manual**. It points to where information lives.
Do not add reference material here — if it would push this file past ~100 lines, it belongs in `docs/`.

`AGENTS.md` is a symlink to this file. Edit here, not there.

## Overview

LazyVim configuration repo. Plugins are managed by lazy.nvim, extras are declared in `lazyvim.json`, and most local code customizations live in `lua/plugins/*.lua` and `lua/config/*.lua`.

## Critical rules

- **Code is the source of truth.** Do not restate behavior that is visible by reading the relevant Lua file or config. Point to the file instead.
- **One plugin per concern.** Each file in `lua/plugins/` should return a table of plugin specs for a coherent feature area.
- **Format with `stylua`.** Settings are in `stylua.toml` — do not duplicate them here.
- **No manual AGENTS.md edits.** It is a symlink to `CLAUDE.md`.
- **Topic docs go in `docs/`.** Language-specific guidance, workflow conventions, and architecture notes each get their own file.
- **Decision history goes in `exec-plans/`.** Use `exec-plans/active/` for in-progress plans, `exec-plans/completed/` for finished ones.

## Repo map

### Where to edit

| To change... | Edit |
|---|---|
| lazy.nvim bootstrap, defaults, performance | `lua/config/lazy.lua` |
| Editor-wide options, root detection | `lua/config/options.lua` |
| Global keymaps and user commands | `lua/config/keymaps.lua` |
| Event-driven behavior (autocmds) | `lua/config/autocmds.lua` |
| Plugin overrides or new plugins | `lua/plugins/<topic>.lua` |
| Enabled LazyVim extras | `lazyvim.json` (or `:LazyExtras`) |
| Lua formatting rules | `stylua.toml` |

### Where to read

| For... | See |
|---|---|
| Load chain and file ownership | [docs/architecture.md](docs/architecture.md) |
| Customization clusters (what diverges from stock LazyVim) | [docs/architecture.md](docs/architecture.md) |
| Agent validation workflows (tmux, headless checks) | [docs/workflows.md](docs/workflows.md) |
| Go tooling setup | [docs/go.md](docs/go.md) |
| Kotlin tooling and formatting | [docs/kotlin.md](docs/kotlin.md) |
| Nix tooling and LSP setup | [docs/nix.md](docs/nix.md) |
| Tool provisioning policy (Nix vs Mason) | [docs/tooling-policy.md](docs/tooling-policy.md) |
| Keymap and usage reference | [cheatsheet.md](cheatsheet.md) |
| Visual keybinding cheatsheet | [~/.agent/diagrams/nvim-keybindings.html](~/.agent/diagrams/nvim-keybindings.html) |
| Documentation catalog and placement rules | [docs/index.md](docs/index.md) |
| Plugin update validation and test fixtures | [docs/workflows.md](docs/workflows.md), [test-fixtures/](test-fixtures/) |
| Past implementation decisions | [exec-plans/](exec-plans/) |

## Plugin patterns

Adding, overriding, and disabling plugins all follow standard LazyVim conventions.
See existing files in `lua/plugins/` for working examples — they are the best reference.

To disable a LazyVim plugin, add it to `lua/plugins/disabled.lua` with `enabled = false`.

## References

- <https://www.lazyvim.org/plugins> — LazyVim plugins
- <https://www.lazyvim.org/keymaps> — LazyVim keymaps

Do not read the files in references unless told explicitly to.
