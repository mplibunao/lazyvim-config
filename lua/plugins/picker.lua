local function resolve_picker()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.picker then
    return snacks.picker
  end
  if Snacks and Snacks.picker then
    return Snacks.picker
  end
  return nil
end

local function make_copy_path_action(base_dir)
  return function(_, item)
    if item and item.file then
      local path
      if vim.fn.fnamemodify(item.file, ":p") == item.file then
        path = item.file
      else
        path = vim.fn.fnamemodify(base_dir .. "/" .. item.file, ":p")
      end
      vim.fn.setreg("+", path)
      vim.notify("Path copied: " .. path, vim.log.levels.INFO)
    else
      vim.notify("No file to copy path from", vim.log.levels.WARN)
    end
  end
end

local function open_files_picker(dir, missing_msg, unavailable_msg)
  if vim.fn.isdirectory(dir) ~= 1 then
    vim.notify(missing_msg .. dir, vim.log.levels.ERROR)
    return
  end
  local picker = resolve_picker()
  if picker and picker.files then
    picker.files({
      cwd = dir,
      hidden = true,
      actions = { copy_path = make_copy_path_action(dir) },
      win = { input = { keys = { ["yp"] = { "copy_path", mode = { "n" }, desc = "Copy absolute path" } } } },
    })
  else
    vim.notify(unavailable_msg, vim.log.levels.ERROR)
  end
end

local function open_grep_picker(dir, missing_msg, unavailable_msg)
  if vim.fn.isdirectory(dir) ~= 1 then
    vim.notify(missing_msg .. dir, vim.log.levels.ERROR)
    return
  end
  local picker = resolve_picker()
  if picker and picker.grep then
    picker.grep({ cwd = dir })
  else
    vim.notify(unavailable_msg, vim.log.levels.ERROR)
  end
end

return {
  -- Snacks picker customization and AI picker commands
  {
    "snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true,
          },
        },
        actions = {
          copy_path = function(p, item)
            local base = p.opts.cwd or vim.fn.getcwd()
            make_copy_path_action(base)(p, item)
          end,
        },
        win = {
          input = {
            keys = {
              ["yp"] = { "copy_path", mode = { "n" }, desc = "Copy absolute path" },
            },
          },
        },
      },
    },
    init = function()
      vim.g.wizy_prompts_dir = vim.g.wizy_prompts_dir or "/Users/mp/Projects/wizy/wizy-prompts"
      vim.g.claude_toolkit_dir = vim.g.claude_toolkit_dir or "/Users/mp/Projects/personal/ai/claude-toolkit"

      vim.api.nvim_create_user_command("WizyPrompts", function()
        open_files_picker(vim.g.wizy_prompts_dir, "Wizy prompts directory not found: ", "Snacks picker not available")
      end, { desc = "Open Snacks picker at wizy-prompts" })

      vim.api.nvim_create_user_command("WizyPromptsGrep", function()
        open_grep_picker(
          vim.g.wizy_prompts_dir,
          "Wizy prompts directory not found: ",
          "Snacks grep picker not available"
        )
      end, { desc = "Grep in wizy-prompts" })

      vim.api.nvim_create_user_command("ClaudeToolkit", function()
        open_files_picker(
          vim.g.claude_toolkit_dir,
          "Claude toolkit directory not found: ",
          "Snacks picker not available"
        )
      end, { desc = "Open Snacks picker at claude toolkit" })
    end,
    keys = {
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
  },

  -- Register the AI group in which-key
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
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
  },
}
