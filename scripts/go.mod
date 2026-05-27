module nvim-lazy/tooling

// Separate from test-fixtures/go (which is a language fixture, not tooling).
// Keep stdlib-only: no go.sum, no vendor dir, no node_modules.
// The doc validator and other logic-heavy checks land here in later items
// (see exec-plans/active/harness-engineering-adoption-2026-05-27.md, Item 4).
go 1.22
