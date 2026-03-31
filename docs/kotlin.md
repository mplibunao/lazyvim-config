# Kotlin

## Auto-format

Disabled on save via `lua/config/autocmds.lua` (sets `vim.b.autoformat = false` for Kotlin buffers). LazyVim's Kotlin extra uses `ktlint` as the formatter (via conform.nvim), but the project doesn't have consistent formatting — auto-format causes noisy diffs on untouched lines.

Manual format is still available with `<leader>cf`.

## Linting (ktlint)

LazyVim's Kotlin extra also sets up `ktlint` as a linter (via nvim-lint). It runs with its default ruleset, which can be noisy on projects without a ktlint config.

### Disabling rules globally

Rules are configured in `ktlint.editorconfig` (repo root). The `--editorconfig` flag in `lua/plugins/kotlin.lua` tells ktlint to use this file, overriding any project-level `.editorconfig`.

To disable a rule, add a line:

```ini
[*.{kt,kts}]
ktlint_standard_<rule-name> = disabled
```

### Finding the rule name

The diagnostic message in Neovim shows the rule ID in brackets, e.g. `[standard:indent]` maps to `ktlint_standard_indent`.

### Commonly disabled rules

| Rule | editorconfig key |
|------|-----------------|
| Indentation | `ktlint_standard_indent` |
| Wildcard imports | `ktlint_standard_no-wildcard-imports` |
| Max line length | `ktlint_standard_max-line-length` |
| Trailing comma (call site) | `ktlint_standard_trailing-comma-on-call-site` |
| Trailing comma (declaration) | `ktlint_standard_trailing-comma-on-declaration-site` |

## LSP settings

Configured in `lua/plugins/kotlin.lua`. Uses `kotlin-language-server` (not the official `kotlin-lsp` which is still pre-alpha).

- **JVM target:** Set to `17` — change if your project targets a different version
- **Inlay hints:** Parameter hints and type hints enabled as a learning aid while ramping up on Kotlin. Disable `typeHints` later if they become noisy

### Switching JVM target

Edit `lua/plugins/kotlin.lua` and change `target = "17"` to match your project (e.g., `"21"`).

## Debugging (DAP)

Requires `dap.core` extra (enabled in `lazyvim.json`) and `kotlin-debug-adapter` (auto-installed via Mason).

LazyVim's Kotlin extra provides two DAP configs:
- **"Kotlin: This file"** — run/debug the current file
- **"Kotlin: Attach"** — attach to a running JVM debug port

### Debugging tests with Maven

```bash
# Start Maven with debug port open (default: 8000)
mvnDebug test
# or with surefire
mvn -Dmaven.surefire.debug test
```

Then in Neovim: `<leader>dc` (continue/start) → select "Kotlin: Attach" from the config picker → connect to port 5005 (or 8000 for `mvnDebug`).

## Useful keymaps

| Key | Action |
|-----|--------|
| `<leader>cf` | Manual format (since auto-format is disabled) |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue / start (shows config picker on first run) |
| `<leader>da` | Run with args |
| `<leader>du` | DAP UI |
| `<leader>cc` / `<leader>cC` | Code lens run / run all |
