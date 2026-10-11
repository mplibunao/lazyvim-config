# Neovim Debugging and Logs

Comprehensive guide to debugging Neovim issues and finding logs.

## Quick Diagnostics

### Health Check

```vim
:checkhealth           " Full health check
:checkhealth lazy      " Just lazy.nvim
:checkhealth lsp       " Just LSP
:checkhealth treesitter
```

### Plugin Status

```vim
:Lazy                  " Plugin manager UI
:Lazy health           " Plugin health
:Lazy profile          " Load times
:Lazy debug            " Debug info
```

### LSP Status

```vim
:LspInfo               " Active LSP clients
:LspLog                " Open LSP log
:Mason                 " LSP server manager
```

## Log Locations

| Log           | Location                                                                                           | Access          |
| ------------- | -------------------------------------------------------------------------------------------------- | --------------- |
| Neovim log    | `~/.local/state/$NVIM_APPNAME/log` (defaults to `~/.local/state/nvim/log`)                         | `:edit` or file |
| LSP log       | `~/.local/state/$NVIM_APPNAME/lsp.log` (defaults to `~/.local/state/nvim/lsp.log`)                 | `:LspLog`       |
| Mason log     | `~/.local/share/$NVIM_APPNAME/mason/mason.log` (defaults to `~/.local/share/nvim/mason/mason.log`) | file            |
| Lazy.nvim log | In-memory                                                                                          | `:Lazy log`     |
| Messages      | In-memory                                                                                          | `:messages`     |

### View Logs

```vim
" View message history
:messages

" View LSP log
:LspLog

" View in file
:edit ~/.local/state/nvim/lsp.log
```

### Tail Logs (Terminal)

```bash
# LSP log
tail -f ~/.local/state/${NVIM_APPNAME:-nvim}/lsp.log

# Mason log
tail -f ~/.local/share/${NVIM_APPNAME:-nvim}/mason/mason.log
```

## Startup Debugging

### Profile Startup Time

```bash
nvim --startuptime /tmp/startup.log
# Then examine:
sort -k2 -n /tmp/startup.log | tail -20
```

### Start Without Config

```bash
# No config at all
nvim -u NONE

# Minimal (no plugins, basic settings)
nvim --clean

# Specific config only
nvim -u ~/.config/nvim-lazy/init.lua
```

### Verbose Mode

```bash
# Verbose startup
nvim -V10/tmp/nvim-verbose.log
```

## Plugin Debugging

### Check if Plugin Loaded

```vim
:Lazy
" Look for the plugin, check status icon
```

### Force Reload

```vim
:Lazy reload plugin-name
```

### Check Plugin Spec

```lua
:lua vim.print(require("lazy.core.config").plugins["plugin-name"])
```

### Debug Plugin Load

```lua
-- Add to plugin spec temporarily
{
  "plugin-name",
  init = function()
    vim.notify("Plugin init", vim.log.levels.INFO)
  end,
  config = function(_, opts)
    vim.notify("Plugin config", vim.log.levels.INFO)
    require("plugin").setup(opts)
  end,
}
```

## LSP Debugging

### Check Client Status

```vim
:LspInfo
```

### Increase Log Level

```lua
-- In options.lua or init.lua
vim.lsp.set_log_level("debug")
```

### Check Server Installation

```vim
:Mason
" Look for the server, check install status
```

### Restart LSP

```vim
:LspRestart
```

### Test LSP Manually

```bash
# Check if server runs
~/.local/share/nvim/mason/bin/lua-language-server --version

# Check server logs
tail -f ~/.local/state/nvim/lsp.log
```

## Treesitter Debugging

### Check Parser Status

```vim
:TSInstallInfo
```

### Reinstall Parser

```vim
:TSInstall lua
:TSUpdate lua
```

### Check Highlights

```vim
:Inspect          " Show highlight groups at cursor
:InspectTree      " Show syntax tree
```

## Common Issues

### Plugin Not Loading

1. Check `:Lazy` for errors
2. Verify plugin spec syntax
3. Check `enabled = false` not set
4. Look for dependency issues

### LSP Not Starting

1. Check `:LspInfo` for attached clients
2. Verify server installed via `:Mason`
3. Check filetype: `:set ft?`
4. Look at `:LspLog` for errors

### Slow Startup

1. Run `:Lazy profile`
2. Check `--startuptime` output
3. Look for plugins without lazy-loading
4. Consider adding `event`, `ft`, or `cmd` to slow plugins

### Keymaps Not Working

1. Check `:map <key>` to see what's mapped
2. Look for conflicts with `:verbose map <key>`
3. Verify plugin loaded that provides the keymap

### Colorscheme Issues

1. Check `:colorscheme` for current
2. Verify colorscheme plugin loaded
3. Check termguicolors: `:set termguicolors?`

## Debugging Commands

```vim
" Show all mappings
:map

" Show specific mapping with source
:verbose map <leader>ff

" Show all options
:set all

" Show specific option with source
:verbose set tabstop?

" Show autocommands
:autocmd

" Show loaded scripts
:scriptnames

" Show registers
:registers

" Show marks
:marks

" Show variables
:let
```

## Lua Debugging

### Print Debugging

```lua
vim.notify("Debug message", vim.log.levels.INFO)
vim.print(some_table)  -- Pretty print
```

### Check Module Loaded

```lua
:lua print(package.loaded["module-name"] ~= nil)
```

### Reload Module

```lua
:lua package.loaded["module-name"] = nil
:lua require("module-name")
```

### Inspect Object

```lua
:lua vim.print(vim.api.nvim_get_current_buf())
:lua vim.print(vim.opt.tabstop:get())
```

## Error Investigation

### Check Last Error

```vim
:messages
```

### Enable More Verbose Errors

```lua
vim.o.verbose = 1  -- Or higher
```

### Catch Lua Errors

```lua
local ok, result = pcall(function()
  -- Code that might error
end)
if not ok then
  vim.notify("Error: " .. result, vim.log.levels.ERROR)
end
```
