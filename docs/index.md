# Documentation Index

This directory holds durable, topic-specific docs for this LazyVim config.
`CLAUDE.md` is the router. It points here; it does not duplicate content.

## Doc taxonomy

Maps harness-engineering doc concepts to where they live in this repo:

| Kind | Location | Purpose |
|---|---|---|
| Top-level architecture map | [`ARCHITECTURE.md`](../ARCHITECTURE.md) | Load chain, file ownership, customization clusters |
| Per-area design and policy | [`docs/design-docs/`](design-docs/index.md) | Language tooling, core beliefs, policy docs |
| Architecture decisions | [`docs/decisions/`](decisions/index.md) | ADRs: single decisions with context, alternatives, consequences |
| Operational workflows | [`docs/workflows.md`](workflows.md) | How to validate changes, tmux patterns, smoke checklist |
| External distillations | `docs/references/` *(reserved)* | Local copies of relevant external material |
| Implementation history | `exec-plans/` | Active plans and completed plans |
| Deferred work | [`exec-plans/tech-debt-tracker.md`](../exec-plans/tech-debt-tracker.md) | Items deferred at plan-write time, with reasoning |
| Design review artifacts | `docs/reviews/` | Agent/design-review output; excluded from hand-authored doc coverage |
| Generated doc audits | `docs/generated/` *(reserved)* | Machine-generated output (doc-garden, etc.); excluded from index coverage |

## Placement rules

- If it describes **how the config loads or who owns what**, it belongs in `ARCHITECTURE.md`.
- If it describes **how to validate changes**, it belongs in `workflows.md`.
- If it covers a **specific language, toolchain, or design policy**, it belongs in `docs/design-docs/`.
- If it records a **single architectural decision** with context and alternatives, it belongs in `docs/decisions/`.
- If it just restates what a code file already says, **delete it**: the code is the source of truth.
- Every hand-authored doc must be linked from this index or from a directory-level `index.md`.
  Artifact directories (`docs/generated/`, `docs/reviews/`) are excluded — see taxonomy above.

## Docs

| File | Purpose |
|---|---|
| [`../ARCHITECTURE.md`](../ARCHITECTURE.md) | Load chain, file ownership, customization clusters |
| [`workflows.md`](workflows.md) | Agent validation conventions (tmux, headless checks) |
| [`design-docs/`](design-docs/index.md) | Per-area design and policy (tooling, core beliefs, language docs) |
| [`decisions/`](decisions/index.md) | Architecture Decision Records, including the home-path literal policy |

## Related resources

| Path | Purpose |
|---|---|
| `README.md` | Brief user-facing overview and onboarding |
| `cheatsheet.md` | User-facing keymap and usage lookup |
| `exec-plans/` | Implementation history and decision logs |
| `exec-plans/tech-debt-tracker.md` | Durable home for deferred work items |
| `lazyvim.json` | Canonical list of enabled LazyVim extras |
| `stylua.toml` | Canonical Lua formatting settings |
