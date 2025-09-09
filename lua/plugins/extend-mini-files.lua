return {
  "echasnovski/mini.files",
  dependencies = { "snacks.nvim" }, -- Ensure it loads after snacks.nvim
  init = function()
    -- Clear any existing mappings for <leader>e to ensure mini.files takes precedence
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        -- Delete any existing mappings
        pcall(vim.keymap.del, "n", "<leader>fe")
        pcall(vim.keymap.del, "n", "<leader>fE")
        -- Ensure our mappings are set
        vim.keymap.set("n", "<leader>e", function()
          require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
        end, { desc = "Open mini.files (directory of current file)" })
        vim.keymap.set("n", "<leader>E", function()
          require("mini.files").open(vim.uv.cwd(), true)
        end, { desc = "Open mini.files (cwd)" })
      end,
    })
  end,
  keys = {
    {
      "<leader>e",
      function()
        require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
      end,
      desc = "Open mini.files (directory of current file)",
    },
    {
      "<leader>E",
      function()
        require("mini.files").open(vim.uv.cwd(), true)
      end,
      desc = "Open mini.files (cwd)",
    },
    {
      "<leader>fm",
      function()
        require("mini.files").open(LazyVim.root(), true)
      end,
      desc = "Open mini.files (root)",
    },
  },
  opts = {
    options = {
      use_as_default_explorer = true,
    },
  },
}
