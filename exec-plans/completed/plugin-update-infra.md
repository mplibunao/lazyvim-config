# Plugin Update Infrastructure

Synthesized from two oracle consultations (2026-04-03). Goal: safely update all pending plugins and establish reusable validation infrastructure for future updates.

## Context

- Neovim 0.11.6 currently installed via Nix (Home Manager)
- Nvim 0.12.0 already available in nixpkgs channel — just needs rebuild
- `nvim-treesitter` dropped 0.11 support (`feat!: drop support for Nvim 0.11`)
- LazyVim v15.15.0 added an 0.11 treesitter compatibility pin, but lockfile is at v15.14.0
- `neotest-golang` v2+ requires treesitter `main` branch parsers (not frozen `master`)
- Config has no local treesitter queries or version pins — all risk comes from upstream

## Key decisions from oracle analysis

| Decision | Rationale |
|---|---|
| Upgrade Neovim to 0.12 rather than pin treesitter | Removes the compatibility problem entirely; no workaround maintenance |
| Don't pin treesitter to frozen `master` | `neotest-golang` v2+ expects `main` branch parsers — `master` breaks Go test discovery |
| Update LazyVim together with plugins | Current lock (v15.14.0) predates the 0.11 treesitter guard; updating LazyVim alone would also work as fallback |
| Add test fixtures to repo | Makes future plugin updates verifiable by agents without needing a real project |
| Extend `workflows.md`, not new doc | Test fixtures are validation targets — fits existing "validation by change type" pattern |

## Plugin update clusters

Plugins aren't independent — they form two clusters that should be updated as units:

**LSP cluster** (safe to update independently):
- `mason.nvim`, `mason-lspconfig.nvim`, `nvim-lspconfig`

**Treesitter cluster** (coupled — keep consistent):
- `nvim-treesitter`, `nvim-treesitter-textobjects`, `render-markdown.nvim`, `neotest`, `neotest-golang`

**Independent** (safe anytime):
- `copilot.lua`, `gitsigns.nvim`, `SchemaStore.nvim`

Updating `LazyVim` itself should trigger the full smoke-test path — it can change how all clusters are wired.

## Steps

### ~~Step 1: Upgrade Neovim to 0.12~~ DONE

Rebuild Nix to pick up 0.12.0 from nixpkgs. No config changes needed — `neovim.nix` doesn't pin a version.

> Also fixed: `nodePackages` removed from nixpkgs — replaced `nodePackages.typescript-language-server`, `nodePackages.vscode-langservers-extracted`, `nodePackages.prettier` with top-level equivalents in `neovim.nix`.

```bash
darwin-rebuild switch \
    --flake ~/Projects/personal/dotfiles
```

Verify: `nvim --version | head -1` shows `NVIM v0.12.0`.

**Fallback:** If 0.12 causes issues, revert the rebuild and instead update LazyVim to v15.15.0+ (which pins treesitter for 0.11 users).

**Files:** none in this repo

---

### ~~Step 2: Create test fixtures~~ DONE

Minimal project scaffolds — just enough to trigger each plugin chain. Each fixture needs a valid project root so LSP/tooling attaches.

```
test-fixtures/
├── go/
│   ├── go.mod
│   └── math_test.go
├── kotlin/
│   ├── build.gradle.kts
│   └── src/main/kotlin/Fixture.kt
├── json/
│   └── tsconfig.json
├── markdown/
│   └── sample.md
└── README.md
```

Fixture requirements:
- **Go**: `go.mod` with module declaration + one `func TestXxx` — exercises treesitter parse + neotest discovery
- **Kotlin**: `build.gradle.kts` with kotlin jvm plugin + one `.kt` file — exercises root detection (`options.lua` root_spec) + KLS attach
- **JSON**: `tsconfig.json` — triggers SchemaStore schema association for completion
- **Markdown**: headings + code block — triggers `render-markdown.nvim` rendering

**Files:** `test-fixtures/**`

---

### ~~Step 3: Extend `workflows.md` with fixture-based validation~~ DONE

Add a section documenting:
- What the fixtures validate (LSP attach, treesitter parse, neotest discovery, schema completion, markdown rendering)
- How to run validation after plugin updates (manual and headless/tmux)
- The smoke-test checklist: Go test discovery, Kotlin LSP attach, JSON schema completion, markdown rendering, Copilot startup, `:checkhealth`

Frame as "Plugin update validation" — a specific case of the existing validation workflow, not a separate concept.

**Files:** `docs/workflows.md`

---

### ~~Step 4: Update all plugins~~ DONE

With Neovim 0.12 in place, update everything at once in Lazy:

1. Open nvim, `:Lazy`, update all
2. `:TSUpdate` (required after treesitter plugin updates)
3. Run smoke tests against fixtures
4. `:checkhealth` for general sweep
5. Commit updated `lazy-lock.json`

**Files:** `lazy-lock.json`

---

### ~~Step 5: Add fixture validation entry to CLAUDE.md workflow table~~ DONE

Add a row to the "Where to read" table in CLAUDE.md pointing to the new workflows.md section, so agents know to use fixtures after plugin changes.

**Files:** `CLAUDE.md`

---

## Post-completion notes

After this plan is done, future plugin updates follow a repeatable process:
1. Check if Neovim version meets plugin requirements
2. `:Lazy update` (all, or by cluster if cautious)
3. `:TSUpdate`
4. Open each fixture, verify plugin chain loads
5. `:checkhealth`
6. Commit lockfile
