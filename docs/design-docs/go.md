# Go

## Formatting

Configured in `lua/plugins/go.lua` via conform.nvim. Runs two formatters sequentially on save:

1. **goimports**: fixes import statements (adds missing, removes unused) and formats in `gofmt` style
2. **gofumpt**: stricter, backwards-compatible `gofmt` replacement (enforces extra style rules like grouping imports)

Both are auto-installed via Mason.

## Linting

Uses `golangci-lint` via nvim-lint. This is an umbrella linter that runs multiple Go linters in a single pass.

Lint policy should live in the project's `.golangci.yml`, not in Neovim config. `golangci-lint` searches upward for config files automatically.

## Testing (neotest-golang)

Requires `test.core` extra (enabled in `lazyvim.json`).

**Prerequisite:** `gotestsum` must be installed and on PATH. It's managed via nix (`nix/home/mp/packages/tier2.nix`), not Mason.

Configured with:
- **`gotestsum`** as the runner: solves known `go test -json` stdout interleaving issues
- **`dap_go_enabled = true`**: allows debugging tests via `<leader>td`
- **`go_test_args = { "-v", "-race", "-count=1" }`** (verbose output, race detection, no caching)

### Test keymaps

| Key | Action |
|-----|--------|
| `<leader>tr` | Run nearest test |
| `<leader>tt` | Run current file |
| `<leader>tl` | Run last test |
| `<leader>td` | Debug nearest test (uses Delve) |
| `<leader>ts` | Test summary |
| `<leader>to` / `<leader>tO` | Show test output |

## Debugging (DAP)

Uses `nvim-dap-go` + Delve (auto-installed via Mason). LazyVim's Go extra handles the DAP adapter setup.

| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue |
| `<leader>de` | Eval expression |
| `<leader>du` | DAP UI |

## LSP (gopls)

LazyVim's Go extra configures gopls with good defaults (gofumpt, staticcheck, analyses, inlay hints, code lenses, semantic tokens).

One additional setting in `lua/plugins/go.lua`:
- **`vulncheck = "Imports"`**: lightweight always-on vulnerability diagnostics against your imports

The `gopls` binary comes from Nix Home Manager (the dotfiles flake's
`nix/home/mp/packages/tier2.nix`), not Mason. The
`mason = false` setting in `lua/plugins/go.lua` fences it so Mason cannot install
a duplicate. See [tooling-policy.md](tooling-policy.md).

### Code lenses

gopls provides code lenses for `test`, `generate`, `tidy`, `upgrade_dependency`, and `run_govulncheck`. Use `<leader>cc` / `<leader>cC` to run them.

### Tuning for large repos

If gopls feels slow, consider adding to the gopls settings in `lua/plugins/go.lua`:

```lua
diagnosticsTrigger = "Save",  -- only run diagnostics on save
semanticTokens = false,       -- reduces type-checking latency
```
