# Headless Neovim Automation

Guide for running Neovim non-interactively, essential for agent workflows.

## Why Headless?

Agents often cannot:

- Access interactive terminals (tmux, GUI)
- Wait for user input
- See visual output

Headless mode lets agents:

- Validate configurations
- Run commands programmatically
- Check plugin status
- Profile performance

## Basic Headless Invocation

```bash
# Run command and quit
nvim --headless -c 'command' -c 'qa'

# Run Lua and quit
nvim --headless -c 'lua print("hello")' -c 'qa'

# Run multiple commands
nvim --headless -c 'cmd1' -c 'cmd2' -c 'qa'
```

### Key Flags

| Flag         | Purpose                     |
| ------------ | --------------------------- |
| `--headless` | No UI, minimal output       |
| `-c 'cmd'`   | Run ex command              |
| `-c 'qa'`    | Quit all (needed to exit)   |
| `-c 'qa!'`   | Force quit (ignore unsaved) |
| `--clean`    | Skip all config             |
| `-u NONE`    | No init files               |

## With NVIM_APPNAME

Test specific configurations:

```bash
# Use nvim-lazy config
NVIM_APPNAME=nvim-lazy nvim --headless -c 'lua print("ok")' -c 'qa'

# Use default config
NVIM_APPNAME=nvim nvim --headless -c 'checkhealth' -c 'qa'
```

## Common Validation Tasks

### Check Config Loads

```bash
nvim --headless -c 'lua print("CONFIG_OK")' -c 'qa'
# Success: prints "CONFIG_OK"
# Failure: prints error, exits non-zero
```

### Check Plugins Load

```bash
nvim --headless -c 'lua print(#require("lazy").plugins())' -c 'qa'
# Prints number of loaded plugins
```

### Sync Plugins

```bash
nvim --headless -c 'Lazy sync' -c 'qa'
```

### Run Health Check

```bash
nvim --headless -c 'checkhealth' -c 'qa' 2>&1 | head -100
```

### Profile Startup

```bash
nvim --startuptime /tmp/startup.log --headless -c 'qa'
sort -k2 -n /tmp/startup.log | tail -20
```

### Check LSP Servers

```bash
# List installed via Mason
ls ~/.local/share/${NVIM_APPNAME:-nvim}/mason/bin/

# Verify server works
~/.local/share/${NVIM_APPNAME:-nvim}/mason/bin/lua-language-server --version
```

## Capturing Output

### Stdout

```bash
output=$(nvim --headless -c 'lua print("result")' -c 'qa' 2>&1)
echo "$output"
```

### To File

```bash
nvim --headless -c 'redir > /tmp/out.txt' -c 'messages' -c 'redir END' -c 'qa'
cat /tmp/out.txt
```

### Error Handling

```bash
if nvim --headless -c 'lua error("test")' -c 'qa' 2>&1; then
  echo "Success"
else
  echo "Failed"
fi
```

## Lua Scripting

### Run Lua File

```bash
nvim --headless -l script.lua
```

### Inline Lua

```bash
nvim --headless -c 'lua <<EOF
local plugins = require("lazy").plugins()
print("Loaded " .. #plugins .. " plugins")
EOF' -c 'qa'
```

### Check Module Exists

```bash
nvim --headless -c 'lua print(pcall(require, "telescope"))' -c 'qa'
# true = module exists, false = not found
```

## Using nvim-headless.sh

The skill's helper script covers common tasks; run it from the repo root:

```bash
# Basic check
.agents/skills/neovim/scripts/nvim-headless.sh check lazy

# Check plugins
.agents/skills/neovim/scripts/nvim-headless.sh plugins lazy

# Profile startup
.agents/skills/neovim/scripts/nvim-headless.sh startup

# Run arbitrary command
.agents/skills/neovim/scripts/nvim-headless.sh cmd 'echo &runtimepath'

# Run Lua
.agents/skills/neovim/scripts/nvim-headless.sh lua 'print(vim.fn.stdpath("config"))'
```

## Automation Patterns

### Config Validation Pipeline

```bash
#!/bin/bash
set -e

echo "Checking config loads..."
NVIM_APPNAME=nvim-lazy nvim --headless -c 'qa'

echo "Checking plugins..."
NVIM_APPNAME=nvim-lazy nvim --headless -c 'Lazy sync' -c 'qa'

echo "Running health check..."
NVIM_APPNAME=nvim-lazy nvim --headless -c 'checkhealth' -c 'qa' 2>&1 | grep -E '(OK|ERROR|WARNING)'

echo "All checks passed"
```

### Plugin Update Script

```bash
#!/bin/bash
NVIM_APPNAME=nvim-lazy nvim --headless -c 'Lazy update' -c 'qa'
NVIM_APPNAME=nvim-lazy nvim --headless -c 'Lazy sync' -c 'qa'
```

### Extract Config Info

```bash
# Get colorscheme
nvim --headless -c 'lua print(vim.g.colors_name or "default")' -c 'qa' 2>&1

# Get leader key
nvim --headless -c 'lua print(vim.g.mapleader or "\\\\")' -c 'qa' 2>&1

# List loaded plugins
nvim --headless -c 'lua for k,_ in pairs(package.loaded) do print(k) end' -c 'qa' 2>&1
```

## Limitations

### What Headless Cannot Do

1. **Visual feedback** - No UI to see results
2. **Interactive commands** - `:Lazy` UI, `:Mason` browser
3. **User input** - Prompts, confirmations
4. **Full LSP testing** - Needs actual file buffers
5. **Telescope/picker** - Interactive pickers

### Workarounds

| Need               | Headless Alternative       |
| ------------------ | -------------------------- |
| See plugin status  | Check `lazy-lock.json`     |
| LSP testing        | Verify server binary works |
| Interactive config | Edit files directly        |
| Visual output      | Redirect to file/stdout    |

## When to Use tmux

Some tasks need interactivity:

- Debugging complex UI issues
- Testing keymaps visually
- Running interactive pickers
- Full LSP diagnostics with hover

For these, the validation ladder is:

1. Try headless first
2. If insufficient, use tmux + interactive Neovim
3. Document what couldn't be validated headlessly

## Exit Codes

| Code     | Meaning           |
| -------- | ----------------- |
| 0        | Success           |
| 1        | General error     |
| Non-zero | Command/Lua error |

Always check exit codes in scripts:

```bash
if ! nvim --headless -c 'lua require("nonexistent")' -c 'qa' 2>&1; then
  echo "Module not found"
fi
```
