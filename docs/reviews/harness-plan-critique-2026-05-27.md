# Critique: Harness-Engineering Adoption Plan (2026-05-27)

**Scope of this review.** Reviews `exec-plans/active/harness-engineering-adoption-2026-05-27.md` against the earlier `context_builder` export (`prompt-exports/oracle-plan-2026-05-27-155722-...md`). The export's narrower "cheap foundation, defer the rest" framing was deliberately overridden by MP at the Phase-5 checkpoint: Selene (Item 3), ast-grep (Item 5), ADRs (Item 7), doc-garden (Item 8), and minimal CI (Item 9) are intentionally pulled in. Those are out of scope for contradiction-flagging here. The export is used only to compare specificity on the foundation items. No scope is added below.

## 1. Top 3 under-specified seams

1. **Item 5 ast-grep starter rules (highest guess risk).** Two of the three named rules do not express as clean AST invariants. Plugin specs are plain `{ "owner/repo", ... }` tables (`lua/plugins/nix.lua:60-85`) with no syntactic marker, so "plugin specs only under `lua/plugins/`" can only be approximated by a heuristic that false-positives on any table with a `"x/y"` string. "Disable only via `disabled.lua`" needs path-scoped exclusion, not a pattern. The plan shows zero concrete patterns and doesn't say which rules are AST-shaped vs. better as regex/shell. An implementer will burn time discovering rule #1 may be the wrong tool.
2. **Item 3 Selene neovim std.** The key file "neovim-std file" is named but undefined: provenance (hand-written vs. community std?) and **global coverage** are left to guess. The plan mentions only the `vim` global, but LazyVim injects `LazyVim`, `Snacks`, and others; a `vim`-only std will false-positive across the tree. `selene.toml`'s `std` reference mechanics are unstated.
3. **Item 9 CI provisioning.** "Nix install, or direct installs" is an unresolved fork bundled with the separate full-vs-subset question. The installer choice (e.g. a Nix installer action vs. apt/curl of stylua/selene/ast-grep/vale/Neovim) and whether CI consumes MP's cross-repo dotfiles flake are all undecided. Item 8's `guardrails/doc-history/policy.json` schema is similarly unspecified (owned by the doc-garden skill, but the plan doesn't point at the schema source), making it a secondary seam.

## 2. Specificity balance

- **Item 5 over-commits while claiming to defer.** It says the catalog is "MP/implementer-owned, grows iteratively" (good) yet prescribes three specific rules, one of which is a poor ast-grep fit. Right level: name the **invariants** to consider and let the implementer pick the mechanism per invariant.
- **Item 9 is pitched correctly** (default = subset, final call deferred), but the breadth decision is stated three times (item body "Decide here", Risks, Open Questions). Trim to one home.
- **Dropped framing the export had:** the export gave a concrete `check-nvim` fixture data-shape (`{ path, filetype, optional_lsp, extra_assertions }`) and an explicit per-fixture timeout (8s). Item 2 compresses this to "timeout-bounded" with no number and no table shape. Re-inlining the data-driven fixture example would cut implementer guesswork at no scope cost.

## 3. Contradictions / missing dependencies (Items 1–10)

1. **Cross-repo Nix provisioning is an unmodeled hard dependency.** Items 3, 5, 8 (and 9) require `selene`/`ast-grep`/`vale` provisioned in the **dotfiles** repo, but provisioning is only a Background/Risk note, not a work item or dependency edge. An agent can start Item 3 and immediately stall. Add an explicit Item 0 (or per-item blocking note).
2. **Item 5 rule #3 fails on a clean tree today.** "No hardcoded `/Users/...`" would flag three intentional, documented lines: `lua/plugins/nix.lua:10` and `lua/plugins/picker.lua:87-88`. This contradicts Item 5 "Done when... a clean tree passes" and Verification #1 (`just check` exits 0). The prior art (surf-cli/claude-toolkit) uses a `baseline.json`, but Item 5 never mentions seeding one. Either baseline/carve-out from day one or drop the rule.
3. **Item 4 coverage scope is ambiguous and collides with Item 8.** Item 4 polices "every `docs/*.md`" (top-level glob) for index-linkage, but Items 7/8/10 assume it polices subdirs (`docs/decisions/`, `docs/references/`). If coverage goes recursive, Item 8's generated `docs/generated/doc-garden/*.md` output becomes orphan failures in the full pre-commit gate. Item 4 needs an explicit `docs/generated/` exclusion and a stated recursive-vs-top-level decision before Item 8 can land.
4. **Minor:** Item 10 finalizes "resolved decisions" but doesn't depend on Item 9, whose full-vs-subset decision is one of them.

## 4. Over-planning risk (brutally honest, for a solo Lua config repo)

The expansion was MP's deliberate call, but for repo size the ROI ranking is uneven:

- **Item 9 (CI) is the weakest item.** For a single-user, single-machine config with a **full** pre-commit gate, CI re-running the deterministic subset mainly guards "MP skipped his own hook." That low-probability case costs a second toolchain to keep in sync plus the flagged-flaky Nix-in-CI bootstrap. The export's TD-005 trigger ("only if shared across machines or PR-reviewed remotely") was right. Recommend: cut to a stub/follow-up, or land subset-only and revisit.
- **Item 8 (doc-garden + Vale) is premature for ~7 docs.** The deterministic validator (Item 4) already covers linkage + link-resolution. The export's TD-004 trigger ("after deterministic validation proves insufficient") was sound. Heavy now.
- **Item 5's full `sg test` + `__snapshots__` harness is sized for surf-cli's dozens of rules,** not 1-3. Building the full apparatus now contradicts the plan's own "start small" principle (TD-002). Land the genuinely-structural rule(s) lean; defer the snapshot harness until the catalog grows.
- **Keep:** Item 7 (ADR layer) is genuinely cheap and MP values it; Item 3 (Selene) earns its keep as a real linter. **Watch:** the full headless-nvim gate on *every* commit (incl. docs-only commits) is multi-second friction that invites `--no-verify`, which then makes CI the real gate. MP accepted this; flagging the friction-to-bypass loop, not relitigating.

## 5. Questions that would change implementation order

1. **Is the cross-repo Nix provisioning (selene/ast-grep/vale) already done?** If not, an Item 0 provisioning step must front-run Items 3/5/8/9. (Biggest order lever.)
2. **CI breadth: full or subset?** "Subset" keeps Item 9 small and movable right after Item 5; "full" pulls in the lazy.nvim bootstrap/cache sub-task and slips Item 9 later.
3. **Item 4 coverage: top-level or recursive, and is `docs/generated/` excluded?** Determines whether Item 4 must ship the exclusion **before** Item 8 (and 7) can land without breaking the hook.
4. **Can ast-grep express the plugin-spec-location rule for Lua at all?** If not, Item 5 shrinks (drop/relocate rule #1), which makes it smaller and possibly earlier, and changes whether the snapshot harness is worth standing up now.
