package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestValidateDocsAcceptsIndexedDocsAndValidLinks(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "docs/index.md", `# Docs

- [Workflow](workflows.md)
- [Design docs](design-docs/index.md)
- [Decision docs](decisions/index.md)
- [External](https://example.com)
- [Email](mailto:hello@example.com)
- [Anchor](#docs)
- [Home](~/notes/private.md)
- [File URL](file://~/notes/private.md)
`)
	writeFile(t, root, "docs/workflows.md", `# Workflows

See [tooling](design-docs/tooling-policy.md#tools).
`)
	writeFile(t, root, "docs/design-docs/index.md", `# Design docs

- [Tooling policy](tooling-policy.md)
`)
	writeFile(t, root, "docs/design-docs/tooling-policy.md", `# Tooling
`)
	writeFile(t, root, "docs/decisions/index.md", `# Decisions

See [template](template.md).
`)
	writeFile(t, root, "docs/decisions/template.md", `# Template
`)
	writeFile(t, root, "docs/generated/report.md", `# Generated
`)
	writeFile(t, root, "docs/reviews/review.md", `# Review

[broken](missing.md) is ignored because reviews are agent artifacts.
`)

	violations, err := validateDocs(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(violations) != 0 {
		t.Fatalf("expected no violations, got %#v", violations)
	}
}

func TestValidateDocsCountsReferenceUsageButNotUnusedDefinitionAsCoverage(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "docs/index.md", `# Docs

[orphan]: orphan.md
`)
	writeFile(t, root, "docs/orphan.md", `# Orphan
`)

	violations, err := validateDocs(root)
	if err != nil {
		t.Fatal(err)
	}
	assertViolation(t, violations, "docs/orphan.md", "not linked")
	for _, violation := range violations {
		if violation.File == "docs/index.md" {
			t.Fatalf("expected unused reference definition target to remain link-valid, got index violation %#v", violation)
		}
	}

	writeFile(t, root, "docs/index.md", `# Docs

See [the orphan][orphan].

[orphan]: orphan.md
`)
	violations, err = validateDocs(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(violations) != 0 {
		t.Fatalf("expected reference-style usage to cover the target doc, got %#v", violations)
	}
}

func TestValidateDocsReportsOrphanDoc(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "docs/index.md", `# Docs

- [Workflow](workflows.md)
`)
	writeFile(t, root, "docs/workflows.md", `# Workflows
`)
	writeFile(t, root, "docs/orphan.md", `# Orphan
`)

	violations, err := validateDocs(root)
	if err != nil {
		t.Fatal(err)
	}
	assertViolation(t, violations, "docs/orphan.md", "not linked")
}

func TestValidateDocsReportsUnlinkedDirectoryIndex(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "docs/index.md", `# Docs
`)
	writeFile(t, root, "docs/new-area/index.md", `# New area

- [Child](child.md)
`)
	writeFile(t, root, "docs/new-area/child.md", `# Child
`)

	violations, err := validateDocs(root)
	if err != nil {
		t.Fatal(err)
	}
	assertViolation(t, violations, "docs/new-area/index.md", "not linked")
}

func TestValidateDocsIgnoresLinksInsideFencedCodeBlocks(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "docs/index.md", `# Docs

- [Workflow](workflows.md)
`)
	writeFile(t, root, "docs/workflows.md", "# Workflows\n\n```markdown\n[broken](missing.md)\n```\n")

	violations, err := validateDocs(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(violations) != 0 {
		t.Fatalf("expected fenced-code links to be ignored, got %#v", violations)
	}
}

func TestValidateDocsReportsBrokenLocalLink(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "docs/index.md", `# Docs

- [Workflow](workflows.md)
`)
	writeFile(t, root, "docs/workflows.md", `# Workflows

[missing](missing.md)
`)

	violations, err := validateDocs(root)
	if err != nil {
		t.Fatal(err)
	}
	assertViolation(t, violations, "docs/workflows.md", `"missing.md"`)
}

func TestValidateDocsTreatsReferencesAsHandAuthoredDocs(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, ".gitignore", "/references/\n")
	writeFile(t, root, "docs/index.md", `# Docs

- [References](references/index.md)
`)
	writeFile(t, root, "docs/references/index.md", `# References

- [Local copy](local-copy.md)
`)
	writeFile(t, root, "docs/references/local-copy.md", `# Local copy
`)

	violations, err := validateDocs(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(violations) != 0 {
		t.Fatalf("expected docs/references to validate as hand-authored docs, got %#v", violations)
	}
}

func TestValidateDocsExcludesGeneratedAndReviewsFromCoverage(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "docs/index.md", `# Docs
`)
	writeFile(t, root, "docs/generated/report.md", `# Generated
`)
	writeFile(t, root, "docs/reviews/review.md", `# Review
`)

	violations, err := validateDocs(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(violations) != 0 {
		t.Fatalf("expected excluded docs not to require index coverage, got %#v", violations)
	}
}

func assertViolation(t *testing.T, violations []docViolation, file string, messagePart string) {
	t.Helper()
	for _, violation := range violations {
		if violation.File == file && strings.Contains(violation.Message, messagePart) {
			return
		}
	}
	t.Fatalf("expected violation for %s containing %q, got %#v", file, messagePart, violations)
}

func writeFile(t *testing.T, root, rel, content string) {
	t.Helper()
	path := filepath.Join(root, filepath.FromSlash(rel))
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}
