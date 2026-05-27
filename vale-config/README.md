# Vale vocabulary mirror

These files are the CI substitute for the vocabulary that Nix Home Manager
installs at `~/.local/share/vale/styles/config/vocabularies/`.

**Source of truth:** `dotfiles/nix/home/mp/modules/vale.nix` (the `dataFile`
vocab blocks for Base, Nix, JVM, Go, and TypeScript).

**When to update:** when a vocab block in `vale.nix` changes (terms added or
removed), mirror the change here in the same PR. Failure symptom: `just prose`
disagrees between local and CI on a technical term that did not otherwise change.

**Known duplication risk:** TD-007 in `exec-plans/tech-debt-tracker.md`.
