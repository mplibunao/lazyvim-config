// Package tooling contains Go-based check scripts for the nvim-lazy harness.
//
// The footprint is intentionally minimal: stdlib-only, no external deps,
// so gofmt/go vet/go test are the only tools needed. Real check logic lands
// in later items (scripts/check-docs.go in Item 4; see the exec-plan).
package tooling
