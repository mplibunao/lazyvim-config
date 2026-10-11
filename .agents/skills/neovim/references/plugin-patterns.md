# LazyVim Plugin Patterns

Common patterns for adding, configuring, and managing plugins in LazyVim.

## Adding a New Plugin

### Basic Plugin

```lua
-- lua/plugins/my-plugin.lua
return {
  "author/plugin-name",
}
```

### Plugin with Options

```lua
return {
  "author/plugin-name",
  opts = {
    setting = true,
    another = "value",
  },
}
```

### Plugin with Keymaps

```lua
return {
  "author/plugin-name",
  keys = {
    { "<leader>xx", "<cmd>PluginCommand<cr>", desc = "Run plugin" },
    { "<leader>xy", function() require("plugin").action() end, desc = "Action" },
  },
}
```

### Lazy-loaded Plugin

```lua
return {
  "author/plugin-name",
  event = "VeryLazy",  -- Load after UI
  -- or
  ft = { "lua", "python" },  -- Load for filetypes
  -- or
  cmd = { "PluginCommand" },  -- Load on command
}
```

### Plugin with Dependencies

```lua
return {
  "author/plugin-name",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  opts = { ... },
}
```

## Overriding LazyVim Plugins

### Merge Options

```lua
return {
  "LazyVim/plugin",
  opts = {
    -- These merge with defaults
    new_option = true,
  },
}
```

### Override Options Function

```lua
return {
  "LazyVim/plugin",
  opts = function(_, opts)
    -- Full control over opts
    opts.setting = "new value"
    table.insert(opts.list, "item")
    return opts
  end,
}
```

### Add to Existing Keys

```lua
return {
  "LazyVim/plugin",
  keys = {
    -- Add new keys (merges with existing)
    { "<leader>xx", "<cmd>NewCommand<cr>", desc = "New" },
  },
}
```

### Replace Keys Entirely

```lua
return {
  "LazyVim/plugin",
  keys = function()
    return {
      -- Only these keys, no defaults
      { "<leader>a", "<cmd>Only<cr>", desc = "Only this" },
    }
  end,
}
```

## Disabling Plugins

### Disable Single Plugin

```lua
-- lua/plugins/disabled.lua
return {
  { "plugin/to-disable", enabled = false },
}
```

### Disable Multiple Plugins

```lua
return {
  { "plugin-one", enabled = false },
  { "plugin-two", enabled = false },
  { "plugin-three", enabled = false },
}
```

### Conditional Disable

```lua
return {
  {
    "plugin-name",
    enabled = function()
      return vim.fn.has("mac") == 1
    end,
  },
}
```

## Config vs Opts

### opts (Preferred)

Most plugins use a `setup(opts)` pattern. Use `opts`:

```lua
return {
  "plugin",
  opts = {
    setting = true,
  },
}
```

### config (Full Control)

When you need to do more than call setup:

```lua
return {
  "plugin",
  config = function(_, opts)
    require("plugin").setup(opts)
    -- Additional setup
    vim.cmd("SomeCommand")
  end,
}
```

### init (Before Load)

Run before plugin loads (for vim settings):

```lua
return {
  "plugin",
  init = function()
    vim.g.plugin_setting = true
  end,
}
```

## Common Patterns

### Colorscheme Plugin

```lua
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,  -- Load first
  opts = {
    flavour = "mocha",
  },
}
```

### UI Plugin (Load After Start)

```lua
return {
  "nvim-tree/nvim-tree.lua",
  cmd = { "NvimTreeToggle", "NvimTreeFocus" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Explorer" },
  },
  opts = { ... },
}
```

### LSP Extension

```lua
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tsserver = {
        settings = {
          typescript = {
            inlayHints = { ... },
          },
        },
      },
    },
  },
}
```

### Treesitter Extension

```lua
return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    vim.list_extend(opts.ensure_installed, {
      "lua",
      "python",
      "rust",
    })
  end,
}
```

### Mason Extension

```lua
return {
  "williamboman/mason.nvim",
  opts = function(_, opts)
    vim.list_extend(opts.ensure_installed, {
      "stylua",
      "shellcheck",
      "prettier",
    })
  end,
}
```

## File Organization

### Single Plugin Per File

```
lua/plugins/
├── colorscheme.lua
├── telescope.lua
├── git.lua
└── lsp.lua
```

### Grouped by Category

```lua
-- lua/plugins/editor.lua
return {
  { "plugin-one", ... },
  { "plugin-two", ... },
}
```

### Current Structure

```
lua/plugins/
├── disabled.lua          # Disabled plugins
├── example.lua           # Examples (reference)
├── extend-mini-files.lua # mini.files customization
├── dashboard.lua         # Dashboard config
├── picker.lua            # Picker config
└── ...
```

## Debugging Plugin Issues

### Check if Plugin Loaded

```vim
:Lazy
```

Look for the plugin in the list. Check for errors.

### Check Plugin Load Time

```vim
:Lazy profile
```

### Force Reload Plugin

```vim
:Lazy reload plugin-name
```

### View Plugin Spec

```lua
:lua vim.print(require("lazy.core.config").plugins["plugin-name"])
```
