-- Kotlin development: formatting policy, linting, and LSP tuning.
-- Auto-format on save is disabled because the project lacks consistent
-- formatting — auto-format causes large diffs on lines you didn't touch.
local ktlint_editorconfig = vim.fn.stdpath("config") .. "/ktlint.editorconfig"

local function disable_kotlin_autoformat()
  local augroup = vim.api.nvim_create_augroup("custom_kotlin_format", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "kotlin",
    callback = function(args)
      vim.b[args.buf].autoformat = false
    end,
  })
  -- Backfill: apply to Kotlin buffers already open before this init ran
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "kotlin" then
      vim.b[buf].autoformat = false
    end
  end
end

-- Run immediately when lazy.nvim loads this spec file (during setup, before VeryLazy)
disable_kotlin_autoformat()

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "kotlin-debug-adapter",
      })
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      local linters = require("lint").linters
      linters.ktlint = linters.ktlint or {}
      linters.ktlint.args = linters.ktlint.args or {}
      local flag = "--editorconfig=" .. ktlint_editorconfig
      if not vim.tbl_contains(linters.ktlint.args, flag) then
        table.insert(linters.ktlint.args, flag)
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = {
          settings = {
            kotlin = {
              compiler = {
                jvm = {
                  target = "17",
                },
              },
              inlayHints = {
                parameterHints = true,
                typeHints = true,
              },
            },
          },
        },
      },
    },
  },
}
