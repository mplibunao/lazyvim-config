return {
  {
    "iamcco/markdown-preview.nvim",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    init = function()
      -- Set custom CSS path
      local css_path = vim.fn.expand("~/.config/nvim-lazy/assets/markdown-preview.css")
      if vim.fn.filereadable(css_path) == 1 then
        vim.g.mkdp_markdown_css = css_path
      end

      -- Note: To inject custom JavaScript for copy functionality,
      -- you may need to modify the preview template or use browser extensions.
      -- The CSS styling is ready for copy buttons when they're added.

      -- Configure preview options with enhanced TOC settings
      vim.g.mkdp_preview_options = {
        mkit = {
          breaks = true, -- Convert \n to <br>
          html = true, -- Enable HTML tags in markdown
        },
        katex = {}, -- katex options
        uml = {}, -- markdown-it-plantuml options
        maid = {}, -- mermaid options
        disable_sync_scroll = 0,
        sync_scroll_type = "middle",
        hide_yaml_meta = 1,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = 0,
        toc = {
          -- Enhanced TOC configuration
          listType = "ol", -- Use ordered list for TOC
          containerClass = "table-of-contents",
          markerPattern = "^\\[toc\\]",
          includeLevel = { 1, 2, 3, 4 }, -- Include h1-h4 in TOC
        },
      }

      -- Enable code block copy functionality (if supported)
      vim.g.mkdp_combine_preview = 1
      vim.g.mkdp_echo_preview_url = 0

      -- Additional markdown-preview settings
      vim.g.mkdp_auto_start = 0 -- Don't auto-start preview
      vim.g.mkdp_auto_close = 1 -- Auto-close preview when leaving buffer
      vim.g.mkdp_refresh_slow = 0 -- Refresh on save
      vim.g.mkdp_command_for_global = 0 -- Preview command only for markdown files
      vim.g.mkdp_open_to_the_world = 0 -- Only accessible from localhost
      vim.g.mkdp_browser = "" -- Use default browser
      vim.g.mkdp_page_title = "「${name}」" -- Preview page title
      vim.g.mkdp_filetypes = { "markdown" } -- Only for markdown files
      vim.g.mkdp_theme = "dark" -- Use dark theme
    end,
  },
}
