# CLAUDE.md

This file is a **router, not a manual**. It points to where information lives.
Do not add reference material here; if it would push this file past ~100 lines, it belongs in `docs/`.

`AGENTS.md` is a symlink to this file. Edit here, not there.

## Overview

LazyVim configuration repo. Plugins are managed by lazy.nvim, extras are declared in `lazyvim.json`, and most local code customizations live in `lua/plugins/*.lua` and `lua/config/*.lua`.

## Critical rules

- **Code is the source of truth.** Do not restate behavior that is visible by reading the relevant Lua file or config. Point to the file instead.
- **One plugin per concern.** Each file in `lua/plugins/` should return a table of plugin specs for a coherent feature area.
- **Format with `stylua`.** Settings are in `stylua.toml`. Do not duplicate them here.
- **No manual AGENTS.md edits.** It is a symlink to `CLAUDE.md`.
- **Topic docs go in `docs/`.** Per-area design and policy go in `docs/design-docs/`; architecture notes go in `ARCHITECTURE.md`; single decisions go in `docs/decisions/`.
- **Implementation plans go in `exec-plans/`.** Use `exec-plans/active/` for in-progress plans, `exec-plans/completed/` for finished ones. Deferred work items go in `exec-plans/tech-debt-tracker.md`. Architectural decisions (ADRs) go in `docs/decisions/`.

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
| Load chain and file ownership | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Customization clusters (what diverges from stock LazyVim) | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Agent validation workflows (`just check` and manual probes) | [docs/workflows.md](docs/workflows.md) |
| Per-area design docs (tooling, language setup, operating principles) | [docs/design-docs/](docs/design-docs/index.md) |
| Architecture decisions (ADRs) | [docs/decisions/](docs/decisions/) |
| Deferred work items | [exec-plans/tech-debt-tracker.md](exec-plans/tech-debt-tracker.md) |
| Keymap and usage reference | [cheatsheet.md](cheatsheet.md) |
| Visual keybinding cheatsheet | [~/.agent/diagrams/nvim-keybindings.html](~/.agent/diagrams/nvim-keybindings.html) |
| Documentation catalog and placement rules | [docs/index.md](docs/index.md) |
| Plugin update validation and test fixtures | [docs/workflows.md](docs/workflows.md), [test-fixtures/](test-fixtures/) |
| Past implementation decisions | [exec-plans/](exec-plans/) |
| External reference material | [docs/references/](docs/references/index.md) |

## Plugin patterns

Adding, overriding, and disabling plugins all follow standard LazyVim conventions.
See existing files in `lua/plugins/` for working examples; they are the best reference.

To disable a LazyVim plugin, add it to `lua/plugins/disabled.lua` with `enabled = false`.

## References

- LazyVim plugins: <https://www.lazyvim.org/plugins>
- LazyVim keymaps: <https://www.lazyvim.org/keymaps>

Do not read the files in references unless told explicitly to.
