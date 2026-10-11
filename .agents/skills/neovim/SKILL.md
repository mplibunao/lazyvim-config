---
name: neovim
description: "Maintain Neovim and LazyVim config: plugins, keymaps, options, autocmds, NVIM_APPNAME switching, startup and LSP debugging. Use for ~/.config/nvim-* or fish nvim-config."
---

# Neovim Configuration Skill

Maintain and automate Neovim configurations, with emphasis on the LazyVim setup.

## Canonical Paths

| Location                                                            | Description                                          |
| ------------------------------------------------------------------- | ---------------------------------------------------- |
| `~/.config/nvim-lazy/`                                              | LazyVim config (current main)                        |
| `~/.config/nvim/`                                                   | Default Neovim config (when `NVIM_APPNAME` is unset) |
| `~/.config/nvim-lua/`                                               | Legacy lua config (used by `lv` abbreviation)        |
| `~/Projects/personal/dotfiles/fish/functions/a_mp/nvim-config.fish` | Config switcher                                      |

## Config Switching

The `nvim-config` Fish function manages `NVIM_APPNAME`:

```fish
nvim-config          # Show current configuration
nvim-config lazy     # Set to use ~/.config/nvim-lazy/
nvim-config default  # Reset to default ~/.config/nvim/
```

**How it works:** Neovim uses `$NVIM_APPNAME` to locate config in `~/.config/$NVIM_APPNAME/`. The variable is set as a Fish universal+exported variable, persisting across sessions.

The `lv` abbreviation maps to `nvim-lua`, not `nvim-lazy`. Use `nvim-config lazy` then `nvim` directly for LazyVim.

## LazyVim Layout

- `init.lua` bootstraps lazy.nvim.
- `lua/config/options.lua`, `autocmds.lua`, and `keymaps.lua` hold custom settings.
- `lua/plugins/*.lua` are plugin specs that lazy.nvim loads automatically.
- `lazyvim.json` lists the enabled extras, and `lazy-lock.json` pins plugin versions.

Loading order, each key file, and the extras system: [lazyvim-architecture.md](references/lazyvim-architecture.md).

## Common Tasks

| Task                                | Where                                                        | Pattern                                                                                             |
| ----------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| Add, override, or disable a plugin  | `lua/plugins/<name>.lua`, `lua/plugins/disabled.lua`         | [plugin-patterns.md](references/plugin-patterns.md)                                                 |
| Custom keymaps, options, autocmds   | `lua/config/keymaps.lua`, `options.lua`, `autocmds.lua`      | `vim.keymap.set("n", "<leader>xx", fn, { desc = "..." })`, `vim.opt.relativenumber = true`          |
| Enable a LazyVim extra              | `:LazyExtras` or `lazyvim.json`                              | [Enabling extras safely](references/install-and-crash-recovery.md#enabling-lazyvim-extras-safely)   |

## Validation

Prefer headless checks; they need no terminal and fit agent workflows:

```bash
nvim --headless -c 'lua print("ok")' -c 'qa'                               # Syntax errors
nvim --headless -c 'lua require("lazy"); print("lazy-ok")' -c 'qa'         # Plugins load (no install/update)
nvim --headless -c 'checkhealth' -c 'qa' 2>&1 | head -100                  # Health checks
NVIM_APPNAME=nvim-lazy nvim --headless -c 'lua print("ok")' -c 'qa'        # A specific config
nvim --headless -c 'Lazy sync' -c 'qa'                                     # Install/update plugins (network; only when intended)
```

Fall back to interactive `nvim` with `:Lazy`, `:checkhealth`, and `:LazyExtras` only when headless is insufficient. More in [headless-automation.md](references/headless-automation.md).

## Debugging

```bash
nvim --startuptime /tmp/startup.log && sort -k2 -n /tmp/startup.log | tail -20   # Slow startup
nvim -u NONE                                                                      # Baseline without config
nvim --clean                                                                      # Minimal config
```

Inside Neovim: `:Lazy` (plugin errors), `:Lazy log`, `:Lazy profile`, `:LspInfo`, `:LspLog`, `:Mason`, `:checkhealth lsp`. Log locations and deeper techniques: [debugging-and-logs.md](references/debugging-and-logs.md).

## Install and Crash Recovery (macOS)

After `:TSUpdate`, `:TSInstall`, or any treesitter parser recompilation, re-sign the parsers, or macOS kills nvim with `SIGKILL (Code Signature Invalid)`:

```bash
for f in ~/.local/share/nvim-lazy/site/parser/*.so; do codesign -f -s - "$f"; done
```

[install-and-crash-recovery.md](references/install-and-crash-recovery.md) has the symptom, the safe way to enable an extra without crashing the next launch, and forcing native plugin rebuilds after a machine or architecture change.

## Scripts

Helper scripts live in `.agents/skills/neovim/scripts/`; run them from the repo root:

| Script             | Purpose                                       |
| ------------------ | --------------------------------------------- |
| `nvim-locate.sh`   | Find config files, plugins, LSP servers, logs |
| `nvim-headless.sh` | Headless validation for agent workflows       |

## References

### Skill References

- [switching-configs.md](references/switching-configs.md) - NVIM_APPNAME and nvim-config
- [lazyvim-architecture.md](references/lazyvim-architecture.md) - LazyVim structure and loading
- [plugin-patterns.md](references/plugin-patterns.md) - Common plugin configuration patterns
- [debugging-and-logs.md](references/debugging-and-logs.md) - Debugging techniques and log locations
- [headless-automation.md](references/headless-automation.md) - Non-interactive validation for agents
- [install-and-crash-recovery.md](references/install-and-crash-recovery.md) - Parser codesign, safe extras, native rebuilds

### External References

- [nvim-lazy/CLAUDE.md](file://~/.config/nvim-lazy/CLAUDE.md) - LazyVim config instructions
- [LazyVim Docs](https://lazyvim.github.io/) - Official LazyVim documentation
- [LazyVim Keymaps](https://www.lazyvim.org/keymaps) - Default keybindings
