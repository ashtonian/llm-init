package greeter

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// Repository defines the data-access contract. Implementations must be
// safe for concurrent use.
type Repository interface {
	Store(ctx context.Context, g Greeting) error
	FindByID(ctx context.Context, id string) (Greeting, error)
	List(ctx context.Context) ([]Greeting, error)
}

// MemoryRepository is an in-memory Repository suitable for tests and
// local development. It requires no infrastructure.
type MemoryRepository struct {
	mu    sync.RWMutex
	items map[string]Greeting
}

// NewMemoryRepository returns a ready-to-use in-memory repository.
func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{items: make(map[string]Greeting)}
}

func (r *MemoryRepository) Store(_ context.Context, g Greeting) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.items[g.ID] = g
	return nil
}

func (r *MemoryRepository) FindByID(_ context.Context, id string) (Greeting, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	g, ok := r.items[id]
	if !ok {
		return Greeting{}, fmt.Errorf("greeting %q not found", id)
	}
	return g, nil
}

func (r *MemoryRepository) List(_ context.Context) ([]Greeting, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]Greeting, 0, len(r.items))
	for _, g := range r.items {
		out = append(out, g)
	}
	return out, nil
}

// generateID produces a simple time-based ID. Replace with UUIDv7 in
// production (e.g., github.com/google/uuid).
func generateID() string {
	return fmt.Sprintf("%d", time.Now().UnixNano())
}
