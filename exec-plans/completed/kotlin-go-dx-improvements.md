# Kotlin & Go DX Improvements

Synthesized from two oracle consultations (2026-04-01). Goal: make LazyVim work well for daily Kotlin and Go development with minimal config additions.

## Context

- MP is new to Kotlin/JVM, experienced with Go
- Project uses **Maven** (not Gradle)
- Kotlin auto-format is intentionally disabled (project lacks consistent formatting)
- Config philosophy: minimal, practical, small-file overrides

## Nix dependencies

~~`gotestsum` is NOT available in Mason and needs to be installed via nix. All other tools are installed via Mason.~~

> ~~**Action required:** MP to provide nix installation instructions for `gotestsum` before Step 3.~~

**Done** (2026-04-01): Added `gotestsum` to `nix/home/mp/packages/tier2.nix`, built and switched.

## Steps

### ~~Step 1: Enable `dap.core` and `test.core` extras~~ DONE

Added to `lazyvim.json`:
- `lazyvim.plugins.extras.dap.core`
- `lazyvim.plugins.extras.test.core`

**Files:** `lazyvim.json`

---

### ~~Step 2: Create `lua/plugins/go.lua`~~ DONE

Created with Mason tools, conform (goimports + gofumpt), nvim-lint (golangcilint), neotest-golang (gotestsum + dap), and gopls vulncheck.

**Files:** `lua/plugins/go.lua`

---

### ~~Step 3: Add treesitter selection textobjects~~ SKIPPED

LazyVim's `mini.ai` already provides `af/if`, `ac/ic`, `aa/ia` textobjects. Adding treesitter-textobjects would shadow them. Caught in code review.

---

### ~~Step 4: Configure `kotlin-language-server` settings~~ DONE

Added JVM target (17), inlay hints (parameter + type), and Mason ensure_installed for kotlin-debug-adapter.

> **Note:** Confirm JVM target matches your project. Change `target = "17"` in `lua/plugins/kotlin.lua` if needed.

**Files:** `lua/plugins/kotlin.lua`

---

### ~~Step 5: Update `docs/kotlin.md`~~ DONE

Added LSP settings, Maven DAP workflow, and keymap reference.

**Files:** `docs/kotlin.md`

---

### ~~Step 6: Create `docs/go.md`~~ DONE

Documented formatting, linting, testing (gotestsum), DAP, and gopls settings.

**Files:** `docs/go.md`

---

## Decisions log

| Decision | Rationale |
|----------|-----------|
| Skip `editor.refactoring` extra | `refactoring.nvim` supports Go but not Kotlin — creates asymmetry |
| Skip `overseer` | Adds complexity; terminal (`<leader>ft`) is sufficient for Maven commands |
| Skip `lang.java` extra | Unnecessary for pure Kotlin projects |
| Skip official `kotlin-lsp` | Still pre-alpha, not recommended for daily use yet |
| Use textobjects over refactoring.nvim | Language-agnostic, works for both Go and Kotlin, composes with Vim grammar |
| `gotestsum` over raw `go test` | Solves known `go test -json` stdout interleaving issues in neotest |
| Inlay hints for Kotlin | Learning aid — can disable later once comfortable with the language |
