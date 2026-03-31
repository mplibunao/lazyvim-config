return {
  -- Disable Snacks explorer and add dashboard session selector
  {
    "snacks.nvim",
    opts = function(_, opts)
      opts.explorer = { enabled = false }

      table.insert(
        opts.dashboard.preset.keys,
        7,
        { icon = "S", key = "S", desc = "Select Session", action = require("persistence").select }
      )

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
      {
        "<leader>fM",
        function()
          require("mini.files").open(vim.uv.cwd(), true)
        end,
        desc = "Open mini.files (cwd)",
      },
    },
    opts = {
      options = {
        use_as_default_explorer = true,
      },
    },
  },
}
