# Documentation Index

This directory holds durable, topic-specific docs for this LazyVim config.
`CLAUDE.md` is the router. It points here; it does not duplicate content.

## Placement rules

- If it describes **how the config loads or who owns what**, it belongs in `architecture.md`.
- If it describes **how to validate changes**, it belongs in `workflows.md`.
- If it covers a **specific language or toolchain**, give it its own file (e.g., `go.md`, `kotlin.md`).
- If it just restates what a code file already says, **delete it**: the code is the source of truth.
- Every doc here must be linked from this index.

## Docs

| File | Purpose |
|---|---|
| [architecture.md](architecture.md) | Load chain, file ownership, customization clusters |
| [workflows.md](workflows.md) | Agent validation conventions (tmux, headless checks) |
| [go.md](go.md) | Go tooling setup and behavior |
| [kotlin.md](kotlin.md) | Kotlin tooling, formatting, and LSP notes |
| [nix.md](nix.md) | Nix tooling: nixd LSP, nixfmt, statix and deadnix |
| [tooling-policy.md](tooling-policy.md) | Nix vs Mason tool provisioning policy and current-state inventory |

## Related resources

| Path | Purpose |
|---|---|
| `README.md` | Brief user-facing overview and onboarding |
| `cheatsheet.md` | User-facing keymap and usage lookup |
| `exec-plans/` | Implementation history and decision logs |
| `lazyvim.json` | Canonical list of enabled LazyVim extras |
| `stylua.toml` | Canonical Lua formatting settings |
