# Changelog

All major changes to this repository are documented here.

This repo is a personal Neovim config rather than a published library, so entries are grouped by workflow milestones instead of release tags.

## Unreleased

### Added

- Added this changelog as the root history file for repo-wide milestones.

## 2026-05-29: Mise harness toolchain + changelog

### Added

- Added a manually maintained changelog for major nvim-lazy workflow milestones.

### Changed

- Completed the migration of harness gate tools to repo-local mise pins so local checks and CI use one version source. See [`exec-plans/completed/mise-tooling-and-changelog-2026-05-29.md`](exec-plans/completed/mise-tooling-and-changelog-2026-05-29.md).

## 2026-05-28: Harness engineering adoption

### Added

- Added the mechanical validation harness for this LazyVim config, including `just` gates, Lua formatting and linting, docs validation, ast-grep guardrails, Vale prose checks, Git hooks, and CI. See [`exec-plans/completed/harness-engineering-adoption-2026-05-27.md`](exec-plans/completed/harness-engineering-adoption-2026-05-27.md).

### Changed

- Reorganized durable documentation around `ARCHITECTURE.md`, `docs/design-docs/`, `docs/decisions/`, and `exec-plans/` so agents can find current-state guidance and historical decisions quickly.

### Fixed

- Hardened config validation around home-path literals, documentation links, prose quality, and LazyVim plugin-disable placement.
