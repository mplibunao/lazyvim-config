package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

var allowedTypes = []string{"feat", "fix", "docs", "refactor", "test", "chore", "style", "perf", "ci", "build"}

// \S ensures the description contains at least one non-space character;
// `: .+` would accept whitespace-only descriptions like "docs:   ".
var conventionalSubject = regexp.MustCompile(`^(` + strings.Join(allowedTypes, `|`) + `)(\([a-z0-9._/-]+\))?!?: \S.*`)

var emojiPattern = regexp.MustCompile(`(?:[\x{1F1E6}-\x{1F1FF}]{2}|[#*0-9]\x{FE0F}?\x{20E3}|[\x{1F300}-\x{1FAFF}\x{2700}-\x{27BF}\x{2600}-\x{26FF}]\x{FE0F}?)`)

type commitMessage struct {
	Subject string
	// Text is the full non-comment message content (subject + blank line + body).
	Text string
}

func parseCommitMessage(input string) commitMessage {
	lines := strings.Split(input, "\n")
	nonComment := make([]string, 0, len(lines))
	for _, line := range lines {
		if strings.HasPrefix(strings.TrimLeft(line, " \t"), "#") {
			continue
		}
		nonComment = append(nonComment, line)
	}

	subject := ""
	if len(nonComment) > 0 {
		subject = nonComment[0]
	}
	return commitMessage{Subject: subject, Text: strings.Join(nonComment, "\n")}
}

func validateMessage(message commitMessage) error {
	if strings.TrimSpace(message.Subject) == "" {
		return fmt.Errorf("empty commit subject")
	}
	if !conventionalSubject.MatchString(message.Subject) {
		return fmt.Errorf("subject must use conventional commit format without emoji.\n\n"+
			"Expected:\n  <type>[optional-scope][!]: <description>\n\n"+
			"Allowed types:\n  %s\n\n"+
			"Examples:\n  docs: update workflow guide\n  feat(nix): add statix guardrail", strings.Join(allowedTypes, ", "))
	}
	if emojiPattern.MatchString(message.Text) {
		return fmt.Errorf("emoji are not allowed in commit messages")
	}
	return nil
}

func run(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// runVale lints the commit message through Vale using the repo-local .vale.ini.
// The message is written to a temp *.md file so [*.md] rules from .vale.ini apply.
// There is no [COMMIT_EDITMSG] section; ai-tells-commits is intentionally not loaded.
func runVale(repoRoot string, message commitMessage) error {
	tmp, err := os.CreateTemp("", "nvim-lazy-commit-msg-*.md")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())

	if _, err := tmp.WriteString(message.Text + "\n"); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}

	setupPath := filepath.Join(repoRoot, "scripts", "setup-vale.sh")
	if err := run("sh", setupPath); err != nil {
		return fmt.Errorf("setup Vale: %w", err)
	}
	configPath := filepath.Join(repoRoot, ".vale.ini")
	if err := run("vale", "--no-global", "--config", configPath, "--minAlertLevel=error", tmp.Name()); err != nil {
		return fmt.Errorf("vale commit message check: %w", err)
	}
	return nil
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "commit-msg: usage: commitmsg <repo-root> <message-file>")
		os.Exit(2)
	}
	repoRoot, err := filepath.Abs(os.Args[1])
	if err != nil {
		fmt.Fprintf(os.Stderr, "commit-msg: resolve repo root: %v\n", err)
		os.Exit(2)
	}
	messageFile, err := filepath.Abs(os.Args[2])
	if err != nil {
		fmt.Fprintf(os.Stderr, "commit-msg: resolve message file: %v\n", err)
		os.Exit(2)
	}
	content, err := os.ReadFile(messageFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "commit-msg: read message file: %v\n", err)
		os.Exit(2)
	}

	message := parseCommitMessage(string(content))
	if err := validateMessage(message); err != nil {
		fmt.Fprintf(os.Stderr, "commit-msg: %v\n", err)
		os.Exit(1)
	}
	if err := runVale(repoRoot, message); err != nil {
		fmt.Fprintf(os.Stderr, "commit-msg: %v\n", err)
		os.Exit(1)
	}
}
