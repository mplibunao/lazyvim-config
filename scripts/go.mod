module nvim-lazy/tooling

// Separate from test-fixtures/go (which is a language fixture, not tooling).
// Keep stdlib-only: no go.sum, no vendor dir, no node_modules.
// Current tooling includes the deterministic docs validator plus tests.
// Keep future logic-heavy harness checks here when they can stay stdlib-only.
go 1.22
