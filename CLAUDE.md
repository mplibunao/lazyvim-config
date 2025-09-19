# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a LazyVim configuration repository - a modern Neovim setup built on the LazyVim distribution. LazyVim provides a pre-configured Neovim experience with lazy-loading plugins, LSP support, and modern development features.

## Architecture

### Configuration Loading Order

1. `init.lua` - Bootstraps lazy.nvim and loads the configuration
2. `lua/config/lazy.lua` - Sets up lazy.nvim plugin manager and loads LazyVim
3. `lua/config/options.lua` - Custom vim options (loaded before plugins)
4. `lua/config/autocmds.lua` - Custom autocommands (loaded on VeryLazy event)
5. `lua/config/keymaps.lua` - Custom keymaps (loaded on VeryLazy event)
6. `lua/plugins/*.lua` - Plugin specifications automatically loaded by lazy.nvim

### Key Directories

- `lua/config/` - Core configuration files (options, keymaps, autocmds, lazy setup)
- `lua/plugins/` - Plugin specifications and overrides
- `lazyvim.json` - LazyVim extras configuration

## Common Development Commands

### Plugin Management

```vim
:Lazy               " Open lazy.nvim UI
:Lazy sync          " Install, update and clean plugins
:Lazy update        " Update plugins
:Lazy install       " Install missing plugins
:Lazy clean         " Clean unused plugins
:Lazy check         " Check for plugin updates
:Lazy restore       " Restore plugins from lockfile
```

### LazyVim Commands

```vim
:LazyExtras         " Manage LazyVim extras
:LazyHealth         " Check LazyVim health
:LazyFormat         " Format current buffer
:LazyRoot           " Change to project root
```

### LSP Commands (via LazyVim)

```vim
<leader>cl          " LSP info
<leader>cd          " Line diagnostics
<leader>ca          " Code action
<leader>cf          " Format buffer
<leader>cr          " Rename symbol
gd                  " Go to definition
gr                  " Go to references
K                   " Hover documentation
```

## LazyVim Extras Configuration

Currently enabled extras (from `lazyvim.json`):

- **AI**: Copilot integration
- **Editor**: dial.nvim, inc-rename, mini.files
- **Language Support**: JSON, Markdown, TOML, TypeScript
- **Utilities**: dot files support, mini.hipatterns

To add more extras:

1. Run `:LazyExtras` to see available extras
2. Select extras to enable/disable
3. Changes are saved to `lazyvim.json`

## Plugin Configuration

### Adding Custom Plugins

Create a new file in `lua/plugins/` or add to an existing file:

```lua
return {
  "author/plugin-name",
  opts = {
    -- plugin options
  },
  keys = {
    { "<leader>key", "<cmd>Command<cr>", desc = "Description" },
  },
}
```

### Overriding LazyVim Plugins

```lua
return {
  "existing/plugin",
  opts = function(_, opts)
    -- Modify opts table
    opts.new_option = true
    return opts
  end,
}
```

### Disabling LazyVim Plugins

Add to `lua/plugins/disabled.lua`:

```lua
return {
  { "plugin/to-disable", enabled = false },
}
```

## Current Customizations

### Disabled Plugins

- `bufferline.nvim` - Tab/buffer line disabled

### Extended Plugins

- `mini.files` - Custom keymaps added (<leader>e, <leader>E, <leader>fm)

### Plugin Examples

The `lua/plugins/example.lua` file (currently disabled) contains comprehensive examples for:

- Adding new plugins
- Configuring colorschemes
- Overriding plugin options
- Setting up LSP servers
- Configuring Treesitter parsers

## Code Style

### Lua Formatting

Configured via `stylua.toml`:

- Indent: 2 spaces
- Column width: 120 characters
- Use `stylua` for formatting Lua files

### File Conventions

- Plugin specs go in `lua/plugins/*.lua`
- Each file in `lua/plugins/` should return a table of plugin specs
- Use descriptive filenames for plugin configurations
- Follow LazyVim's configuration patterns

## Development Workflow

When modifying this configuration:

1. **Adding plugins**: Create new file in `lua/plugins/` or add to existing
2. **Changing options**: Edit `lua/config/options.lua`
3. **Adding keymaps**: Edit `lua/config/keymaps.lua`
4. **Adding autocmds**: Edit `lua/config/autocmds.lua`
5. **Managing LazyVim extras**: Use `:LazyExtras` command

### Testing Changes

1. Save the file
2. Run `:Lazy sync` if adding new plugins
3. Restart Neovim or run `:source %` for config changes
4. Check `:Lazy` UI for any load errors

## Important Settings

### lazy.nvim Configuration

- Plugins are NOT lazy-loaded by default (`lazy = false`)
- Version pinning disabled (`version = false`)
- Auto-check for updates enabled with notifications disabled
- Colorscheme fallbacks: tokyonight, habamax

### Performance Optimizations

Disabled vim plugins:

- gzip, tarPlugin, tohtml, tutor, zipPlugin

## Dependencies

LazyVim automatically installs most dependencies, but ensure you have:

- Neovim >= 0.9.0
- Git (for plugin installation)
- A Nerd Font (for icons)
- ripgrep (for telescope grep)
- fd (for telescope file finding)
- Language servers for your languages (auto-installed via Mason)

## Working with this Config

### Quick Tips

- LazyVim uses `<Space>` as the leader key by default
- Press `<Space>` and wait to see available keybindings
- Use `:Lazy` to manage plugins visually
- Check `:checkhealth` for any issues
- The config is minimal by design - add only what you need

### Extending Functionality

1. Browse available LazyVim extras: `:LazyExtras`
2. Check LazyVim documentation: <https://lazyvim.github.io/>
3. Look at `lua/plugins/example.lua` for configuration patterns
4. Keep customizations modular in separate files under `lua/plugins/`

## References

- <https://www.lazyvim.org/plugins> LazyVim plugins
- <https://www.lazyvim.org/keymaps> - LazyVim keymaps

Do not read the files in references unless told explicitly to
