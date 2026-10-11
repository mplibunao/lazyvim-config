# LazyVim Architecture

This document explains the architecture of LazyVim and how configurations are structured.

## Overview

LazyVim is a Neovim setup powered by lazy.nvim. It provides:

- Pre-configured plugins with sensible defaults
- Lazy-loading for fast startup
- Extensible through "extras"
- Easy customization without forking

## Directory Structure

```
~/.config/nvim-lazy/
├── init.lua              # Bootstrap lazy.nvim
├── lazyvim.json          # Enabled extras
├── lazy-lock.json        # Plugin version lockfile
├── stylua.toml           # Lua formatter config
├── lua/
│   ├── config/
│   │   ├── lazy.lua      # lazy.nvim setup
│   │   ├── options.lua   # Vim options
│   │   ├── keymaps.lua   # Custom keymaps
│   │   └── autocmds.lua  # Custom autocommands
│   └── plugins/
│       ├── disabled.lua  # Disabled plugins
│       ├── example.lua   # Example configurations
│       └── *.lua         # Custom plugin specs
```

## Loading Order

1. **init.lua** - Entry point, bootstraps lazy.nvim if not installed
2. **lua/config/lazy.lua** - Configures lazy.nvim and imports LazyVim
3. **lua/config/options.lua** - Sets vim options (before plugins load)
4. **Plugins load** - LazyVim core + extras + custom plugins
5. **lua/config/autocmds.lua** - Custom autocommands (VeryLazy event)
6. **lua/config/keymaps.lua** - Custom keymaps (VeryLazy event)

## Key Files Explained

### init.lua

Minimal bootstrap that:

1. Checks if lazy.nvim is installed
2. Clones it if missing
3. Calls `require("config.lazy")`

### lua/config/lazy.lua

Configures lazy.nvim with:

- Plugin spec location (`lua/plugins`)
- LazyVim import
- Performance settings
- Colorscheme fallbacks

```lua
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "plugins" },  -- Your plugins
  },
})
```

### lazyvim.json

Tracks which LazyVim "extras" are enabled:

```json
{
  "extras": [
    "lazyvim.plugins.extras.ai.copilot",
    "lazyvim.plugins.extras.lang.typescript"
  ]
}
```

Managed via `:LazyExtras` command or manual editing.

### lazy-lock.json

Lockfile with exact plugin versions. Used by `:Lazy restore` to ensure reproducible installs.

## Plugin Specification

Plugins are defined in `lua/plugins/*.lua` files. Each file returns a table of specs:

```lua
return {
  -- Simple plugin
  "author/plugin-name",

  -- Plugin with config
  {
    "author/plugin-name",
    opts = { ... },
    keys = { ... },
    event = "VeryLazy",
  },
}
```

### Spec Fields

| Field          | Purpose                            |
| -------------- | ---------------------------------- |
| `opts`         | Options passed to plugin's setup() |
| `keys`         | Lazy-load on keymap                |
| `event`        | Lazy-load on event                 |
| `ft`           | Lazy-load on filetype              |
| `cmd`          | Lazy-load on command               |
| `dependencies` | Required plugins                   |
| `config`       | Custom config function             |
| `init`         | Run before plugin loads            |
| `enabled`      | Boolean or function                |
| `priority`     | Load order (higher = earlier)      |

## Extras System

LazyVim extras are pre-configured plugin collections:

- **Lang extras**: Language support (typescript, python, etc.)
- **Editor extras**: Editor features (mini.files, telescope, etc.)
- **AI extras**: AI integrations (copilot, codeium, etc.)
- **Util extras**: Utilities (dot files, mini-hipatterns, etc.)

### Managing Extras

```vim
:LazyExtras           " Interactive picker
```

Or edit `lazyvim.json` directly.

### Current Enabled Extras

From the config's lazyvim.json:

- `lazyvim.plugins.extras.ai.copilot`
- `lazyvim.plugins.extras.editor.dial`
- `lazyvim.plugins.extras.editor.inc-rename`
- `lazyvim.plugins.extras.editor.mini-files`
- `lazyvim.plugins.extras.lang.json`
- `lazyvim.plugins.extras.lang.markdown`
- `lazyvim.plugins.extras.lang.toml`
- `lazyvim.plugins.extras.lang.typescript`
- `lazyvim.plugins.extras.util.dot`
- `lazyvim.plugins.extras.util.mini-hipatterns`

## Overriding LazyVim Defaults

### Override Plugin Options

```lua
return {
  "existing/plugin",
  opts = function(_, opts)
    -- Modify opts
    opts.new_option = true
    return opts
  end,
}
```

### Disable a Plugin

```lua
return {
  { "plugin/to-disable", enabled = false },
}
```

### Replace a Plugin

```lua
return {
  -- Disable original
  { "original/plugin", enabled = false },
  -- Add replacement
  { "replacement/plugin", ... },
}
```

## Events

LazyVim uses these key events:

| Event         | When                                        |
| ------------- | ------------------------------------------- |
| `VeryLazy`    | After UI loads (good for keymaps, autocmds) |
| `LazyFile`    | When a real file is opened                  |
| `BufReadPre`  | Before reading a buffer                     |
| `InsertEnter` | When entering insert mode                   |

## Leader Key

LazyVim uses `<Space>` as the leader key. Press Space and wait to see available bindings via which-key.

## Important Commands

| Command        | Purpose            |
| -------------- | ------------------ |
| `:Lazy`        | Plugin manager UI  |
| `:LazyExtras`  | Manage extras      |
| `:LazyHealth`  | Health check       |
| `:Mason`       | LSP server manager |
| `:checkhealth` | Full health check  |
