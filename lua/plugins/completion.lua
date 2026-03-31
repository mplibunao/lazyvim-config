return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}
      opts.keymap["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" }
      opts.keymap["<S-Tab>"] = { "snippet_backward", "fallback" }
      return opts
    end,
  },
}
