# ADR-002: Home path literals

**Status:** accepted
**Date:** 2026-05-28

## Context

This repo can point Neovim at external directories under MP's home directory,
such as the dotfiles flake or local prompt/toolkit checkouts. Hardcoding the
`/Users/mp` prefix makes those references brittle across macOS users, Linux
machines, and future account names. The fragile part is the home prefix, not the
external repository path.

The harness adds ast-grep guardrails in `guardrails/ast-grep/` and needs a
sanctioned replacement before banning the old pattern. A rule without a repair
path would only bounce work back to the next maintainer or agent.

## Decision

Never hardcode a home-directory prefix in Lua config. Use one of these patterns
instead:

1. `vim.fn.expand("~/path/from/home")` for concrete paths that live under the
   current user's home directory.
2. `vim.env.HOME` when the code needs to compose or compare the home directory
   separately from the rest of the path.

A genuinely machine-specific path that cannot be expressed relative to `~`
should go in one sanctioned module, `lua/config/paths.lua`, so the exception has
one owner. Do not create that module until such a path exists.

## Alternatives considered

**Keep `/Users/mp/...` literals** — simple today, but breaks as soon as this
config is reused under a different account name or on a Linux machine. Rejected.

**Use environment variables for every external checkout** — flexible, but it
turns common local defaults into setup burden. `vim.fn.expand("~/...")` keeps
the current behavior while removing the brittle prefix. Rejected as the default.

**Create `lua/config/paths.lua` immediately** — useful for non-home-relative
machine-specific values, but unnecessary indirection for the current paths. The
current values are all under `$HOME`, so `~` expansion is enough. Deferred until
a non-`~` path appears.

## Consequences

- Lua config no longer depends on MP's exact macOS account path.
- Existing defaults still point to the same directories on MP's machine.
- ast-grep can ban `/Users/...` and `/home/...` string literals in `lua/**`
  without a baseline because the existing violations are migrated first.
- Future agents get a failure message that points here and names the repair
  pattern.

## Migration

Migrate current Lua literals under `/Users/mp` to `vim.fn.expand("~/...")`:

- `lua/plugins/nix.lua` dotfiles flake path.
- `lua/plugins/picker.lua` Wizy prompts default.
- `lua/plugins/picker.lua` claude-toolkit default.

Then add `guardrails/ast-grep/rules/hygiene/no-hardcoded-home-path-in-lua.yml`
and wire `just guard` into `just check`.

## Risks

- **Runtime expansion differs from a literal.** `vim.fn.expand("~/...")` should
  resolve to the same path for MP, but a broken `$HOME` would affect the default.
  `just nvim` and direct command checks catch obvious config-load regressions.
- **The rule flags an intentional future exception.** If a non-home-relative
  machine-specific path becomes necessary, create `lua/config/paths.lua` and
  narrow the rule with an explicit path exemption that points back to this ADR.
