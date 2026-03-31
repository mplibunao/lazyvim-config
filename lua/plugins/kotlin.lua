-- Point ktlint at a custom editorconfig to globally disable noisy rules.
-- Edit ~/.config/nvim-lazy/ktlint.editorconfig to add/remove rules.
local ktlint_editorconfig = vim.fn.stdpath("config") .. "/ktlint.editorconfig"

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
