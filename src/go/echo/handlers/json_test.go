package handlers

import (
	"encoding/json"
	"testing"
)

// Pins the canonical /json payload. See contracts/rest/canonical-payloads.md.
// Before this contract every language returned a different object, so the
// /json ranking compared different workloads over different amounts of wire.

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
		got, err := json.Marshal(newJSONItem(tc.id))
		if err != nil {
			t.Fatalf("id=%d: marshal failed: %v", tc.id, err)
		}
		if string(got) != tc.want {
			t.Errorf("id=%d diverges from contract; want %s got %s", tc.id, tc.want, got)
		}
	}
}

func TestItemCountHonoursQueryParam(t *testing.T) {
	cases := []struct {
		raw  string
		want int
	}{
		{"", defaultJSONItems},
		{"10", 10},
		{"100", 100},
		{"1000", 1000},
		{"abc", defaultJSONItems},
		{"-5", defaultJSONItems},
		{"999999", maxJSONItems},
	}
	for _, tc := range cases {
		if got := itemCount(tc.raw); got != tc.want {
			t.Errorf("itemCount(%q) = %d, want %d", tc.raw, got, tc.want)
		}
	}
}

func TestBuildItemsIsDeterministic(t *testing.T) {
	first, _ := json.Marshal(buildItems(50))
	second, _ := json.Marshal(buildItems(50))
	if string(first) != string(second) {
		t.Error("buildItems is not deterministic; the payload cannot be parity-hashed")
	}
}
