package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	if err := runWithSignals(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func runWithSignals() error {
	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()
	return run(ctx)
}

func run(ctx context.Context) error {
	_ = ctx
	fmt.Println("{{PROJECT_NAME}} starting...")
	return nil
}
