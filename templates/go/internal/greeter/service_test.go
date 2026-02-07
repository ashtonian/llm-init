package greeter_test

import (
	"context"
	"testing"

	"{{PROJECT_MODULE}}/internal/greeter"
)

// newTestService is a helper that creates a service backed by the
// in-memory repository — no infrastructure needed.
func newTestService(t *testing.T, opts ...greeter.Option) *greeter.Service {
	t.Helper()
	defaults := []greeter.Option{
		greeter.WithRepository(greeter.NewMemoryRepository()),
	}
	svc, err := greeter.NewService(append(defaults, opts...)...)
	if err != nil {
		t.Fatalf("NewService: %v", err)
	}
	return svc
}

func TestService_Create(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name      string
		input     greeter.CreateInput
		opts      []greeter.Option
		wantMsg   string
		wantErr   bool
	}{
		{
			name:    "valid greeting defaults to english",
			input:   greeter.CreateInput{Name: "World"},
			wantMsg: "Hello, World!",
		},
		{
			name:    "spanish greeting",
			input:   greeter.CreateInput{Name: "Mundo", Language: "es"},
			wantMsg: "¡Hola, Mundo!",
		},
		{
			name:    "french greeting",
			input:   greeter.CreateInput{Name: "Monde", Language: "fr"},
			wantMsg: "Bonjour, Monde!",
		},
		{
			name:    "service-level default language",
			input:   greeter.CreateInput{Name: "Mundo"},
			opts:    []greeter.Option{greeter.WithDefaultLanguage("es")},
			wantMsg: "¡Hola, Mundo!",
		},
		{
			name:    "empty name is rejected",
			input:   greeter.CreateInput{Name: ""},
			wantErr: true,
		},
		{
			name:    "name too long is rejected",
			input:   greeter.CreateInput{Name: string(make([]byte, 201))},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			svc := newTestService(t, tt.opts...)
			ctx := context.Background()

			got, err := svc.Create(ctx, tt.input)
			if tt.wantErr {
				if err == nil {
					t.Fatal("expected error, got nil")
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got.Message != tt.wantMsg {
				t.Errorf("message = %q, want %q", got.Message, tt.wantMsg)
			}
			if got.ID == "" {
				t.Error("expected non-empty ID")
			}
			if got.CreatedAt.IsZero() {
				t.Error("expected non-zero CreatedAt")
			}
		})
	}
}

func TestService_Get(t *testing.T) {
	t.Parallel()
	svc := newTestService(t)
	ctx := context.Background()

	created, err := svc.Create(ctx, greeter.CreateInput{Name: "Alice"})
	if err != nil {
		t.Fatalf("Create: %v", err)
	}

	got, err := svc.Get(ctx, created.ID)
	if err != nil {
		t.Fatalf("Get: %v", err)
	}
	if got.Name != "Alice" {
		t.Errorf("name = %q, want %q", got.Name, "Alice")
	}

	// Not found
	_, err = svc.Get(ctx, "nonexistent")
	if err == nil {
		t.Fatal("expected error for nonexistent ID")
	}

	// Empty ID
	_, err = svc.Get(ctx, "")
	if err == nil {
		t.Fatal("expected error for empty ID")
	}
}

func TestService_List(t *testing.T) {
	t.Parallel()
	svc := newTestService(t)
	ctx := context.Background()

	// Empty list
	items, err := svc.List(ctx)
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(items) != 0 {
		t.Fatalf("expected 0 items, got %d", len(items))
	}

	// After creating two
	if _, err := svc.Create(ctx, greeter.CreateInput{Name: "A"}); err != nil {
		t.Fatalf("Create: %v", err)
	}
	if _, err := svc.Create(ctx, greeter.CreateInput{Name: "B"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	items, err = svc.List(ctx)
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(items) != 2 {
		t.Fatalf("expected 2 items, got %d", len(items))
	}
}

func TestNewService_Validation(t *testing.T) {
	t.Parallel()

	// Missing repository
	_, err := greeter.NewService()
	if err == nil {
		t.Fatal("expected error without repository")
	}

	// Nil repository
	_, err = greeter.NewService(greeter.WithRepository(nil))
	if err == nil {
		t.Fatal("expected error with nil repository")
	}

	// Empty language
	_, err = greeter.NewService(
		greeter.WithRepository(greeter.NewMemoryRepository()),
		greeter.WithDefaultLanguage(""),
	)
	if err == nil {
		t.Fatal("expected error with empty language")
	}
}
