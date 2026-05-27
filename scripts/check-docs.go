package main

import (
	"errors"
	"flag"
	"fmt"
	"io/fs"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

type docViolation struct {
	File    string
	Message string
	Fix     string
}

func main() {
	root := flag.String("root", "..", "repository root")
	flag.Parse()

	violations, err := validateDocs(*root)
	if err != nil {
		fmt.Fprintf(os.Stderr, "docs: %v\n", err)
		os.Exit(1)
	}
	if len(violations) > 0 {
		fmt.Fprintln(os.Stderr, "docs: validation failed")
		for _, violation := range violations {
			fmt.Fprintf(os.Stderr, "- %s: %s\n  Fix: %s\n", violation.File, violation.Message, violation.Fix)
		}
		os.Exit(1)
	}
	fmt.Println("docs: ok")
}

func validateDocs(root string) ([]docViolation, error) {
	absRoot, err := filepath.Abs(root)
	if err != nil {
		return nil, err
	}
	info, err := os.Stat(absRoot)
	if err != nil {
		return nil, err
	}
	if !info.IsDir() {
		return nil, fmt.Errorf("root is not a directory: %s", absRoot)
	}

	docsDir := filepath.Join(absRoot, "docs")
	if info, err := os.Stat(docsDir); err != nil {
		return nil, err
	} else if !info.IsDir() {
		return nil, errors.New("docs path is not a directory")
	}

	docFiles, err := collectHandAuthoredDocFiles(absRoot)
	if err != nil {
		return nil, err
	}
	parsedDocs, err := parseDocs(absRoot, docFiles)
	if err != nil {
		return nil, err
	}
	docSet := makeDocSet(docFiles)
	linkViolations := validateLocalLinks(absRoot, parsedDocs)
	covered := deriveCoverage(absRoot, parsedDocs, docSet)

	violations := append([]docViolation{}, linkViolations...)
	for _, doc := range docFiles {
		if doc == "docs/index.md" {
			continue
		}
		if !covered[doc] {
			violations = append(violations, docViolation{
				File:    doc,
				Message: "hand-authored doc is not linked from docs/index.md or a directory-level index.md",
				Fix:     "add a Markdown link to this doc from docs/index.md or from the nearest docs/**/index.md",
			})
		}
	}
	sortViolations(violations)
	return violations, nil
}

func collectHandAuthoredDocFiles(root string) ([]string, error) {
	docsDir := filepath.Join(root, "docs")
	var files []string
	err := filepath.WalkDir(docsDir, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if isExcludedDocsDir(root, path) {
				return filepath.SkipDir
			}
			return nil
		}
		if strings.EqualFold(filepath.Ext(path), ".md") {
			rel, err := filepath.Rel(root, path)
			if err != nil {
				return err
			}
			files = append(files, filepath.ToSlash(rel))
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	sort.Strings(files)
	return files, nil
}

func isExcludedDocsDir(root, path string) bool {
	rel, err := filepath.Rel(root, path)
	if err != nil {
		return false
	}
	rel = filepath.ToSlash(rel)
	return rel == "docs/generated" || strings.HasPrefix(rel, "docs/generated/") || rel == "docs/reviews" || strings.HasPrefix(rel, "docs/reviews/")
}

type parsedDoc struct {
	relPath string
	links   markdownLinks
}

func makeDocSet(docFiles []string) map[string]bool {
	docSet := make(map[string]bool, len(docFiles))
	for _, doc := range docFiles {
		docSet[doc] = true
	}
	return docSet
}

func parseDocs(root string, docFiles []string) ([]parsedDoc, error) {
	parsedDocs := make([]parsedDoc, 0, len(docFiles))
	for _, relDoc := range docFiles {
		content, err := os.ReadFile(filepath.Join(root, filepath.FromSlash(relDoc)))
		if err != nil {
			return nil, err
		}
		parsedDocs = append(parsedDocs, parsedDoc{
			relPath: relDoc,
			links:   extractMarkdownLinks(stripFencedCodeBlocks(string(content))),
		})
	}
	return parsedDocs, nil
}

func validateLocalLinks(root string, parsedDocs []parsedDoc) []docViolation {
	var violations []docViolation
	for _, doc := range parsedDocs {
		for _, rawTarget := range doc.links.validationTargets() {
			if shouldIgnoreLink(rawTarget) {
				continue
			}
			if _, err := resolveLocalLink(root, doc.relPath, rawTarget); err != nil {
				violations = append(violations, docViolation{
					File:    doc.relPath,
					Message: fmt.Sprintf("local Markdown link %q is invalid: %v", rawTarget, err),
					Fix:     "point the link at an existing repository file or remove the stale link",
				})
			}
		}
	}
	return violations
}

func deriveCoverage(root string, parsedDocs []parsedDoc, docSet map[string]bool) map[string]bool {
	covered := make(map[string]bool)
	for _, doc := range parsedDocs {
		if filepath.Base(doc.relPath) != "index.md" {
			continue
		}
		for _, rawTarget := range doc.links.coverageTargets() {
			if shouldIgnoreLink(rawTarget) {
				continue
			}
			resolved, err := resolveLocalLink(root, doc.relPath, rawTarget)
			if err == nil && docSet[resolved] {
				covered[resolved] = true
			}
		}
	}
	return covered
}

var inlineLinkPattern = regexp.MustCompile(`!?\[[^\]\n]*\]\(([^)\n]+)\)`)
var referenceUsagePattern = regexp.MustCompile(`!?\[([^\]\n]+)\]\[([^\]\n]*)\]`)
var referenceDefinitionPattern = regexp.MustCompile(`(?m)^\s{0,3}\[([^\]\n]+)\]:\s+(\S+)`)

type markdownLinks struct {
	inlineTargets        []string
	referenceUsageIDs    []string
	referenceDefinitions map[string]string
	definitionTargets    []string
}

func stripFencedCodeBlocks(content string) string {
	var kept []string
	inFence := false
	fenceMarker := ""
	for _, line := range strings.Split(content, "\n") {
		trimmed := strings.TrimLeft(line, " \t")
		marker := ""
		if strings.HasPrefix(trimmed, "```") {
			marker = "```"
		} else if strings.HasPrefix(trimmed, "~~~") {
			marker = "~~~"
		}
		if marker != "" {
			if !inFence {
				inFence = true
				fenceMarker = marker
				continue
			}
			if marker == fenceMarker {
				inFence = false
				fenceMarker = ""
				continue
			}
		}
		if !inFence {
			kept = append(kept, line)
		}
	}
	return strings.Join(kept, "\n")
}

func extractMarkdownLinks(content string) markdownLinks {
	links := markdownLinks{
		referenceDefinitions: make(map[string]string),
	}
	for _, match := range inlineLinkPattern.FindAllStringSubmatch(content, -1) {
		links.inlineTargets = append(links.inlineTargets, cleanMarkdownTarget(match[1]))
	}
	for _, match := range referenceUsagePattern.FindAllStringSubmatch(content, -1) {
		id := match[2]
		if id == "" {
			id = match[1]
		}
		links.referenceUsageIDs = append(links.referenceUsageIDs, normalizeReferenceID(id))
	}
	for _, match := range referenceDefinitionPattern.FindAllStringSubmatch(content, -1) {
		id := normalizeReferenceID(match[1])
		target := cleanMarkdownTarget(match[2])
		links.referenceDefinitions[id] = target
		links.definitionTargets = append(links.definitionTargets, target)
	}
	return links
}

func (links markdownLinks) validationTargets() []string {
	all := append([]string{}, links.inlineTargets...)
	all = append(all, links.definitionTargets...)
	return all
}

func (links markdownLinks) coverageTargets() []string {
	targets := append([]string{}, links.inlineTargets...)
	for _, id := range links.referenceUsageIDs {
		if target, ok := links.referenceDefinitions[id]; ok {
			targets = append(targets, target)
		}
	}
	return targets
}

func normalizeReferenceID(id string) string {
	return strings.ToLower(strings.Join(strings.Fields(id), " "))
}

func cleanMarkdownTarget(target string) string {
	target = strings.TrimSpace(target)
	if strings.HasPrefix(target, "<") {
		if end := strings.Index(target, ">"); end >= 0 {
			return strings.TrimSpace(target[1:end])
		}
	}
	if idx := strings.IndexAny(target, " \t"); idx >= 0 {
		target = target[:idx]
	}
	return strings.TrimSpace(target)
}

func shouldIgnoreLink(target string) bool {
	if target == "" || strings.HasPrefix(target, "#") || strings.HasPrefix(target, "~") {
		return true
	}
	lower := strings.ToLower(target)
	if strings.HasPrefix(lower, "mailto:") {
		return true
	}
	parsed, err := url.Parse(target)
	return err == nil && parsed.Scheme != ""
}

func resolveLocalLink(root, sourceRel, target string) (string, error) {
	withoutFragment := target
	if idx := strings.IndexAny(withoutFragment, "#?"); idx >= 0 {
		withoutFragment = withoutFragment[:idx]
	}
	if withoutFragment == "" {
		return "", nil
	}

	candidate := filepath.Clean(filepath.Join(root, filepath.Dir(filepath.FromSlash(sourceRel)), filepath.FromSlash(withoutFragment)))
	rootWithSep := filepath.Clean(root) + string(os.PathSeparator)
	if candidate != filepath.Clean(root) && !strings.HasPrefix(candidate, rootWithSep) {
		return "", fmt.Errorf("target escapes the repository root: %s", target)
	}

	info, err := os.Stat(candidate)
	if err != nil {
		return "", err
	}
	if info.IsDir() {
		candidate = filepath.Join(candidate, "index.md")
		if _, err := os.Stat(candidate); err != nil {
			return "", fmt.Errorf("directory link has no index.md: %w", err)
		}
	}
	rel, err := filepath.Rel(root, candidate)
	if err != nil {
		return "", err
	}
	return filepath.ToSlash(rel), nil
}

func sortViolations(violations []docViolation) {
	sort.Slice(violations, func(i, j int) bool {
		if violations[i].File != violations[j].File {
			return violations[i].File < violations[j].File
		}
		return violations[i].Message < violations[j].Message
	})
}
