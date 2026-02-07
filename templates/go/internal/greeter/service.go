package greeter

import (
	"context"
	"errors"
	"fmt"
	"time"
)

// Service implements the greeting business logic. Create one with
// NewService and functional options.
type Service struct {
	repo     Repository
	language string
}

// Option configures Service via the functional options pattern.
type Option func(*Service) error

// WithRepository sets the backing store. Required.
func WithRepository(r Repository) Option {
	return func(s *Service) error {
		if r == nil {
			return errors.New("repository must not be nil")
		}
		s.repo = r
		return nil
	}
}

// WithDefaultLanguage sets the fallback language for greetings.
func WithDefaultLanguage(lang string) Option {
	return func(s *Service) error {
		if lang == "" {
			return errors.New("language must not be empty")
		}
		s.language = lang
		return nil
	}
}

// NewService constructs a Service. WithRepository is required; other
// options are optional with sensible defaults.
func NewService(opts ...Option) (*Service, error) {
	s := &Service{
		language: "en",
	}
	for _, opt := range opts {
		if err := opt(s); err != nil {
			return nil, fmt.Errorf("applying option: %w", err)
		}
	}
	if s.repo == nil {
		return nil, errors.New("repository is required: use WithRepository")
	}
	return s, nil
}

// Create validates input, builds a greeting, persists it, and returns
// the stored entity.
func (s *Service) Create(ctx context.Context, in CreateInput) (Greeting, error) {
	if err := in.Validate(); err != nil {
		return Greeting{}, fmt.Errorf("invalid input: %w", err)
	}

	lang := in.Language
	if lang == "" {
		lang = s.language
	}

	g := Greeting{
		ID:        generateID(),
		Name:      in.Name,
		Language:  lang,
		Message:   buildMessage(lang, in.Name),
		CreatedAt: time.Now().UTC(),
	}

	if err := s.repo.Store(ctx, g); err != nil {
		return Greeting{}, fmt.Errorf("storing greeting: %w", err)
	}
	return g, nil
}

// Get retrieves a greeting by ID.
func (s *Service) Get(ctx context.Context, id string) (Greeting, error) {
	if id == "" {
		return Greeting{}, errors.New("id is required")
	}
	return s.repo.FindByID(ctx, id)
}

// List returns all greetings.
func (s *Service) List(ctx context.Context) ([]Greeting, error) {
	return s.repo.List(ctx)
}

func buildMessage(lang, name string) string {
	switch lang {
	case "es":
		return fmt.Sprintf("¡Hola, %s!", name)
	case "fr":
		return fmt.Sprintf("Bonjour, %s!", name)
	default:
		return fmt.Sprintf("Hello, %s!", name)
	}
}
