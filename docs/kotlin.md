# Kotlin

## Auto-format

Disabled on save via `lua/plugins/kotlin.lua`. LazyVim's Kotlin extra uses `ktlint` as the formatter (via conform.nvim), but the project doesn't have consistent formatting — auto-format causes noisy diffs on untouched lines.

Manual format is still available with `<leader>cf`.

## Linting (ktlint)

LazyVim's Kotlin extra also sets up `ktlint` as a linter (via nvim-lint). It runs with its default ruleset, which can be noisy on projects without a ktlint config.

### Disabling rules globally

Rules are configured in `ktlint.editorconfig` (repo root). The `--editorconfig` flag in `lua/plugins/kotlin.lua` tells ktlint to use this file, overriding any project-level `.editorconfig`.

To disable a rule, add a line:

```ini
[*.{kt,kts}]
ktlint_standard_<rule-name> = disabled
```

### Finding the rule name

The diagnostic message in Neovim shows the rule ID in brackets, e.g. `[standard:indent]` maps to `ktlint_standard_indent`.

### Commonly disabled rules

| Rule | editorconfig key |
|------|-----------------|
| Indentation | `ktlint_standard_indent` |
| Wildcard imports | `ktlint_standard_no-wildcard-imports` |
| Max line length | `ktlint_standard_max-line-length` |
| Trailing comma (call site) | `ktlint_standard_trailing-comma-on-call-site` |
| Trailing comma (declaration) | `ktlint_standard_trailing-comma-on-declaration-site` |
