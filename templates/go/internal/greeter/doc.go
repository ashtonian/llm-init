// Package greeter provides a greeting service demonstrating recommended
// project patterns: domain types with validation, service interfaces,
// functional options constructors, repository abstraction with a
// memory-backed implementation for testing, and structured error handling.
//
// Use this package as a reference when adding new domain packages.
//
// Example usage:
//
//	repo := greeter.NewMemoryRepository()
//	svc, err := greeter.NewService(
//		greeter.WithRepository(repo),
//		greeter.WithDefaultLanguage("en"),
//	)
//	if err != nil {
//		log.Fatal(err)
//	}
//
//	g, err := svc.Create(ctx, greeter.CreateInput{Name: "World"})
//	if err != nil {
//		log.Fatal(err)
//	}
//	fmt.Println(g.Message) // "Hello, World!"
package greeter
