package models

import "fmt"

// canonicalCreatedAt is fixed by contract. A per-request timestamp would make
// the payload non-deterministic and therefore impossible to parity-hash.
const canonicalCreatedAt = "2026-01-01T00:00:00Z"

// JSONItem is the canonical /json payload item.
//
// See contracts/rest/canonical-payloads.md. The shape matches JsonItem in
// contracts/grpc/benchmark.proto and contracts/graphql/schema.graphql so all
// three protocols serialize the same data.
type JSONItem struct {
	ID        int    `json:"id"`
	UUID      string `json:"uuid"`
	Name      string `json:"name"`
	Email     string `json:"email"`
	CreatedAt string `json:"createdAt"`
	IsActive  bool   `json:"isActive"`
}

// NewJSONItem builds item i. Content is a pure function of the index: no
// randomness and no wall-clock, so the payload is stable across runs and
// identical across languages.
//
// The previous version generated 16 bytes of crypto/rand per item -- 16 KB of
// CSPRNG per request -- which is real work no other implementation did, and it
// formatted the id with string(rune(id)), producing a NUL byte for id 0 and
// multi-byte UTF-8 for ids >= 128 rather than the decimal text.
func NewJSONItem(id int) *JSONItem {
	return &JSONItem{
		ID:        id,
		UUID:      fmt.Sprintf("00000000-0000-0000-0000-%012d", id),
		Name:      fmt.Sprintf("Item %d", id),
		Email:     fmt.Sprintf("item%d@benchmark.local", id),
		CreatedAt: canonicalCreatedAt,
		IsActive:  id%2 == 0,
	}
}
