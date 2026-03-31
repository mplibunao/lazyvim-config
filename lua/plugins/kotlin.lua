-- Point ktlint at a custom editorconfig to globally disable noisy rules.
-- Edit ~/.config/nvim-lazy/ktlint.editorconfig to add/remove rules.
local ktlint_editorconfig = vim.fn.stdpath("config") .. "/ktlint.editorconfig"

return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local linters = require("lint").linters
      linters.ktlint = linters.ktlint or {}
      linters.ktlint.args = linters.ktlint.args or {}
      table.insert(linters.ktlint.args, "--editorconfig=" .. ktlint_editorconfig)
    end,
  },
}
