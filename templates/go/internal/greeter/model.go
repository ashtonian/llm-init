package greeter

import (
	"errors"
	"time"
)

// Greeting is the core domain model.
type Greeting struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Language  string    `json:"language"`
	Message   string    `json:"message"`
	CreatedAt time.Time `json:"created_at"`
}

// CreateInput holds validated input for creating a greeting.
type CreateInput struct {
	Name     string
	Language string // optional — falls back to service default
}

// Validate checks invariants before the input reaches the service layer.
func (in CreateInput) Validate() error {
	if in.Name == "" {
		return errors.New("name is required")
	}
	if len(in.Name) > 200 {
		return errors.New("name must be 200 characters or fewer")
	}
	return nil
}
