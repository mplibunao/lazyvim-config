# nvim-lazy harness runner.
#
# Usage:
#   just check   — full gate, fail-fast (fmt → lint → test → vet → nvim)
#   just fmt     — format check only (stylua + gofmt)
#   just lint    — Selene Lua lint only
#   just nvim    — headless Neovim: config load + fixture filetypes + Nix invariants
#   just test    — Go tooling tests (scripts/)
#   just vet     — Go tooling vet (scripts/)
#
# All tools come from Nix Home Manager (Item 0), never Mason.
# If selene, stylua, or just are absent, activate your Nix profile first.
# See docs/design-docs/tooling-policy.md.
#
# Recipes for docs (Item 4), guard (Item 5), and prose (Item 7) are
# reserved stubs; they land in later harness items.

# Full gate: format → lint → Go tests/vet → headless nvim. Fail-fast.
check: fmt lint test vet nvim

# Format check: stylua (Lua) and gofmt (Go tooling scripts). Does not modify files.
# To fix: stylua init.lua lua/ scripts/check-nvim.lua  OR  cd scripts && gofmt -w .
fmt:
    #!/usr/bin/env sh
    stylua --config-path stylua.toml --check init.lua lua/ scripts/check-nvim.lua || exit 1
    # Capture both stdout and exit code: gofmt exits non-zero on parse errors,
    # and exits 0 whether or not files need reformatting (check output instead).
    gofmt_out=$(cd scripts && gofmt -l . 2>&1)
    gofmt_exit=$?
    if [ "$gofmt_exit" -ne 0 ]; then
        printf 'gofmt: error (exit %d):\n%s\n' "$gofmt_exit" "$gofmt_out"
        exit 1
    fi
    if [ -n "$gofmt_out" ]; then
        printf 'gofmt: unformatted files:\n%s\nFix: cd scripts && gofmt -w .\n' "$gofmt_out"
        exit 1
    fi

# Lint: Selene over init.lua and all lua/ files.
# Globals covered: vim.* (built-in vim std), LazyVim.* + Snacks.* (lazyvim_extras.toml).
lint:
    selene --config selene.toml init.lua lua/

# Headless Neovim: config load + per-fixture filetype assertions + Nix invariants.
# Optional LSP checks skip gracefully when the binary is absent (tooling-policy.md).
# Driven by scripts/check-nvim.lua; replaces the inline snippets in docs/workflows.md.
nvim:
    NVIM_APPNAME=nvim-lazy nvim --headless -c "luafile scripts/check-nvim.lua"

# Go tests for tooling scripts (scripts/).
test:
    cd scripts && go test ./...

# Go vet for tooling scripts (scripts/).
vet:
    cd scripts && go vet ./...
