# Install and Crash Recovery

Procedures for the three install-time situations that crash or break nvim on macOS, plus the lazy.nvim commands they use.

## Plugin Management Commands

```vim
:Lazy               " Open lazy.nvim UI
:Lazy sync          " Install, update and clean plugins
:Lazy update        " Update plugins
:Lazy restore       " Restore plugins from lockfile
:Lazy build <name>  " Force rebuild plugin (native binaries)
:Lazy check         " Check for updates
:Lazy clean         " Remove unused plugins
```

## Treesitter Parser Codesign (macOS)

After `:TSUpdate`, `:TSInstall`, or any treesitter parser recompilation, the `.so` files need re-signing or macOS kills nvim with `SIGKILL (Code Signature Invalid)`:

```bash
for f in ~/.local/share/nvim-lazy/site/parser/*.so; do codesign -f -s - "$f"; done
```

**Symptom:** nvim crashes when loading treesitter parsers (e.g., opening Lazy UI, opening files with syntax highlighting). Crash reports in `~/Library/Logs/DiagnosticReports/` show `CODESIGNING / Invalid Page` with `add_language` in the stack trace.

**Always re-sign after installing/updating parsers.**

## Enabling LazyVim Extras Safely

Enabling extras via `:LazyExtras` writes to `lazyvim.json` but does NOT install plugins in the same step. If nvim restarts before plugins are installed, it crashes on next launch.

**Safe approach from the terminal:**

```bash
# 1. Edit lazyvim.json (add the extra)
# 2. Sync plugins headlessly
NVIM_APPNAME=nvim-lazy nvim --headless -c 'lua require("lazy").sync({wait=true})' -c 'qa'
# 3. Install new treesitter parsers if needed
NVIM_APPNAME=nvim-lazy nvim --headless -c 'TSInstall <lang>' -c 'sleep 30' -c 'qa'
# 4. Re-sign parsers
for f in ~/.local/share/nvim-lazy/site/parser/*.so; do codesign -f -s - "$f"; done
```

**Recovery if nvim won't start:** edit `~/.config/nvim-lazy/lazyvim.json` with `nvim --clean` to remove the problematic extra.

## Native Plugin Builds

Some plugins (e.g., `markdown-preview.nvim`, `blink.cmp`) have native binaries. After migrating to a new machine or architecture:

```bash
# Force rebuild all plugins with build steps
NVIM_APPNAME=nvim-lazy nvim -c 'Lazy build' -c 'qa'
```

**Why:** `Lazy restore` skips builds if plugins aren't "dirty" (no git changes). Use `Lazy build` to force rebuilds.
