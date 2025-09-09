return {
  -- Extend Snacks configuration with a custom picker shortcut/command
  "snacks.nvim",
  init = function()
    -- Allow overriding from your `init.lua` or elsewhere
    vim.g.wizy_prompts_dir = vim.g.wizy_prompts_dir or "/Users/mp/Projects/wizy/wizy-prompts"

    -- :WizyPrompts command to open the picker at the prompts dir
    vim.api.nvim_create_user_command("WizyPrompts", function()
      local dir = vim.g.wizy_prompts_dir
      if vim.fn.isdirectory(dir) ~= 1 then
        vim.notify("Wizy prompts directory not found: " .. dir, vim.log.levels.ERROR)
        return
      end

      local picker
      local ok, snacks = pcall(require, "snacks")
      if ok and snacks and snacks.picker then
        picker = snacks.picker
      elseif _G.Snacks and _G.Snacks.picker then
        picker = _G.Snacks.picker
      end

      if picker and picker.files then
        picker.files({ cwd = dir, hidden = true })
      else
        vim.notify("Snacks picker not available", vim.log.levels.ERROR)
      end
    end, { desc = "Open Snacks picker at wizy-prompts" })

    -- :WizyPromptsGrep command to live-grep within the prompts dir
    vim.api.nvim_create_user_command("WizyPromptsGrep", function()
      local dir = vim.g.wizy_prompts_dir
      if vim.fn.isdirectory(dir) ~= 1 then
        vim.notify("Wizy prompts directory not found: " .. dir, vim.log.levels.ERROR)
        return
      end

      local picker
      local ok, snacks = pcall(require, "snacks")
      if ok and snacks and snacks.picker then
        picker = snacks.picker
      elseif _G.Snacks and _G.Snacks.picker then
        picker = _G.Snacks.picker
      end

      if picker and picker.grep then
        picker.grep({ cwd = dir })
      else
        vim.notify("Snacks grep picker not available", vim.log.levels.ERROR)
      end
    end, { desc = "Grep in wizy-prompts" })
  end,
  keys = {
    -- AI group mappings
    {
      "<leader>aw",
      function()
        vim.cmd("WizyPrompts")
      end,
      desc = "Wizy Prompts (picker)",
    },
    {
      "<leader>aW",
      function()
        vim.cmd("WizyPromptsGrep")
      end,
      desc = "Wizy Prompts Grep (picker)",
    },
  },
}
