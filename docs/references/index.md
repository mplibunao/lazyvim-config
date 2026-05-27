# References

Local copies of external material included for agent context. The index and framing notes are
hand-authored prose; copied payload files are not.

> **Prose gate:** Each verbatim external payload file is excluded from `just prose` by an
> explicit entry in the `justfile` prose recipe. Currently excluded: `harness-engineering.md`.
> Adding a new payload requires a new targeted exclusion in the `justfile`; the directory is not
> blanket-excluded. This index is prose-checked as normal.
> Hand-authored distillations of external material belong in `docs/design-docs/` instead.
> Index coverage (`just docs`) still applies to all files here.

## Docs

| File | Purpose |
|---|---|
| [`harness-engineering.md`](harness-engineering.md) | OpenAI article on agent-first repo design; source of the structural patterns adopted in this repo's enforcement harness |

## Patterns adopted from harness-engineering

The following patterns from the article are implemented in this repo:

- `AGENTS.md` (~100 lines) as a table of contents, not a manual
- Indexed `docs/` as the knowledge system of record, validated by `just docs`
- `exec-plans/{active,completed}/` and `exec-plans/tech-debt-tracker.md` as first-class artifacts
- Single aggregate check command (`just check`) with named sub-recipes for fast iteration
- Remediation-first lint messages that inject fixes into agent context
- Doc-gardening consumer for recurring doc-currency checks

For what was deliberately excluded (observability stacks, per-worktree boot, Chrome DevTools,
ports-and-adapters), see [`docs/design-docs/core-beliefs.md`](../design-docs/core-beliefs.md).
