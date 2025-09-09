return {
  "folke/which-key.nvim",
  opts = function(_, opts)
    -- Use the modern spec API and avoid duplicates
    opts.spec = opts.spec or {}
    local has_ai_group = false
    for _, item in ipairs(opts.spec) do
      if type(item) == "table" and item[1] == "<leader>a" and (item.group or item.name) then
        has_ai_group = true
        break
      end
    end
    if not has_ai_group then
      table.insert(opts.spec, { "<leader>a", group = "AI" })
    end
  end,
}
