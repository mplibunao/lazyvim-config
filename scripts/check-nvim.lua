-- scripts/check-nvim.lua
-- Headless Neovim validation: config load, per-fixture filetypes, and the
-- Nix-specific invariants declared in lua/plugins/nix.lua.
--
-- Run via `just nvim` (or directly):
--   cd <repo> && NVIM_APPNAME=nvim-lazy nvim --headless \
--       -c "luafile scripts/check-nvim.lua"
--
-- Fixture table contract:
--   path              string   — path relative to repo root
--   filetype          string   — expected vim filetype after opening
--   optional_lsp?     table    — { client, binary, timeout_ms?, settle_ms? }
--                                Skip the attach check when binary is absent
--                                (graceful degradation; see tooling-policy.md).
--                                timeout_ms: positive client attach wait (default LSP_TIMEOUT_MS).
--                                settle_ms: after_lsp_settle window when binary absent
--                                (default timeout_ms). Keeps attach and settle concepts separate.
--   before_lsp?       fn(buf)  — called after filetype check, before any LSP wait
--   after_lsp_settle? fn(buf)  — invoked by run_lsp_phase after the settle window
--                                (after attach completes, or after settle_ms when
--                                binary is absent). Caller does not invoke directly.
--
-- Exit behaviour: cquit 1 on any failure, timeout, or deferred crash;
--                 qall! only when all checks passed and done was set.

local LSP_TIMEOUT_MS = 8000
-- Startup delay gives lazy.nvim enough time to complete its initialisation
-- phase before any fixture is opened. Mirrors the defer used in the manual
-- snippets in docs/workflows.md.
local STARTUP_DELAY_MS = 3000

-- ---------------------------------------------------------------------------
-- Output helpers
-- ---------------------------------------------------------------------------

local failures = {}

local function fail(msg)
  io.stderr:write("FAIL: " .. msg .. "\n")
  table.insert(failures, msg)
end

local function skip(msg)
  io.write("skip: " .. msg .. "\n")
end

local function ok(msg)
  io.write("ok:   " .. msg .. "\n")
end

-- ---------------------------------------------------------------------------
-- Nix fixture callbacks
-- ---------------------------------------------------------------------------

-- Synchronous linter-config assertions from lua/plugins/nix.lua.
-- Called via before_lsp: linters_by_ft is configured during plugin setup,
-- before any file is opened, so no wait is needed.
local function check_nix_linters(buf)
  local lint_ok, lint = pcall(require, "lint")
  if not lint_ok then
    fail("nix_invariants: nvim-lint not loaded — require('lint') failed")
    return
  end

  local linters = lint.linters_by_ft.nix or {}
  for _, expected in ipairs({ "statix", "deadnix" }) do
    if not vim.tbl_contains(linters, expected) then
      fail(
        ("nix_invariants: linters_by_ft.nix missing %q — check deadnix wiring in lua/plugins/nix.lua"):format(
          expected
        )
      )
    else
      ok(("nix_invariants: linters_by_ft.nix has %s"):format(expected))
    end
  end
end

-- Negative nil_ls assertion from lua/plugins/nix.lua (nil_ls = { enabled = false }).
-- Called via after_lsp_settle: must run after the full LSP settle window so a
-- delayed nil_ls attach is not missed. A 500 ms pre-check was insufficient.
local function check_nil_ls_absent(buf)
  local nil_ls_clients = vim.lsp.get_clients({ bufnr = buf, name = "nil_ls" })
  if #nil_ls_clients > 0 then
    fail(
      "nix_invariants: nil_ls is attached — expected disabled (nil_ls = { enabled = false } in lua/plugins/nix.lua)"
    )
  else
    ok("nix_invariants: nil_ls not attached")
  end
end

-- ---------------------------------------------------------------------------
-- Fixture table
-- ---------------------------------------------------------------------------

local fixtures = {
  {
    path = "test-fixtures/go/math_test.go",
    filetype = "go",
    optional_lsp = { client = "gopls", binary = "gopls" },
  },
  {
    path = "test-fixtures/kotlin/src/main/kotlin/Fixture.kt",
    filetype = "kotlin",
    -- kotlin_language_server is Mason-managed (predates the Nix policy) and its
    -- Mason-installed binary is visible to nvim but not to the shell. The server
    -- has known crash bugs in some Mason versions. Asserting attach here would
    -- gate just check on Mason LSP health rather than this repo's config
    -- invariants, so we test filetype only.
  },
  {
    -- LazyVim maps tsconfig*.json → jsonc via Neovim's built-in filetype.lua.
    path = "test-fixtures/json/tsconfig.json",
    filetype = "jsonc",
  },
  {
    path = "test-fixtures/markdown/sample.md",
    filetype = "markdown",
  },
  {
    path = "test-fixtures/nix/default.nix",
    filetype = "nix",
    -- nixd evaluates flake expressions (lua/plugins/nix.lua: darwin_expr) which
    -- take longer to start than gopls. 20 s gives the server enough headroom in
    -- headless mode; the default 8 s was not sufficient in practice.
    optional_lsp = { client = "nixd", binary = "nixd", timeout_ms = 20000 },
    before_lsp = check_nix_linters,
    after_lsp_settle = check_nil_ls_absent,
  },
}

-- ---------------------------------------------------------------------------
-- Generic LSP phase runner
-- ---------------------------------------------------------------------------

-- Runs the complete LSP phase for a fixture: optional client attach wait
-- (or graceful skip when binary absent), then after_lsp_settle callback.
--
-- Owning both the wait and the callback here makes the timing contract
-- unambiguous: after_lsp_settle always observes the settle window regardless
-- of whether the binary was present or absent. The caller invokes
-- run_lsp_phase once and the full LSP concern is handled.
local function run_lsp_phase(buf, fixture)
  if fixture.optional_lsp then
    local binary = fixture.optional_lsp.binary
    local client = fixture.optional_lsp.client
    local timeout = fixture.optional_lsp.timeout_ms or LSP_TIMEOUT_MS
    -- settle_ms is the after_lsp_settle window; defaults to timeout_ms so
    -- current fixtures need no change, but callers can tune independently.
    local settle = fixture.optional_lsp.settle_ms or timeout

    if vim.fn.executable(binary) == 0 then
      skip(("%s: LSP %s (binary %q not on PATH)"):format(fixture.path, client, binary))

      -- Settle window for after_lsp_settle even when binary is absent.
      -- Uses settle_ms (not timeout_ms) so the two concepts stay independent.
      if fixture.after_lsp_settle then
        vim.wait(settle, function()
          return false
        end, 100)
      end
    else
      local attached = vim.wait(timeout, function()
        return #vim.lsp.get_clients({ bufnr = buf, name = client }) > 0
      end, 100)
      if attached then
        ok(("%s: LSP %s attached"):format(fixture.path, client))
      else
        fail(("%s: LSP %s: binary present but did not attach within %dms"):format(fixture.path, client, timeout))
      end
    end
  end

  if fixture.after_lsp_settle then
    fixture.after_lsp_settle(buf)
  end
end

-- ---------------------------------------------------------------------------
-- Main check loop
-- ---------------------------------------------------------------------------

local done = false

vim.defer_fn(function()
  -- Wrap the entire body so a Lua error cannot silently pass the checker.
  -- Any crash is recorded as a failure, and done is always set so the outer
  -- vim.wait does not block for the full 120 s ceiling.
  local ok_pcall, err = pcall(function()
    for _, fixture in ipairs(fixtures) do
      -- Opening the file fires BufRead/BufReadPost/FileType autocmds
      -- synchronously, triggering lazy.nvim to load filetype-specific plugins.
      vim.cmd("edit " .. vim.fn.fnameescape(fixture.path))
      local buf = vim.api.nvim_get_current_buf()

      -- Phase 1: filetype detection (synchronous, part of BufReadPost chain).
      local ft = vim.bo[buf].filetype
      if ft ~= fixture.filetype then
        fail(("%s: filetype=%s want=%s"):format(fixture.path, ft == "" and "(empty)" or ft, fixture.filetype))
      else
        ok(("%s: filetype=%s"):format(fixture.path, ft))
      end

      -- Phase 2: fixture-specific pre-LSP checks (e.g. linter wiring).
      if fixture.before_lsp then
        fixture.before_lsp(buf)
      end

      -- Phase 3: LSP phase — attach wait (or skip) then after_lsp_settle.
      run_lsp_phase(buf, fixture)
    end
  end)

  if not ok_pcall then
    fail("deferred callback crashed: " .. tostring(err))
  end

  -- Always set done so the outer vim.wait unblocks even on crash.
  done = true
end, STARTUP_DELAY_MS)

-- Keep the event loop alive until all checks complete.
-- 120 s hard ceiling; a false return means the deferred callback never fired.
local completed = vim.wait(120000, function()
  return done
end, 100)

if not completed then
  -- done was never set: deferred callback did not run within the ceiling.
  fail("check timed out after 120 s — deferred callback did not complete (lazy.nvim startup stalled?)")
end

-- ---------------------------------------------------------------------------
-- Report and exit
-- ---------------------------------------------------------------------------

if #failures > 0 then
  io.stderr:write(("\ncheck-nvim: %d failure(s)\n"):format(#failures))
  vim.cmd("cquit 1")
else
  io.write(("\ncheck-nvim: %d fixture(s) passed\n"):format(#fixtures))
  vim.cmd("qall!")
end
