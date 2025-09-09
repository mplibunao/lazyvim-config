return {
  "snacks.nvim",
  opts = function(_, opts)
    -- Disable snacks explorer to prevent conflict with mini.files
    opts.explorer = { enabled = false }

    -- Add session selector to dashboard
    table.insert(
      opts.dashboard.preset.keys,
      7,
      { icon = "S", key = "S", desc = "Select Session", action = require("persistence").select }
    )
    
    return opts
  end,
  keys = {
    -- Override the default explorer keybindings to prevent them from being set
    { "<leader>fe", false },
    { "<leader>fE", false },
    { "<leader>e", false },
    { "<leader>E", false },
  },
}
