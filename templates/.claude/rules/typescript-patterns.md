---
paths: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "package.json"]
---

# TypeScript & UI/UX Engineering Guide

Mandatory patterns for building high-performance, user-friendly interfaces. Standards for TypeScript code, component architecture, accessibility, performance, and UX quality.

## Core Principles

| Principle | Rule |
|-----------|------|
| **Type everything** | No `any`. Use `unknown` + type guards when the type is genuinely unknown. |
| **Accessibility first** | Every interactive element must be keyboard-navigable and screen-reader friendly. |
| **Performance by default** | Measure before optimizing, but never ship code that blocks the main thread >50ms. |
| **Progressive enhancement** | Core functionality works without JS where possible. |
| **Responsive always** | Every component must work from 320px to 4K. Mobile-first CSS. |
| **Error resilience** | Every async operation has loading, error, and empty states. |
| **Semantic HTML** | Use `<button>` not `<div onClick>`. Use `<nav>`, `<main>`, `<article>`. |
| **Zero layout shift** | Reserve space for async content. Use skeleton loaders. |

## TypeScript Patterns

- **Strict mode always** (`strict: true`, `noUncheckedIndexedAccess: true`)
- **Discriminated unions for state** (`AsyncState<T>` with status field)
- **Branded types for domain safety** (prevent mixing IDs)
- **Const assertions and satisfies** for route maps, config objects
- **Zod for runtime validation** at API boundaries

## Component Architecture

- **Composition over configuration** (compound components, not prop explosion)
- **Container/Presentation separation** (data fetching vs pure rendering)
- **Custom hooks for reusable logic** (useDebounce, usePagination)
- **Error boundaries everywhere** (wrap routes and major sections)

## State Management

| State Type | Solution |
|------------|----------|
| Server/async data | TanStack Query / SWR |
| URL state | Search params / router |
| Form state | React Hook Form |
| Local UI state | useState |
| Cross-component UI | Zustand / Jotai |

## Performance Standards

| Metric | Budget |
|--------|--------|
| Initial JS bundle | <100KB gzipped |
| Per-route chunk | <50KB gzipped |
| First Contentful Paint | <1.5s |
| Largest Contentful Paint | <2.5s |
| Total Blocking Time | <200ms |
| Cumulative Layout Shift | <0.1 |

- Route-level code splitting (mandatory)
- Virtualization for lists >100 items
- Memoize expensive computations and callbacks
- Preload on hover/focus for perceived speed

## Accessibility (WCAG 2.1 AA)

- Color contrast: 4.5:1 for text, 3:1 for UI components
- All interactive elements keyboard-navigable
- All images have alt, all icons have aria-label
- Focus management: visible indicator, logical tab order, focus trap in modals
- Respect `prefers-reduced-motion`

## UX Quality Standards

- **Loading states**: Skeleton loaders for known layouts, spinners for actions
- **Error recovery**: Always provide retry action
- **Empty states**: Helpful guidance with action
- **Optimistic UI**: Immediate feedback, reconcile with server
- **Responsive**: Cards on mobile, tables on desktop; 44x44px min touch targets
- **Animation**: CSS transitions first; respect prefers-reduced-motion

## Anti-Patterns

| Anti-Pattern | Instead |
|--------------|---------|
| `any` type | `unknown` + type guards |
| `<div onClick>` | `<button>` or `<a>` |
| `useEffect` for data fetching | TanStack Query / SWR |
| CSS-in-JS runtime | Tailwind CSS or CSS Modules |
| `index` as key for dynamic lists | Unique `id` from data |
| Prop drilling >2 levels | Context or state library |
| No loading/error states | Always handle all async states |
| Custom scroll/dropdown | Use Radix, Headless UI, Ariakit |
