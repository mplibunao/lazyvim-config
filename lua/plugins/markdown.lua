-- Markdown editing policy: keep manual formatting available, but disable
-- LazyVim format-on-save to avoid noisy Markdown diffs in skill/docs files.

local function disable_markdown_autoformat()
  local augroup = vim.api.nvim_create_augroup("custom_markdown_format", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "markdown",
    callback = function(args)
      vim.b[args.buf].autoformat = false
    end,
  })

  -- Backfill: apply to Markdown buffers already open before this spec loaded.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "markdown" then
      vim.b[buf].autoformat = false
    end
  end
end

disable_markdown_autoformat()

return {}
