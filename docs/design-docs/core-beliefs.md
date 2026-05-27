# Core beliefs

Operating principles for this repo. These are not aspirations; they are
constraints that shape every tooling decision and should be tested against
before adding new machinery.

## This is a config repo, not a product

This repo excludes ports-and-adapters domain architecture, observability
stacks, runtime boot machinery, and per-worktree services. The complexity ceiling is: "does this
help a single user edit code faster and more reliably?" If the answer requires a
services architecture, the answer is no.

## One check command

All validation should route through a single aggregate command with named
sub-recipes for fast iteration. Scattered per-tool invocation guides and
prose-only checklists are an anti-pattern: agents and humans diverge, CI
diverges, and the enforcement contract is undefined. Until the runner is in
place, use `docs/workflows.md` as the interim reference. Once the runner exists,
everything wires into it; ADR-001 records the current gate; this principle
governs what is ever considered in scope.

## Docs are maps, not manuals

`CLAUDE.md` is a router (~100 lines). Each doc points to source of truth; it
does not duplicate what the code already says. If a doc restates what a Lua file
says, delete the doc. Progressive disclosure: CLAUDE.md → docs/ → source files.

## Mechanical rules carry remediation and ship with a sanctioned pattern

Every failing check prints what to fix, where, and why; the fix is injected
into agent context automatically. A mechanical ban ships only when a sanctioned
alternative pattern exists and existing violations are migrated. "No rule
without a solution" prevents rules that just bounce the problem back to the
maintainer.

## Optional tools degrade gracefully

A missing optional binary is a skip, not a failure. Only present-but-broken
tooling and config-load errors fail hard. This keeps the config portable across
machines without the full Nix profile.

## Keep enforcement bounded to static checks and headless editor validation

Enforcement belongs in: formatters, linters, structural validators, prose
checks, and headless editor startup. Adding beyond this needs a concrete problem
this repo actually has, not a pattern borrowed from a product-scale codebase.
What is currently in the gate is in ADR-001; this principle governs what is ever
considered.
