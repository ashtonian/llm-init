package main

import (
	"context"
	"testing"
)

func TestRun(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	if err := run(ctx); err != nil {
		t.Fatalf("run() returned error: %v", err)
	}
}
