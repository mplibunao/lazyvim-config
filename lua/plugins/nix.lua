-- Nix development: LSP, linting, and formatting integration.
--
-- Binaries come from Nix Home Manager (on PATH), never Mason; see
-- docs/design-docs/tooling-policy.md. The lang.nix extra supplies the baseline (treesitter,
-- nixfmt via conform, statix via nvim-lint, and nil_ls). This file swaps the LSP
-- to nixd (for module-options completion) and adds deadnix alongside statix.

-- The dotfiles flake and host key, reused by all three nixd exprs below. One
-- source of truth: change here if the flake path or host key ever moves.
local dotfiles_flake = vim.fn.expand("~/Projects/personal/dotfiles/nix")
local darwin_host = "m5-mbp"
local function darwin_expr(suffix)
  return ('(builtins.getFlake "%s").darwinConfigurations."%s"%s'):format(dotfiles_flake, darwin_host, suffix)
end

-- nixd's completion settings point at an absolute flake path. On a host where
-- nixd is on PATH but this flake is absent (a fresh or non-Nix machine), handing
-- those exprs to nixd makes it throw on every evaluation. Gate them on the flake
-- actually existing, so degradation stays clean: nixd still attaches, only
-- without options/package completion, instead of erroring repeatedly. See
-- docs/design-docs/tooling-policy.md (graceful degradation).
local has_dotfiles_flake = vim.fn.isdirectory(dotfiles_flake) == 1

-- nixd is provided by Nix on PATH; never let Mason fetch a duplicate.
local nixd_server = { mason = false }
if has_dotfiles_flake then
  nixd_server.settings = {
    nixd = {
      -- Package completion, flake-pinned to the same nixpkgs the system
      -- evaluates: nix-darwin exposes `.pkgs` on the config, mirroring the
      -- `.options` the home-manager expr uses.
      -- Avoids a <nixpkgs> NIX_PATH lookup, which is unreliable under
      -- Determinate's pure-flake mode and may resolve to a different nixpkgs.
      nixpkgs = {
        expr = darwin_expr(".pkgs"),
      },
      -- Module-options completion. The ABSOLUTE flake path is required:
      -- `./.` resolves to nixd's cwd, which is rarely the flake dir.
      options = {
        -- nix-darwin top-level options (system.defaults.*, homebrew.*, ...).
        darwin = {
          expr = darwin_expr(".options"),
        },
        -- home-manager options, where MP mostly edits. HM is integrated as
        -- a nix-darwin module here (no standalone homeConfigurations), so
        -- its options nest under the darwin config. The attrsOf-submodule
        -- element type is extracted with `users.type.getSubOptions []`
        -- (nixd's documented NixOS-integrated pattern, adapted nixos->darwin).
        -- Keep this suffix aligned with the home-manager option-tree shape.
        ["home-manager"] = {
          expr = darwin_expr(".options.home-manager.users.type.getSubOptions []"),
        },
      },
      -- Formatting intentionally unset: conform.nvim owns format-on-save
      -- with nixfmt. Setting formatting.command here would double-format.
    },
  }
end

return {
  {
    -- Add deadnix without dropping statix (wired by the lang.nix extra).
    -- Function-form opts append to the already-merged list; a plain table-form
    -- `linters_by_ft.nix` would replace the array and silently lose statix.
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.nix = opts.linters_by_ft.nix or {}
      if not vim.tbl_contains(opts.linters_by_ft.nix, "deadnix") then
        table.insert(opts.linters_by_ft.nix, "deadnix")
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- The extra enables nil_ls, but its binary (`nil`) was removed from Home
        -- Manager in favor of nixd. Disabling it avoids a failed attach attempt.
        nil_ls = { enabled = false },
        nixd = nixd_server,
      },
    },
  },
}
