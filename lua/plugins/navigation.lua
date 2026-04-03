-- Single source of truth for mini.files open targets
local function open_current_file()
  require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
end

local function open_cwd()
  require("mini.files").open(vim.uv.cwd(), true)
end

local function open_root()
  require("mini.files").open(LazyVim.root(), true)
end

return {
  -- Disable Snacks explorer and add dashboard session selector
  {
    "snacks.nvim",
    opts = function(_, opts)
      opts.explorer = { enabled = false }

      -- Insert session key only if S is not already present
      opts.dashboard = opts.dashboard or {}
      opts.dashboard.preset = opts.dashboard.preset or {}
      opts.dashboard.preset.keys = opts.dashboard.preset.keys or {}
      local has_session_key = false
      for _, item in ipairs(opts.dashboard.preset.keys) do
        if type(item) == "table" and item.key == "S" then
          has_session_key = true
          break
        end
      end
      if not has_session_key then
        local pos = math.min(7, #opts.dashboard.preset.keys + 1)
        table.insert(
          opts.dashboard.preset.keys,
          pos,
          { icon = "S", key = "S", desc = "Select Session", action = require("persistence").select }
        )
      end

      return opts
    end,
    keys = {
      -- Suppress default explorer keybindings to prevent conflict with mini.files
      { "<leader>fe", false },
      { "<leader>fE", false },
      { "<leader>e", false },
      { "<leader>E", false },
    },
  },

  -- mini.files as the default explorer
  {
    "nvim-mini/mini.files",
    dependencies = { "snacks.nvim" },
    init = function()
      -- Reassert our mappings on VimEnter in case upstream explorer mappings race earlier
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("custom_mini_files_nav", { clear = true }),
        callback = function()
          pcall(vim.keymap.del, "n", "<leader>fe")
          pcall(vim.keymap.del, "n", "<leader>fE")
          vim.keymap.set("n", "<leader>e", open_current_file, { desc = "Open mini.files (directory of current file)" })
          vim.keymap.set("n", "<leader>E", open_cwd, { desc = "Open mini.files (cwd)" })
        end,
      })
    end,
    keys = {
      { "<leader>e", open_current_file, desc = "Open mini.files (directory of current file)" },
      { "<leader>E", open_cwd, desc = "Open mini.files (cwd)" },
      { "<leader>fm", open_root, desc = "Open mini.files (root)" },
      { "<leader>fM", open_cwd, desc = "Open mini.files (cwd)" },
    },
    opts = {
      options = {
        use_as_default_explorer = true,
      },
    },
  },
}
