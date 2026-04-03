-- Using fork with admonition support
local function resolve_markdown_preview_css()
  local css_path = vim.fn.expand("~/.config/nvim-lazy/assets/markdown-preview.css")
  if vim.fn.filereadable(css_path) == 1 then
    return css_path
  end
  return nil
end

local preview_options = {
  mkit = {
    breaks = true,
    html = true,
  },
  katex = {},
  uml = {},
  maid = {},
  disable_sync_scroll = 0,
  sync_scroll_type = "middle",
  hide_yaml_meta = 1,
  sequence_diagrams = {},
  flowchart_diagrams = {},
  content_editable = false,
  disable_filename = 0,
  toc = {
    listType = "ol",
    containerClass = "table-of-contents",
    markerPattern = "^\\[toc\\]",
    includeLevel = { 1, 2, 3, 4 },
  },
}

local global_settings = {
  mkdp_combine_preview = 1,
  mkdp_combine_preview_auto_refresh = 0,
  mkdp_echo_preview_url = 0,
  mkdp_auto_start = 0,
  mkdp_auto_close = 1,
  mkdp_refresh_slow = 0,
  mkdp_command_for_global = 0,
  mkdp_open_to_the_world = 0,
  mkdp_browser = "",
  mkdp_page_title = "「${name}」",
  mkdp_filetypes = { "markdown" },
  mkdp_theme = "dark",
}

return {
  {
    "UtkarshKunwar/markdown-preview.nvim",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    init = function()
      local css = resolve_markdown_preview_css()
      if css then
        vim.g.mkdp_markdown_css = css
      end
      vim.g.mkdp_preview_options = preview_options
      for key, value in pairs(global_settings) do
        vim.g[key] = value
      end
    end,
  },
}
