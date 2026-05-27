# Workflows

## Quick validation

```bash
just check   # full gate, fail-fast; the justfile owns the current recipe sequence
just --list  # authoritative recipe list and available targeted checks
```

Tools come from Nix Home Manager. If `just` is missing, activate your Nix profile first (see `docs/design-docs/tooling-policy.md`).

Fresh clones should enable the repo-local Git hook once:

```bash
just install-hooks
```

The installed pre-commit hook delegates to `just check`, so manual and commit-time validation use the same gate.

---

## Targeting this config

This config uses `NVIM_APPNAME=nvim-lazy`. Always set this when launching Neovim programmatically so you hit this config instead of the default.

## Validation by change type

| Change type | What to check |
|---|---|
| `lua/config/*.lua` or `lua/plugins/*.lua` (existing plugins) | `just fmt` + `just nvim` |
| New/removed plugins or extras (any file) | `just nvim` + `:Lazy sync` + lockfile review |
| `lazyvim.json` changes | `just nvim` + `:Lazy sync` + lockfile review |
| Any tracked hand-authored Markdown | `just docs` + `just prose`; the justfile owns exact prose-scope exclusions. Manually spot-check claim accuracy against source files. |
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

---

## Manual debugging (ad hoc only)

The snippets below are for one-off investigation when `just check` output needs more context. The authoritative fixture list and exit-code harness are in `scripts/check-nvim.lua`.

### Verifying changes with tmux

tmux is the only reliable way for agents to test Neovim behavior interactively. Launch a detached session, run the check, capture the output:

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

For assertion patterns (filetype, LSP attach, linter wiring), `scripts/check-nvim.lua` is the
reference; `just nvim` runs the full harness and covers all current fixtures.
