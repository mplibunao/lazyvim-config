-- Disable auto-formatting for Kotlin files on save.
-- The project doesn't have consistent formatting, so auto-format causes
-- large diffs on lines you didn't touch.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "kotlin",
  callback = function()
    vim.b.autoformat = false
  end,
})

return {}
