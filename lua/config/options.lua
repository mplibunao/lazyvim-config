-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Add JVM build system markers to root detection so pickers resolve
-- the project root correctly in Kotlin/Maven projects.
vim.g.root_spec = { "lsp", { ".git", "pom.xml", "build.gradle.kts", "build.gradle", "settings.gradle.kts" }, "cwd" }

-- Enable line wrapping
vim.opt.wrap = true
vim.opt.linebreak = true -- Wrap at word boundaries, not mid-word
vim.opt.breakindent = true -- Preserve indentation on wrapped lines
