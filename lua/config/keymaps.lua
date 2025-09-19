-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function copy_current_file_path()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    vim.notify("Current buffer is not associated with a file", vim.log.levels.WARN)
    return
  end
  local absolute = vim.fn.fnamemodify(name, ":p")
  vim.fn.setreg("+", absolute)
  vim.notify("Copied path: " .. absolute, vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>yp", copy_current_file_path, {
  desc = "Copy buffer absolute path",
})

vim.api.nvim_create_user_command("CopyCurrentFilePath", copy_current_file_path, {
  desc = "Copy current buffer's absolute path",
})
