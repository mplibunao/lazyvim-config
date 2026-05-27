# Workflows

## Quick validation

```bash
just check   # full gate: fmt → lint → test → vet → nvim (fail-fast)
just --list  # authoritative recipe list
```

Tools come from Nix Home Manager. If `just` is missing, activate your Nix profile first (see `docs/design-docs/tooling-policy.md`).

---

## Targeting this config

This config uses `NVIM_APPNAME=nvim-lazy`. Always set this when launching Neovim programmatically so you hit this config instead of the default.

## Verifying changes with tmux

tmux is the only reliable way for agents to test Neovim behavior. Launch a detached session, run the check, capture the output:

```bash
# Headless Lua check
tmux new-session -d -s nvim-check -x 120 -y 40 \
  "NVIM_APPNAME=nvim-lazy nvim --headless \
  -c '<lua commands>' 2>&1 | tee /tmp/nvim-check.log"

# Read output
tmux capture-pane -p -t nvim-check

# Clean up
tmux kill-session -t nvim-check
```

Use `vim.defer_fn` with a delay (e.g., 3000ms) to let plugins load before checking values.

## Validation by change type

| Change type | What to check |
|---|---|
| `lua/config/*.lua` or `lua/plugins/*.lua` (existing plugins) | `just fmt` + `just nvim` |
| New/removed plugins or extras (any file) | `just nvim` + `:Lazy sync` + lockfile review |
| `lazyvim.json` changes | `just nvim` + `:Lazy sync` + lockfile review |
| Markdown docs or routing files only (e.g. `docs/**`, `CLAUDE.md`, `ARCHITECTURE.md`, `exec-plans/**`) | Manually verify referenced paths exist and spot-check claims against source files (`just docs` lands in Item 4) |
| Interactive UI / plugin behavior | tmux-backed visual validation |

## Plugin update validation

After updating plugins (`:Lazy update`), validate that plugin chains still load using the fixtures in `test-fixtures/`. Always run `:TSUpdate` after any treesitter plugin update.

### Update clusters

Plugins form two coupled clusters. Keep each cluster internally consistent when doing partial updates:

- **LSP cluster**: `mason.nvim`, `mason-lspconfig.nvim`, `nvim-lspconfig`
- **Treesitter cluster**: `nvim-treesitter`, `nvim-treesitter-textobjects`, `render-markdown.nvim`, `neotest`, `neotest-golang`
- **Independent** (safe anytime): `copilot.lua`, `gitsigns.nvim`, `SchemaStore.nvim`

Updating `LazyVim` itself should trigger the full smoke-test path: it can change how all clusters are wired.

### Smoke-test checklist

Open each fixture and verify the relevant plugin chain loads:

| Fixture | What to check |
|---|---|
| `test-fixtures/go/math_test.go` | gopls attaches (`:LspInfo`), treesitter highlights, `<leader>tt` discovers `TestAdd` |
| `test-fixtures/kotlin/src/main/kotlin/Fixture.kt` | kotlin_language_server attaches, inlay hints visible |
| `test-fixtures/json/tsconfig.json` | JSON LSP attaches, completion offers `compilerOptions` fields (verifies JSON schema/completion works) |
| `test-fixtures/markdown/sample.md` | `render-markdown.nvim` renders headings and code blocks (this does not cover `markdown-preview.nvim` browser preview, so test that separately with `:MarkdownPreview` on any `.md` file if that plugin was updated) |
| `test-fixtures/nix/default.nix` | `nixd` attaches (NOT `nil_ls`) via `:LspInfo`, treesitter highlights, nvim-lint lists `statix` and `deadnix` for `nix`, and `<leader>cf` formats with `nixfmt` (confirm via `:ConformInfo`) |
| Any file (optional, requires auth) | Copilot suggestions appear (skip if not authenticated) |
| `:checkhealth` | General sweep for errors |

### Headless validation (ad hoc debugging)

These snippets are for one-off investigation. For routine validation, use `just check`. The authoritative fixture list and exit-code harness are in `scripts/check-nvim.lua`.

```bash
# Quick startup check: exits 0 if no errors
NVIM_APPNAME=nvim-lazy nvim --headless \
  -c "lua vim.defer_fn(function() vim.cmd('qa!') end, 5000)" \
  test-fixtures/go/math_test.go

# Check LSP attached to a fixture
tmux new-session -d -s nvim-check -x 120 -y 40 \
  "NVIM_APPNAME=nvim-lazy nvim \
  -c 'lua vim.defer_fn(function() \
    local clients = vim.lsp.get_clients({ bufnr = 0 }) \
    for _, c in ipairs(clients) do print(c.name) end \
    if #clients == 0 then print(\"NO LSP ATTACHED\") end \
    vim.cmd(\"qa!\") \
  end, 5000)' \
  test-fixtures/go/math_test.go 2>&1 | tee /tmp/nvim-check.log"
sleep 8 && tmux capture-pane -p -t nvim-check
tmux kill-session -t nvim-check 2>/dev/null
```

For the Nix fixture, confirm `nixd` (not `nil_ls`) attaches and that both linters are wired. Expect `lsp: nixd` and `linters: statix,deadnix`:

```bash
tmux new-session -d -s nvim-nix -x 120 -y 40 \
  "NVIM_APPNAME=nvim-lazy nvim \
  -c 'lua vim.defer_fn(function() \
    local names = {} \
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do names[#names+1] = c.name end \
    print(\"lsp: \" .. table.concat(names, \",\")) \
    print(\"linters: \" .. table.concat(require(\"lint\").linters_by_ft.nix or {}, \",\")) \
    vim.cmd(\"qa!\") \
  end, 5000)' \
  test-fixtures/nix/default.nix 2>&1 | tee /tmp/nvim-nix.log"
sleep 8 && tmux capture-pane -p -t nvim-nix
tmux kill-session -t nvim-nix 2>/dev/null
```

`nixd` only attaches on a machine where the Nix-provided binary is on PATH (see [tooling-policy.md](design-docs/tooling-policy.md)); without it the line reads `lsp:` empty, which is the expected degraded state, not a failure. The `nixfmt` formatter is best confirmed interactively with `:ConformInfo` or `<leader>cf` on the fixture.
