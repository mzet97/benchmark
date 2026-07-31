package models

import (
	"encoding/json"
	"testing"
)

// The canonical payload is normative: contracts/rest/canonical-payloads.md.
// These tests exist because the previous implementation silently diverged from
// every other language -- different fields, 45% more bytes, and 16 KB of
// crypto/rand per request -- which made the /json ranking meaningless.

func TestNewJSONItemMatchesContract(t *testing.T) {
	cases := []struct {
		id   int
		want string
	}{
		{0, `{"id":0,"uuid":"00000000-0000-0000-0000-000000000000","name":"Item 0","email":"item0@benchmark.local","createdAt":"2026-01-01T00:00:00Z","isActive":true}`},
		{1, `{"id":1,"uuid":"00000000-0000-0000-0000-000000000001","name":"Item 1","email":"item1@benchmark.local","createdAt":"2026-01-01T00:00:00Z","isActive":false}`},
		{999, `{"id":999,"uuid":"00000000-0000-0000-0000-000000000999","name":"Item 999","email":"item999@benchmark.local","createdAt":"2026-01-01T00:00:00Z","isActive":false}`},
	}

	for _, tc := range cases {
		got, err := json.Marshal(NewJSONItem(tc.id))
		if err != nil {
			t.Fatalf("id=%d: marshal failed: %v", tc.id, err)
		}
		if string(got) != tc.want {
			t.Errorf("id=%d payload diverges from contract\n want %s\n  got %s",
				tc.id, tc.want, got)
		}
	}
}

// id >= 128 is the case the old string(rune(id)) formatting broke: it emitted
// multi-byte UTF-8 for the code point instead of the decimal text, and a NUL
// byte for id 0.
func TestNewJSONItemFormatsIDAsDecimal(t *testing.T) {
	for _, id := range []int{0, 65, 128, 4096} {
		item := NewJSONItem(id)
		want := "Item " + itoa(id)
		if item.Name != want {
			t.Errorf("id=%d: Name = %q, want %q", id, item.Name, want)
		}
		for _, r := range item.Name {
			if r == 0 {
				t.Errorf("id=%d: Name contains a NUL byte: %q", id, item.Name)
			}
		}
	}
}

// Determinism is what makes the payload parity-hashable across languages.
func TestNewJSONItemIsDeterministic(t *testing.T) {
	for _, id := range []int{0, 7, 512} {
		first, _ := json.Marshal(NewJSONItem(id))
		second, _ := json.Marshal(NewJSONItem(id))
		if string(first) != string(second) {
			t.Errorf("id=%d is not deterministic:\n first  %s\n second %s",
				id, first, second)
		}
	}
}

func itoa(i int) string {
	if i == 0 {
		return "0"
	}
	var buf [20]byte
	pos := len(buf)
	for i > 0 {
		pos--
		buf[pos] = byte('0' + i%10)
		i /= 10
	}
	return string(buf[pos:])
}
