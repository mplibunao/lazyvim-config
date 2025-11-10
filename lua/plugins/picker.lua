return {
  -- Extend Snacks configuration with a custom picker shortcut/command
  "snacks.nvim",
  opts = {
    picker = {
      sources = {
        files = {
          hidden = true,
        },
      },
      actions = {
        -- Custom action to copy the absolute path of the selected file
        copy_path = function(p, item)
          if item and item.file then
            -- Get the picker's cwd and construct the absolute path
            local picker_cwd = p.opts.cwd or vim.fn.getcwd()
            local path
            -- Check if item.file is already absolute
            if vim.fn.fnamemodify(item.file, ":p") == item.file then
              path = item.file
            else
              -- Construct absolute path from picker's cwd
              path = vim.fn.fnamemodify(picker_cwd .. "/" .. item.file, ":p")
            end
            vim.fn.setreg('+', path)
            vim.notify("Path copied: " .. path, vim.log.levels.INFO)
          else
            vim.notify("No file to copy path from", vim.log.levels.WARN)
          end
        end,
      },
      win = {
        input = {
          keys = {
            -- Add yp keybinding to copy absolute path (similar to ranger.nvim)
            ["yp"] = { "copy_path", mode = { "n", "i" }, desc = "Copy absolute path" },
          },
        },
      },
    },
  },
  init = function()
    -- Allow overriding from your `init.lua` or elsewhere
    vim.g.wizy_prompts_dir = vim.g.wizy_prompts_dir or "/Users/mp/Projects/wizy/wizy-prompts"
    vim.g.claude_toolkit_dir = vim.g.claude_toolkit_dir or "/Users/mp/Projects/personal/ai/claude-toolkit"

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
        picker.files({
          cwd = dir,
          hidden = true,
          -- Add the same copy_path action for the WizyPrompts picker
          actions = {
            copy_path = function(p, item)
              if item and item.file then
                -- Use the configured wizy_prompts_dir to ensure correct absolute path
                local path
                -- Check if item.file is already absolute
                if vim.fn.fnamemodify(item.file, ":p") == item.file then
                  path = item.file
                else
                  -- Construct absolute path from the wizy prompts directory
                  path = vim.fn.fnamemodify(dir .. "/" .. item.file, ":p")
                end
                vim.fn.setreg('+', path)
                vim.notify("Path copied: " .. path, vim.log.levels.INFO)
              else
                vim.notify("No file to copy path from", vim.log.levels.WARN)
              end
            end,
          },
          win = {
            input = {
              keys = {
                ["yp"] = { "copy_path", mode = { "n", "i" }, desc = "Copy absolute path" },
              },
            },
          },
        })
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

    -- :ClaudeToolkit command to open the picker at the claude toolkit dir
    vim.api.nvim_create_user_command("ClaudeToolkit", function()
      local dir = vim.g.claude_toolkit_dir
      if vim.fn.isdirectory(dir) ~= 1 then
        vim.notify("Claude toolkit directory not found: " .. dir, vim.log.levels.ERROR)
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
        picker.files({
          cwd = dir,
          hidden = true,
          actions = {
            copy_path = function(p, item)
              if item and item.file then
                local absolute
                if vim.fn.fnamemodify(item.file, ":p") == item.file then
                  absolute = item.file
                else
                  absolute = vim.fn.fnamemodify(dir .. "/" .. item.file, ":p")
                end
                vim.fn.setreg('+', absolute)
                vim.notify("Path copied: " .. absolute, vim.log.levels.INFO)
              else
                vim.notify("No file to copy path from", vim.log.levels.WARN)
              end
            end,
          },
          win = {
            input = {
              keys = {
                ["yp"] = { "copy_path", mode = { "n", "i" }, desc = "Copy absolute path" },
              },
            },
          },
        })
      else
        vim.notify("Snacks picker not available", vim.log.levels.ERROR)
      end
    end, { desc = "Open Snacks picker at claude toolkit" })
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
    {
      "<leader>ac",
      function()
        vim.cmd("ClaudeToolkit")
      end,
      desc = "Claude Toolkit (picker)",
    },
  },
}
