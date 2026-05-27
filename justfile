# nvim-lazy harness runner.
#
# Usage:
#   just check         — full gate, fail-fast (fmt → lint → docs → guard → prose → test → vet → nvim)
#   just install-hooks — set repo-local Git hooks to .githooks
#   just fmt           — format check only (stylua + gofmt)
#   just lint    — Selene Lua lint only
#   just docs    — deterministic docs coverage and local-link validation
#   just guard   — ast-grep structural guardrails
#   just prose   — Vale AI-tells and em-dash check over all tracked hand-authored Markdown
#   just nvim    — headless Neovim: config load + fixture filetypes + Nix invariants
#   just test    — Go tooling tests (scripts/)
#   just vet     — Go tooling vet (scripts/)
#
# Harness gate tools come from Nix Home Manager (Item 0); language-server ownership follows
# docs/design-docs/tooling-policy.md, where Mason still owns selected language helpers.
# If selene, stylua, vale, or just are absent, activate your Nix profile first.

# Full gate: format → lint → docs → guard → prose → Go tests/vet → headless nvim. Fail-fast.
check: fmt lint docs guard prose test vet nvim

# Install repo-local hooks. This writes only .git/config, never global Git config.
install-hooks:
    @test -f .githooks/pre-commit || { printf 'Missing .githooks/pre-commit; refusing to install hooks.\n' >&2; exit 1; }
    @test -x .githooks/pre-commit || { printf '.githooks/pre-commit is not executable; run chmod +x .githooks/pre-commit.\n' >&2; exit 1; }
    git config --local core.hooksPath .githooks
    @printf 'Git hooks installed: core.hooksPath=%s\n' "$(git config --local core.hooksPath)"

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

# Docs validation: hand-authored docs are indexed, and local Markdown links resolve.
docs:
    cd scripts && go run .

# Guardrails: ast-grep structural checks for repo invariants.
guard:
    sg scan --config guardrails/ast-grep/sgconfig.yml

# Prose: Vale over tracked hand-authored Markdown.
# Exact exclusions avoid generated/review output, legacy plans, fixtures, demos, and the AGENTS symlink.
# Rule policy lives in .vale.ini; --no-global makes it authoritative.
prose:
    #!/usr/bin/env sh
    set -e
    git ls-files -z -- '*.md' \
        ':(exclude)docs/reviews/**' \
        ':(exclude)docs/generated/**' \
        ':(exclude)exec-plans/active/**' \
        ':(exclude)exec-plans/completed/**' \
        ':(exclude)test-fixtures/**' \
        ':(exclude)test-preview.md' \
        ':(exclude)AGENTS.md' \
        | xargs -0 vale --no-global --minAlertLevel=error

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
