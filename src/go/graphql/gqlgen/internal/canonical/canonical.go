// Package canonical holds the /json payload contract.
// See contracts/rest/canonical-payloads.md.
//
// The gRPC and GraphQL item types are generated per implementation, so this
// package exposes the field values rather than a struct: every implementation
// builds its own type from the same numbers.
//
// Item content is a pure function of the index -- no randomness and no wall
// clock -- so the payload is stable across runs and identical across
// languages and protocols.
package canonical

import "fmt"

const (
	DefaultItems = 1000
	MaxItems     = 10000
	// CreatedAt is fixed by the contract: reading the clock once per item is
	// work no implementation should be timed on.
	CreatedAt = "2026-01-01T00:00:00Z"
)

func UUID(i int) string { return fmt.Sprintf("00000000-0000-0000-0000-%012d", i) }

func Name(i int) string { return fmt.Sprintf("Item %d", i) }

func Email(i int) string { return fmt.Sprintf("item%d@benchmark.local", i) }

func IsActive(i int) bool { return i%2 == 0 }

// ItemCount clamps the requested limit. On a 1 GbE link 1000 items is
// network-bound, so the serialization ranking is taken at 100.
func ItemCount(limit int) int {
	if limit <= 0 {
		return DefaultItems
	}
	if limit > MaxItems {
		return MaxItems
	}
	return limit
}
