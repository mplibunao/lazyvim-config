package main

import "testing"

// TestGoSubstrate proves the stdlib-only harness package compiles alongside
// the docs validator tests.
func TestGoSubstrate(t *testing.T) {
	// Nothing to assert here. The value is that go test ./... exits 0,
	// proving the module structure and toolchain integration work.
}
