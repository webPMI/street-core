package security

import (
	"strings"
	"testing"
)

// TestEscapeRegex tests the EscapeRegex function for MongoDB regex metacharacter escaping
func TestEscapeRegex(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
		desc     string
	}{
		{
			name:     "empty_string",
			input:    "",
			expected: "",
			desc:     "Empty string should return empty",
		},
		{
			name:     "no_special_chars",
			input:    "username",
			expected: "username",
			desc:     "Normal text without special chars should remain unchanged",
		},
		{
			name:     "email_address",
			input:    "user@example.com",
			expected: "user@example\\.com",
			desc:     "Dot in email should be escaped",
		},
		{
			name:     "wildcard_attack",
			input:    ".*",
			expected: "\\.\\*",
			desc:     "Wildcard regex should be escaped to prevent matching all",
		},
		{
			name:     "full_regex_injection",
			input:    "^admin.*$",
			expected: "\\^admin\\.\\*\\$",
			desc:     "Full regex pattern should be escaped",
		},
		{
			name:     "all_metacharacters",
			input:    ".+*?^${}()[]|\\",
			expected: "\\.\\+\\*\\?\\^\\$\\{\\}\\(\\)\\[\\]\\|\\\\",
			desc:     "All MongoDB regex metacharacters should be escaped",
		},
		{
			name:     "parentheses_attack",
			input:    "(a|b|c){100}",
			expected: "\\(a\\|b\\|c\\)\\{100\\}",
			desc:     "ReDoS attack pattern should be escaped",
		},
		{
			name:     "bracket_attack",
			input:    "[a-z]{1000}",
			expected: "\\[a-z\\]\\{1000\\}",
			desc:     "Character class attack should be escaped",
		},
		{
			name:     "mixed_content",
			input:    "hello.world*test?end",
			expected: "hello\\.world\\*test\\?end",
			desc:     "Mixed normal and special characters",
		},
		{
			name:     "backslash_first",
			input:    "\\test",
			expected: "\\\\test",
			desc:     "Backslash should be escaped first to avoid double-escaping",
		},
		{
			name:     "multiple_backslashes",
			input:    "\\\\\\",
			expected: "\\\\\\\\\\\\",
			desc:     "Multiple backslashes should all be escaped",
		},
		{
			name:     "sql_like_pattern",
			input:    "%admin%",
			expected: "%admin%",
			desc:     "SQL LIKE wildcards (%) are not MongoDB regex metacharacters",
		},
		{
			name:     "unicode_safe",
			input:    "用户.*名",
			expected: "用户\\.\\*名",
			desc:     "Unicode characters should be preserved, regex chars escaped",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := EscapeRegex(tt.input)
			if result != tt.expected {
				t.Errorf("%s: expected '%s', got '%s'", tt.desc, tt.expected, result)
			}
		})
	}
}

// TestSanitizeSearchTerm tests the SanitizeSearchTerm function
func TestSanitizeSearchTerm(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
		desc     string
	}{
		{
			name:     "empty_string",
			input:    "",
			expected: "",
			desc:     "Empty string should return empty",
		},
		{
			name:     "whitespace_only",
			input:    "   \t\n  ",
			expected: "",
			desc:     "Whitespace-only input should return empty",
		},
		{
			name:     "normal_search",
			input:    "bicycle",
			expected: "bicycle",
			desc:     "Normal search term should pass through",
		},
		{
			name:     "trim_whitespace",
			input:    "  skateboard  ",
			expected: "skateboard",
			desc:     "Leading/trailing whitespace should be trimmed",
		},
		{
			name:     "regex_injection",
			input:    "admin.*",
			expected: "admin\\.\\*",
			desc:     "Regex metacharacters should be escaped",
		},
		{
			name:     "exact_max_length",
			input:    strings.Repeat("a", 100),
			expected: strings.Repeat("a", 100),
			desc:     "Input at exact max length (100) should be preserved",
		},
		{
			name:     "exceeds_max_length",
			input:    strings.Repeat("a", 150),
			expected: strings.Repeat("a", 100),
			desc:     "Input exceeding 100 chars should be truncated",
		},
		{
			name:     "unicode_within_limit",
			input:    "用户名称",
			expected: "用户名称",
			desc:     "Unicode search term within limit should be preserved",
		},
		{
			name:     "unicode_exceeds_limit",
			input:    strings.Repeat("用", 120),
			expected: strings.Repeat("用", 100),
			desc:     "Unicode search term exceeding limit should be truncated at rune boundary",
		},
		{
			name:     "complex_regex_attack",
			input:    "^(a+)+$",
			expected: "\\^\\(a\\+\\)\\+\\$",
			desc:     "Complex ReDoS pattern should be fully escaped",
		},
		{
			name:     "email_search",
			input:    "john@example.com",
			expected: "john@example\\.com",
			desc:     "Email search should escape dots",
		},
		{
			name:     "wildcard_search",
			input:    "test*",
			expected: "test\\*",
			desc:     "Wildcard should be escaped",
		},
		{
			name:     "mixed_content",
			input:    "  product (2024)  ",
			expected: "product \\(2024\\)",
			desc:     "Mixed content with special chars and whitespace",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := SanitizeSearchTerm(tt.input)
			if result != tt.expected {
				t.Errorf("%s: expected '%s', got '%s'", tt.desc, tt.expected, result)
			}
		})
	}
}

// TestSanitizeUserInput tests the SanitizeUserInput function
func TestSanitizeUserInput(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
		desc     string
	}{
		{
			name:     "empty_string",
			input:    "",
			expected: "",
			desc:     "Empty string should return empty",
		},
		{
			name:     "normal_text",
			input:    "Hello world",
			expected: "Hello world",
			desc:     "Normal text should pass through",
		},
		{
			name:     "trim_whitespace",
			input:    "  text  ",
			expected: "text",
			desc:     "Leading/trailing whitespace should be trimmed",
		},
		{
			name:     "null_byte_injection",
			input:    "admin\x00.txt",
			expected: "admin.txt",
			desc:     "Null bytes should be removed",
		},
		{
			name:     "multiple_null_bytes",
			input:    "te\x00st\x00ing\x00",
			expected: "testing",
			desc:     "Multiple null bytes should all be removed",
		},
		{
			name:     "multiple_spaces",
			input:    "Hello    world",
			expected: "Hello world",
			desc:     "Multiple spaces should collapse to single space",
		},
		{
			name:     "newlines_preserved",
			input:    "Line 1\nLine 2",
			expected: "Line 1 Line 2",
			desc:     "Newlines should be normalized (collapsed with spaces)",
		},
		{
			name:     "tabs_preserved",
			input:    "Column1\tColumn2",
			expected: "Column1 Column2",
			desc:     "Tabs should be normalized (collapsed with spaces)",
		},
		{
			name:     "zero_width_space",
			input:    "test\u200Bword",
			expected: "testword",
			desc:     "Zero-width space should be removed",
		},
		{
			name:     "zero_width_non_joiner",
			input:    "test\u200Cword",
			expected: "testword",
			desc:     "Zero-width non-joiner should be removed",
		},
		{
			name:     "zero_width_joiner",
			input:    "test\u200Dword",
			expected: "testword",
			desc:     "Zero-width joiner should be removed",
		},
		{
			name:     "byte_order_mark",
			input:    "\uFEFFtest",
			expected: "test",
			desc:     "BOM (Zero-width no-break space) should be removed",
		},
		{
			name:     "control_characters",
			input:    "test\x01\x02\x03word",
			expected: "testword",
			desc:     "Control characters (except newline/tab) should be removed",
		},
		{
			name:     "unicode_text",
			input:    "Café résumé",
			expected: "Café résumé",
			desc:     "Valid Unicode text should be preserved",
		},
		{
			name:     "emoji",
			input:    "Hello 👋 World 🌍",
			expected: "Hello 👋 World 🌍",
			desc:     "Emoji should be preserved",
		},
		{
			name:     "mixed_whitespace",
			input:    "  test  \t\n  word  ",
			expected: "test word",
			desc:     "Mixed whitespace should be collapsed and trimmed",
		},
		{
			name:     "special_unicode_chars",
			input:    "test\u2028word\u2029end",
			expected: "test word end",
			desc:     "Special Unicode line/paragraph separators converted to spaces",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := SanitizeUserInput(tt.input)
			if result != tt.expected {
				t.Errorf("%s:\nexpected: '%s'\ngot:      '%s'", tt.desc, tt.expected, result)
			}
		})
	}
}

// TestValidateMongoID tests the ValidateMongoID function
func TestValidateMongoID(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected bool
		desc     string
	}{
		{
			name:     "valid_lowercase",
			input:    "507f1f77bcf86cd799439011",
			expected: true,
			desc:     "Valid 24-char hex ID (lowercase)",
		},
		{
			name:     "valid_uppercase",
			input:    "507F1F77BCF86CD799439011",
			expected: true,
			desc:     "Valid 24-char hex ID (uppercase)",
		},
		{
			name:     "valid_mixed_case",
			input:    "507f1F77BcF86cD799439011",
			expected: true,
			desc:     "Valid 24-char hex ID (mixed case)",
		},
		{
			name:     "empty_string",
			input:    "",
			expected: false,
			desc:     "Empty string is invalid",
		},
		{
			name:     "too_short",
			input:    "507f1f77bcf86cd79943901",
			expected: false,
			desc:     "23 characters is too short",
		},
		{
			name:     "too_long",
			input:    "507f1f77bcf86cd7994390112",
			expected: false,
			desc:     "25 characters is too long",
		},
		{
			name:     "invalid_characters",
			input:    "507f1f77bcf86cd79943901g",
			expected: false,
			desc:     "Contains invalid hex character 'g'",
		},
		{
			name:     "special_characters",
			input:    "507f1f77bcf86cd799439!@#",
			expected: false,
			desc:     "Contains special characters",
		},
		{
			name:     "sql_injection_attempt",
			input:    "' OR '1'='1",
			expected: false,
			desc:     "SQL injection attempt should fail validation",
		},
		{
			name:     "nosql_injection_attempt",
			input:    "{\"$ne\": null}",
			expected: false,
			desc:     "NoSQL injection attempt should fail validation",
		},
		{
			name:     "spaces",
			input:    "507f1f77 bcf86cd799439011",
			expected: false,
			desc:     "Spaces are invalid",
		},
		{
			name:     "with_prefix",
			input:    "ObjectId(507f1f77bcf86cd799439011)",
			expected: false,
			desc:     "MongoDB ObjectId() wrapper format is invalid",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ValidateMongoID(tt.input)
			if result != tt.expected {
				t.Errorf("%s: expected %v, got %v", tt.desc, tt.expected, result)
			}
		})
	}
}

// Benchmark tests
func BenchmarkEscapeRegex(b *testing.B) {
	input := "^admin.*test@example.com$"
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		EscapeRegex(input)
	}
}

func BenchmarkSanitizeSearchTerm(b *testing.B) {
	input := "  test search term with special chars.*  "
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		SanitizeSearchTerm(input)
	}
}

func BenchmarkSanitizeUserInput(b *testing.B) {
	input := "  User input with\x00null bytes and  multiple   spaces  "
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		SanitizeUserInput(input)
	}
}

func BenchmarkValidateMongoID(b *testing.B) {
	input := "507f1f77bcf86cd799439011"
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		ValidateMongoID(input)
	}
}

// Security-focused test: Verify protection against common NoSQL injection patterns
func TestNoSQLInjectionProtection(t *testing.T) {
	injectionAttempts := []struct {
		name     string
		input    string
		desc     string
		testFunc func(string) string
	}{
		{
			name:     "regex_all_match",
			input:    ".*",
			desc:     "Wildcard to match all documents",
			testFunc: SanitizeSearchTerm,
		},
		{
			name:     "regex_or_operator",
			input:    "admin|user",
			desc:     "OR operator to match multiple patterns",
			testFunc: SanitizeSearchTerm,
		},
		{
			name:     "regex_start_anchor",
			input:    "^admin",
			desc:     "Start anchor to enumerate usernames",
			testFunc: SanitizeSearchTerm,
		},
		{
			name:     "redos_attack",
			input:    "(a+)+b",
			desc:     "ReDoS attack pattern",
			testFunc: SanitizeSearchTerm,
		},
		{
			name:     "null_byte_bypass",
			input:    "admin\x00.txt",
			desc:     "Null byte to bypass file extension checks",
			testFunc: SanitizeUserInput,
		},
	}

	for _, tt := range injectionAttempts {
		t.Run(tt.name, func(t *testing.T) {
			result := tt.testFunc(tt.input)

			// Verify all dangerous regex metacharacters are escaped
			dangerousChars := []string{".*", "^", "$", "|", "(", ")", "+"}
			for _, char := range dangerousChars {
				if strings.Contains(result, char) && !strings.Contains(result, "\\"+char) {
					t.Errorf("%s: Dangerous pattern '%s' not properly escaped in result: %s",
						tt.desc, char, result)
				}
			}

			// Verify null bytes are removed
			if strings.Contains(result, "\x00") {
				t.Errorf("%s: Null byte not removed from result: %v", tt.desc, []byte(result))
			}
		})
	}
}
