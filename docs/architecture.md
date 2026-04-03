# Architecture

## Load chain

```
init.lua
  → lua/config/lazy.lua        bootstraps lazy.nvim, calls require("lazy").setup()

Runtime load order:
  1. lua/config/options.lua     vim options (loaded before plugins)
  2. LazyVim/LazyVim            core distribution (lazyvim.plugins)
     + lua/plugins/*.lua        local plugin specs (merged into the plugin graph)
  3. lua/config/autocmds.lua    autocommands (loaded on VeryLazy event)
     lua/config/keymaps.lua     keymaps and user commands (loaded on VeryLazy event)
```

LazyVim extras are declared in `lazyvim.json` — that file is the canonical list.

## File ownership

| Path | Owns |
|---|---|
| `lua/config/lazy.lua` | lazy.nvim bootstrap, plugin graph wiring, defaults, performance settings |
| `lua/config/options.lua` | Editor-wide options, root detection patterns |
| `lua/config/autocmds.lua` | Cross-cutting event-driven behavior (global autocmds only) |
| `lua/config/keymaps.lua` | Global keymaps and user commands (`<leader>yp`, `:CopyCurrentFilePath`, etc.) |
| `lua/plugins/*.lua` | Plugin-specific overrides and feature modules (may include feature-local commands and autocmds in `init` when tightly coupled to the plugin, e.g., `picker.lua` commands, `kotlin.lua` autoformat autocmd) |
| `lazyvim.json` | Enabled LazyVim extras |
| `stylua.toml` | Lua formatting rules |
| `ktlint.editorconfig` | Kotlin formatting rules |

## Customization clusters

These are the main areas where this config diverges from stock LazyVim:

| Area | Primary file(s) |
|---|---|
| Navigation / explorer | `lua/plugins/navigation.lua` — disables Snacks explorer, uses mini.files |
| Picker / AI shortcuts | `lua/plugins/picker.lua` — Snacks picker config, `:WizyPrompts`, `:ClaudeToolkit` |
| Completion | `lua/plugins/completion.lua` — Tab/Shift-Tab for blink.cmp |
| Disabled plugins | `lua/plugins/disabled.lua` — bufferline.nvim |
| Go support | `lua/plugins/go.lua` + `docs/go.md` |
| Kotlin support | `lua/plugins/kotlin.lua` + `docs/kotlin.md` |
| Markdown preview | `lua/plugins/markdown-preview.lua` + `assets/` |
| Indentation | `lua/plugins/guess-indent.lua` |
