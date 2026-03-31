-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable auto-formatting for Kotlin files on save.
-- The project doesn't have consistent formatting, so auto-format causes
-- large diffs on lines you didn't touch.
local kotlin_augroup = vim.api.nvim_create_augroup("custom_kotlin_format", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = kotlin_augroup,
  pattern = "kotlin",
  callback = function(args)
    vim.b[args.buf].autoformat = false
  end,
})
-- Backfill: apply to Kotlin buffers already open before VeryLazy fired
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "kotlin" then
    vim.b[buf].autoformat = false
  end
end
