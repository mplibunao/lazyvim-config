package main

import "testing"

func TestValidateMessageAcceptsConventionalSubjects(t *testing.T) {
	tests := []string{
		"docs: update workflow guide",
		"feat(nix): add statix guardrail",
		"fix!: remove broken hook path",
		"ci(github-actions)!: tighten gate",
	}
	for _, subject := range tests {
		message := parseCommitMessage(subject + "\n\n# comment ignored")
		if err := validateMessage(message); err != nil {
			t.Fatalf("%q should be valid: %v", subject, err)
		}
	}
}

func TestValidateMessageRejectsInvalidSubjects(t *testing.T) {
	tests := []string{
		"update workflow guide",
		"feature: wrong type",
		"docs update workflow guide",
		"docs(scope with space): bad scope",
		"",
		// Whitespace-only descriptions must be rejected; `.+` would accept these.
		"docs:   ",
		"docs: ",
		"fix(scope):   ",
	}
	for _, subject := range tests {
		message := parseCommitMessage(subject)
		if err := validateMessage(message); err == nil {
			t.Fatalf("%q should be invalid", subject)
		}
	}
}

func TestValidateMessageRejectsEmoji(t *testing.T) {
	tests := []string{
		"docs: ✨ update workflow guide",
		"docs: 🇵🇭 update workflow guide",
		"docs: 1️⃣ update workflow guide",
		"docs: update workflow guide\n\nBody has ✅ emoji",
	}
	for _, input := range tests {
		message := parseCommitMessage(input)
		if err := validateMessage(message); err == nil {
			t.Fatalf("%q should reject emoji", input)
		}
	}
}

func TestParseCommitMessageIgnoresComments(t *testing.T) {
	input := "docs: update workflow guide\n# Please enter the commit message\n\nBody kept\n  # indented comment ignored"
	message := parseCommitMessage(input)
	if message.Subject != "docs: update workflow guide" {
		t.Fatalf("subject = %q", message.Subject)
	}
	if message.Text != "docs: update workflow guide\n\nBody kept" {
		t.Fatalf("text = %q", message.Text)
	}
}

func TestProseTextDropsOnlyTrailingTrailers(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{
			name:  "trailer block is dropped",
			input: "docs: update guide\n\nBody kept.\n\nCo-Authored-By: Some Name <some@example.com>\nSigned-off-by: Other Name <other@example.com>",
			want:  "docs: update guide\n\nBody kept.",
		},
		{
			name:  "body paragraph with a prose line is kept",
			input: "docs: update guide\n\nBody kept.\nNote: still prose",
			want:  "docs: update guide\n\nBody kept.\nNote: still prose",
		},
		{
			name:  "subject alone is kept",
			input: "docs: update guide",
			want:  "docs: update guide",
		},
	}
	for _, test := range tests {
		if got := proseText(test.input); got != test.want {
			t.Fatalf("%s: proseText = %q, want %q", test.name, got, test.want)
		}
	}
}
