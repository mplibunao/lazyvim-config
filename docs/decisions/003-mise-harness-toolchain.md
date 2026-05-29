# ADR-003: Mise harness toolchain

**Status:** accepted
**Date:** 2026-05-29

## Context

The harness gate depends on exact versions of `stylua`, `selene`, the `vale`
binary, `ast-grep`, Go, and `just`. Before this decision, CI installed most of
those tools through one-off workflow steps while local runs used globally
provisioned Nix tools. That split duplicated version truth and made local and CI
behavior vulnerable to drift.

TD-008 in `exec-plans/tech-debt-tracker.md` records the debt: harness gate tools
need a repo-local source of truth when their versions determine pass or fail
behavior. The mise tooling plan extends that rule to `just` as well, because the
runner itself can break the gate if a global Nix update changes its behavior.

Go also needed an explicit decision. The previous `scripts/go.mod` floor came
from older work tooling, not from this repo's harness needs. The harness should
run on a current repo-pinned Go toolchain, and Go must not self-download a newer
toolchain that bypasses the repo pin.

## Decision

Use mise as the repo-local source of truth for harness gate tools:

- `stylua`
- `selene`
- `vale` binary only
- `ast-grep` through the `sg` binary
- Go
- `just`

Nix remains responsible for baseline machine availability, including installing
mise and putting mise shims on PATH. Inside this repo, mise shims should win so
local hooks, local `just` runs, and CI all resolve the same tool versions.

Pin Go to `1.26` in mise, raise the harness Go module floor to `go 1.26`, and
set `GOTOOLCHAIN=local`. `GOTOOLCHAIN=local` keeps the mise-managed Go version
authoritative by making unexpected toolchain drift fail instead of silently
downloading a different Go release.

Keep Vale style packages out of mise. mise owns the `vale` executable only;
`styles/`, `.vale.ini`, and `scripts/setup-vale.sh` continue to own style package
sync and caching.

## Alternatives considered

**Keep manual CI installs and Nix-local tools.** This preserves the existing
workflow shape but leaves two version authorities. It also keeps CI provisioning
spread across curl, npm, setup-go, and setup-just steps. Rejected because the
harness gate needs one repo-local source of truth.

**Use Nix in CI for all gate tools.** This would align CI with the user's machine
profile, but it makes a personal system flake the gate's version authority and
adds more CI bootstrap weight than this repo needs. Rejected because the harness
should be portable from the repo checkout.

**Use a `.tool-versions` plus lockfile-only `mise.toml` split.** This matches
another private repo pattern and is compatible with mise, but it spreads a small
toolchain across two config files. Rejected in favor of a single `mise.toml` with
a committed `mise.lock`.

## Consequences

- Local and CI harness gates use one repo-pinned toolchain.
- Global Nix updates should not change `just check`, `just ci`, or git hook
  behavior inside this repo.
- Nix still matters as the bootstrap and availability layer for mise and its
  shims.
- `gofmt`, `go vet`, and `go test` follow the repo-pinned Go SDK instead of a
  global Go installation.
- Go 1.26 may surface new `gofmt`, `go vet`, or test behavior. That is accepted
  because the harness should track a supported toolchain.
- Vale style package behavior remains separate from the Vale binary pin, so
  style cache invalidation still follows `.vale.ini`, the setup script, and the
  tracked vocabulary files.

## Migration

Add `mise.toml` with tool pins and `[settings] lockfile = true`, then generate
and commit `mise.lock` from mise. Run `mise install` locally and configure CI to
install from the same files with frozen lockfile behavior.

Update `scripts/go.mod` to `go 1.26` and set `GOTOOLCHAIN=local` in the mise
environment. Keep `gofmt` implicit because it ships with the Go SDK.

Update local setup guidance to say `mise trust` and `mise install` prepare the
repo-local gate tools. Keep Nix guidance only as the bootstrap path for mise and
as the source for editor and machine-baseline tools.

## Risks

- **Hook PATH drift.** Git hooks run in a non-interactive environment. If mise
  shims are not on PATH, hooks can fall back to global tools. Verify with a real
  commit-path probe, not only by running hooks from an activated shell.
- **Lockfile drift.** Tool pin changes without a matching `mise.lock` update
  should fail in CI through frozen mise behavior.
- **Go toolchain behavior changes.** Go 1.26 can introduce stricter vet checks or
  changed formatting. Treat failures from `just fmt`, `just vet`, or `just test`
  as real migration findings.
- **Vale scope confusion.** mise does not own Vale style packages. If prose rules
  change unexpectedly, inspect `.vale.ini`, `styles/`, and `scripts/setup-vale.sh`
  before changing mise pins.
