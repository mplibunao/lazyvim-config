# Test fixture for Nix language support in this LazyVim config.
#
# Opening this file should detect filetype=nix, apply treesitter highlighting,
# and attach the nixd LSP. It also deliberately carries lint anti-patterns so the
# statix and deadnix paths (both wired in lua/plugins/nix.lua) have something to
# report. The smells below are INTENTIONAL; do not "fix" them.
{
  pkgs ? import <nixpkgs> { },
  # deadnix: `unusedArg` is never referenced, so it is flagged as an unused
  # function argument.
  unusedArg ? null,
}:

let
  # deadnix: `unusedBinding` is never referenced below, so it is flagged as a
  # dead let binding.
  unusedBinding = "never used";

  # A referenced binding, so the fixture also exercises a real let-binding to
  # usage path for treesitter highlighting and nixd hover/goto-definition.
  greeting = "hello from the nix test fixture";

  enableHello = true;

  # statix (bool_comparison): comparing against `true` is redundant; statix
  # rewrites this to just `enableHello`.
  helloEnabled = enableHello == true;
in
pkgs.mkShell {
  packages = pkgs.lib.optional helloEnabled pkgs.hello;

  shellHook = ''
    echo "${greeting}"
  '';
}
