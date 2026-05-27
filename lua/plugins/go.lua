-- Go development: formatting, linting, testing, and LSP tuning.
--
-- Tool sourcing: goimports/gofumpt/golangci-lint/delve (plus gomodifytags/impl)
-- come from the LazyVim lang.go extra via Mason, so they are not listed here.
-- gopls comes from Nix Home Manager (dotfiles tier2.nix) and is fenced from
-- Mason below, so Mason cannot install a second, version-drifting copy.
-- See docs/tooling-policy.md.
-- Lint policy should live in the project's .golangci.yml, not here.
return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        go = { "golangcilint" },
      },
    },
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = {
      adapters = {
        ["neotest-golang"] = {
          dap_go_enabled = true,
          go_test_args = { "-v", "-race", "-count=1" },
          runner = "gotestsum",
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          mason = false, -- use the Nix gopls (see header + docs/tooling-policy.md)
          settings = {
            gopls = {
              vulncheck = "Imports",
            },
          },
        },
      },
    },
  },
}
