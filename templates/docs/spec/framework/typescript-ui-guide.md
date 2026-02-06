# TypeScript & UI/UX Engineering Guide

Mandatory patterns for building extremely well-crafted, high-performance, user-friendly interfaces. This guide defines the standards for TypeScript code, component architecture, accessibility, performance, and UX quality that all generated UI code must follow.

> **LLM Quick Reference**: TypeScript UI patterns, component architecture, performance optimization, accessibility, and UX quality standards.

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Writing any TypeScript or frontend code
- Designing UI component architecture
- Building user-facing features or interactions
- Optimizing frontend performance (render cycles, bundle size, runtime)
- Implementing accessibility or responsive design
- Reviewing UI code for quality and UX polish

### Key Sections

| Section | Purpose |
|---------|---------|
| **Core Principles** | Mandatory rules for all UI code |
| **TypeScript Patterns** | Type safety, generics, discriminated unions, utility types |
| **Component Architecture** | Composition, state management, rendering strategies |
| **Performance** | Bundle splitting, virtualization, memoization, render optimization |
| **Accessibility** | WCAG compliance, keyboard navigation, screen readers |
| **UX Quality Standards** | Animation, loading states, error recovery, responsiveness |
| **Testing** | Component testing, visual regression, interaction testing |

### Quick Reference: Decision Matrix

| Scenario | Pattern | Notes |
|----------|---------|-------|
| Shared UI state across siblings | Lift state up or use context | Avoid prop drilling beyond 2 levels |
| Server data caching | React Query / SWR / TanStack Query | Never roll your own cache |
| Form state | React Hook Form / Formik | Uncontrolled preferred for perf |
| Global app state | Zustand / Jotai | Redux only if genuinely needed |
| List >100 items | Virtualize (TanStack Virtual) | Never render 1000+ DOM nodes |
| Animation | CSS transitions first, Framer Motion for complex | No JS `setInterval` animation |
| Data fetching | Server components or suspense boundaries | Avoid useEffect for fetching |

### Context Loading

1. For **TypeScript/UI patterns**: This doc is sufficient
2. For **Go backend integration**: Also load `./go-generation-guide.md`
3. For **performance deep-dive**: Also load `./performance-guide.md`

---

## Core Principles

These rules are mandatory. Every piece of generated UI code must comply.

| Principle | Rule |
|-----------|------|
| **Type everything** | No `any`. Use `unknown` + type guards when the type is genuinely unknown. |
| **Accessibility first** | Every interactive element must be keyboard-navigable and screen-reader friendly. |
| **Performance by default** | Measure before optimizing, but never ship code that blocks the main thread >50ms. |
| **Progressive enhancement** | Core functionality works without JS where possible. Enhance with interactivity. |
| **Responsive always** | Every component must work from 320px to 4K. Mobile-first CSS. |
| **Error resilience** | Every async operation has loading, error, and empty states. No unhandled rejections. |
| **Semantic HTML** | Use `<button>` not `<div onClick>`. Use `<nav>`, `<main>`, `<article>`. |
| **Zero layout shift** | Reserve space for async content. Use skeleton loaders. Set explicit dimensions on media. |

---

## TypeScript Patterns

### Strict mode always

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

### Discriminated unions for state

```typescript
// Good: exhaustive, type-safe state handling
type AsyncState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; error: Error };

function renderState<T>(state: AsyncState<T>) {
  switch (state.status) {
    case "idle":
      return null;
    case "loading":
      return <Skeleton />;
    case "success":
      return <DataView data={state.data} />;
    case "error":
      return <ErrorView error={state.error} onRetry={retry} />;
  }
}
```

### Branded types for domain safety

```typescript
type UserId = string & { readonly __brand: "UserId" };
type TenantId = string & { readonly __brand: "TenantId" };

function createUserId(id: string): UserId {
  if (!isValidUUID(id)) throw new Error(`Invalid user ID: ${id}`);
  return id as UserId;
}

// Compiler prevents mixing IDs
function getUser(userId: UserId, tenantId: TenantId): Promise<User> { ... }
```

### Const assertions and satisfies

```typescript
const ROUTES = {
  home: "/",
  dashboard: "/dashboard",
  settings: "/settings",
  profile: "/profile/:id",
} as const satisfies Record<string, string>;

type Route = (typeof ROUTES)[keyof typeof ROUTES];
```

### Utility types for API integration

```typescript
// Derive frontend types from API response shapes
type ApiResponse<T> = {
  data: T;
  meta: { cursor?: string; total: number };
};

// Create form types from entity types (omit server-generated fields)
type CreateUserForm = Omit<User, "id" | "createdAt" | "updatedAt">;
type UpdateUserForm = Partial<Pick<User, "name" | "email" | "avatar">>;

// Extract component props from complex types
type ListItemProps = Pick<User, "id" | "name" | "avatar"> & {
  isSelected: boolean;
  onSelect: (id: UserId) => void;
};
```

### Zod for runtime validation

```typescript
import { z } from "zod";

const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(255),
  email: z.string().email(),
  role: z.enum(["admin", "member", "viewer"]),
});

type User = z.infer<typeof UserSchema>;

// Validate API responses at the boundary
function parseUser(data: unknown): User {
  return UserSchema.parse(data);
}
```

---

## Component Architecture

### Composition over configuration

```typescript
// Good: composable, flexible
<Card>
  <Card.Header>
    <Card.Title>Users</Card.Title>
    <Card.Action><Button>Add</Button></Card.Action>
  </Card.Header>
  <Card.Body>
    <UserList users={users} />
  </Card.Body>
</Card>

// Bad: prop explosion
<Card
  title="Users"
  actionLabel="Add"
  onAction={handleAdd}
  bodyContent={<UserList users={users} />}
/>
```

### Container/Presentation separation

```typescript
// Container: handles data fetching, state, side effects
function UserListContainer() {
  const { data, isLoading, error } = useUsers();

  if (isLoading) return <UserListSkeleton />;
  if (error) return <ErrorBanner error={error} />;
  if (!data?.length) return <EmptyState icon={UsersIcon} message="No users yet" />;

  return <UserList users={data} />;
}

// Presentation: pure rendering, no side effects, easy to test
function UserList({ users }: { users: User[] }) {
  return (
    <ul role="list" className="divide-y">
      {users.map((user) => (
        <UserListItem key={user.id} user={user} />
      ))}
    </ul>
  );
}
```

### Custom hooks for reusable logic

```typescript
// Encapsulate complex stateful logic
function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debounced;
}

function usePagination<T>(
  fetcher: (cursor?: string) => Promise<ApiResponse<T[]>>,
) {
  const [pages, setPages] = useState<T[][]>([]);
  const [cursor, setCursor] = useState<string>();
  const [hasMore, setHasMore] = useState(true);

  const loadMore = useCallback(async () => {
    const response = await fetcher(cursor);
    setPages((prev) => [...prev, response.data]);
    setCursor(response.meta.cursor);
    setHasMore(!!response.meta.cursor);
  }, [fetcher, cursor]);

  return {
    items: pages.flat(),
    loadMore,
    hasMore,
  };
}
```

### Error boundaries everywhere

```typescript
// Wrap every route and major section in an error boundary
function AppRoutes() {
  return (
    <Routes>
      <Route path="/dashboard" element={
        <ErrorBoundary fallback={<RouteErrorFallback />}>
          <Suspense fallback={<DashboardSkeleton />}>
            <Dashboard />
          </Suspense>
        </ErrorBoundary>
      } />
    </Routes>
  );
}

// Error boundaries must offer recovery
function RouteErrorFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div role="alert" className="p-8 text-center">
      <h2>Something went wrong</h2>
      <p className="text-muted">{error.message}</p>
      <Button onClick={resetErrorBoundary}>Try again</Button>
    </div>
  );
}
```

---

## State Management

### Decision matrix

| State Type | Solution | Example |
|------------|----------|---------|
| Server/async data | TanStack Query / SWR | User list, dashboard stats |
| URL state | Search params / router | Filters, pagination, tab selection |
| Form state | React Hook Form | Create/edit forms |
| Local UI state | useState | Modals, dropdowns, tooltips |
| Cross-component UI | Zustand / Jotai | Theme, sidebar collapsed, toast queue |
| Complex derived state | useMemo / selectors | Filtered/sorted lists |

### Server state with TanStack Query

```typescript
// Define query keys as constants
const queryKeys = {
  users: ["users"] as const,
  user: (id: string) => ["users", id] as const,
  userDevices: (id: string) => ["users", id, "devices"] as const,
};

function useUsers(filters?: UserFilters) {
  return useQuery({
    queryKey: [...queryKeys.users, filters],
    queryFn: () => api.users.list(filters),
    staleTime: 30_000,        // Data fresh for 30s
    gcTime: 5 * 60_000,       // Cache for 5min
    placeholderData: keepPreviousData, // Show stale while fetching
  });
}

// Optimistic updates for mutations
function useUpdateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: api.users.update,
    onMutate: async (variables) => {
      await queryClient.cancelQueries({ queryKey: queryKeys.user(variables.id) });
      const previous = queryClient.getQueryData(queryKeys.user(variables.id));
      queryClient.setQueryData(queryKeys.user(variables.id), (old: User) => ({
        ...old,
        ...variables.data,
      }));
      return { previous };
    },
    onError: (_err, variables, context) => {
      queryClient.setQueryData(queryKeys.user(variables.id), context?.previous);
    },
    onSettled: (_data, _error, variables) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.user(variables.id) });
    },
  });
}
```

---

## Performance Standards

### Bundle size budgets

| Metric | Budget | Enforcement |
|--------|--------|-------------|
| Initial JS bundle | <100KB gzipped | Build fails above threshold |
| Per-route chunk | <50KB gzipped | Code-split at route level |
| First Contentful Paint | <1.5s | Lighthouse CI |
| Largest Contentful Paint | <2.5s | Lighthouse CI |
| Total Blocking Time | <200ms | Lighthouse CI |
| Cumulative Layout Shift | <0.1 | Lighthouse CI |

### Code splitting

```typescript
// Route-level splitting (mandatory)
const Dashboard = lazy(() => import("./pages/Dashboard"));
const Settings = lazy(() => import("./pages/Settings"));

// Component-level splitting for heavy components
const Chart = lazy(() => import("./components/Chart"));
const CodeEditor = lazy(() => import("./components/CodeEditor"));

// Preload on hover/focus for perceived speed
function NavLink({ to, children }: NavLinkProps) {
  const preload = () => {
    const route = routeModules[to];
    if (route) route.preload();
  };

  return (
    <Link to={to} onMouseEnter={preload} onFocus={preload}>
      {children}
    </Link>
  );
}
```

### Virtualization for long lists

```typescript
import { useVirtualizer } from "@tanstack/react-virtual";

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 64,
    overscan: 5,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div style={{ height: virtualizer.getTotalSize(), position: "relative" }}>
        {virtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.key}
            style={{
              position: "absolute",
              top: 0,
              transform: `translateY(${virtualRow.start}px)`,
              height: virtualRow.size,
              width: "100%",
            }}
          >
            <ListItem item={items[virtualRow.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

### Render optimization

```typescript
// Memoize expensive computations
const sortedAndFiltered = useMemo(
  () => items
    .filter((item) => item.status === filter)
    .sort((a, b) => a.name.localeCompare(b.name)),
  [items, filter],
);

// Memoize callbacks passed to child components
const handleSelect = useCallback(
  (id: string) => setSelected((prev) => prev.includes(id)
    ? prev.filter((s) => s !== id)
    : [...prev, id]),
  [],
);

// Use React.memo for pure list items
const ListItem = memo(function ListItem({ item, onSelect }: ListItemProps) {
  return (
    <div onClick={() => onSelect(item.id)}>
      {item.name}
    </div>
  );
});
```

### Image optimization

```typescript
// Always use next/image or responsive images
<Image
  src={user.avatar}
  alt={user.name}
  width={48}
  height={48}
  loading="lazy"                    // Lazy load below-fold images
  placeholder="blur"                // Show blur while loading
  sizes="(max-width: 768px) 32px, 48px"
/>

// Explicit dimensions prevent layout shift
<img
  src={thumbnail}
  alt={description}
  width="320"
  height="180"
  loading="lazy"
  decoding="async"
/>
```

---

## Accessibility Standards

### WCAG 2.1 AA compliance is mandatory

| Requirement | Implementation |
|-------------|---------------|
| Color contrast | 4.5:1 for text, 3:1 for large text and UI components |
| Keyboard navigation | All interactive elements focusable via Tab, activatable via Enter/Space |
| Screen reader labels | All images have `alt`, all icons have `aria-label`, all regions have landmarks |
| Focus management | Visible focus indicator, logical tab order, focus trap in modals |
| Motion sensitivity | Respect `prefers-reduced-motion`, provide pause controls for animation |
| Text sizing | UI functional at 200% zoom, use `rem` not `px` for text |

### Interactive component patterns

```typescript
// Dialog/Modal
function Modal({ isOpen, onClose, title, children }: ModalProps) {
  const closeRef = useRef<HTMLButtonElement>(null);

  // Trap focus inside modal
  // Return focus to trigger on close
  // Close on Escape key

  return (
    <Dialog open={isOpen} onClose={onClose} initialFocus={closeRef}>
      <Dialog.Overlay className="fixed inset-0 bg-black/50" />
      <Dialog.Panel role="dialog" aria-modal="true" aria-labelledby="modal-title">
        <Dialog.Title id="modal-title">{title}</Dialog.Title>
        {children}
        <button ref={closeRef} onClick={onClose}>Close</button>
      </Dialog.Panel>
    </Dialog>
  );
}

// Dropdown/Select
// Always use Headless UI, Radix, or Ariakit for complex widgets
// Never build custom dropdowns from scratch
```

### Keyboard shortcuts

```typescript
// Register keyboard shortcuts with a central system
function useKeyboardShortcut(
  key: string,
  callback: () => void,
  options?: { ctrl?: boolean; meta?: boolean; shift?: boolean },
) {
  useEffect(() => {
    function handler(e: KeyboardEvent) {
      if (options?.ctrl && !e.ctrlKey) return;
      if (options?.meta && !e.metaKey) return;
      if (options?.shift && !e.shiftKey) return;
      if (e.key === key) {
        e.preventDefault();
        callback();
      }
    }
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [key, callback, options]);
}
```

---

## UX Quality Standards

### Loading states

Every async boundary must show appropriate feedback:

```typescript
// Skeleton loading (preferred for known layouts)
function UserCardSkeleton() {
  return (
    <div className="animate-pulse">
      <div className="h-12 w-12 rounded-full bg-gray-200" />
      <div className="h-4 w-32 rounded bg-gray-200 mt-2" />
      <div className="h-3 w-24 rounded bg-gray-200 mt-1" />
    </div>
  );
}

// Inline loading for actions
<Button onClick={handleSave} disabled={isSaving}>
  {isSaving ? <Spinner size="sm" /> : null}
  {isSaving ? "Saving..." : "Save"}
</Button>

// Progress indication for long operations
<ProgressBar value={uploadProgress} max={100} aria-label="Upload progress" />
```

### Error recovery

```typescript
// Errors must be recoverable. Always provide a retry action.
function ErrorState({ error, onRetry }: { error: Error; onRetry: () => void }) {
  return (
    <div role="alert" className="text-center p-8">
      <AlertCircle className="mx-auto h-12 w-12 text-red-400" />
      <h3 className="mt-4 font-medium">Failed to load</h3>
      <p className="mt-2 text-sm text-gray-500">{error.message}</p>
      <Button onClick={onRetry} className="mt-4">Try again</Button>
    </div>
  );
}

// Toast notifications for non-blocking errors
function useErrorToast() {
  const { toast } = useToast();

  return useCallback((error: Error) => {
    toast({
      variant: "destructive",
      title: "Something went wrong",
      description: error.message,
      action: <ToastAction altText="Try again">Retry</ToastAction>,
    });
  }, [toast]);
}
```

### Empty states

```typescript
// Every list/table must handle the empty case with helpful guidance
function EmptyState({ icon: Icon, title, description, action }: EmptyStateProps) {
  return (
    <div className="text-center py-12">
      <Icon className="mx-auto h-12 w-12 text-gray-400" />
      <h3 className="mt-4 text-sm font-medium">{title}</h3>
      <p className="mt-2 text-sm text-gray-500">{description}</p>
      {action && <div className="mt-6">{action}</div>}
    </div>
  );
}

// Usage
<EmptyState
  icon={InboxIcon}
  title="No messages"
  description="New messages will appear here when you receive them."
  action={<Button>Send your first message</Button>}
/>
```

### Optimistic UI

```typescript
// Immediate feedback for user actions. Reconcile with server response.
function useOptimisticToggle(item: Item) {
  const [optimisticState, setOptimisticState] = useState(item.isActive);
  const mutation = useToggleMutation();

  const toggle = () => {
    setOptimisticState(!optimisticState);
    mutation.mutate(
      { id: item.id, isActive: !item.isActive },
      { onError: () => setOptimisticState(item.isActive) }, // Revert on failure
    );
  };

  return { isActive: optimisticState, toggle, isPending: mutation.isPending };
}
```

### Responsive design

```typescript
// Mobile-first breakpoints
// sm: 640px, md: 768px, lg: 1024px, xl: 1280px, 2xl: 1536px

// Responsive component patterns
function DataDisplay({ items }: { items: Item[] }) {
  return (
    <>
      {/* Cards on mobile, table on desktop */}
      <div className="block md:hidden">
        {items.map((item) => <ItemCard key={item.id} item={item} />)}
      </div>
      <div className="hidden md:block">
        <ItemTable items={items} />
      </div>
    </>
  );
}

// Touch targets: minimum 44x44px on mobile
<button className="min-h-[44px] min-w-[44px] p-3">
  <Icon className="h-5 w-5" />
</button>
```

### Animation guidelines

```css
/* Respect user preferences */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

/* Standard transitions */
.transition-default {
  transition-property: color, background-color, border-color, opacity, transform;
  transition-duration: 150ms;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
}

/* Enter/exit animations */
.fade-in { animation: fadeIn 200ms ease-out; }
.slide-up { animation: slideUp 200ms ease-out; }
```

---

## Testing Standards

### Component testing

```typescript
import { render, screen, userEvent } from "@testing-library/react";

// Test behavior, not implementation
test("submits form with valid data", async () => {
  const onSubmit = vi.fn();
  render(<UserForm onSubmit={onSubmit} />);

  await userEvent.type(screen.getByLabelText("Name"), "Alice");
  await userEvent.type(screen.getByLabelText("Email"), "alice@example.com");
  await userEvent.click(screen.getByRole("button", { name: "Save" }));

  expect(onSubmit).toHaveBeenCalledWith({
    name: "Alice",
    email: "alice@example.com",
  });
});

// Test accessibility
test("form fields have accessible labels", () => {
  render(<UserForm onSubmit={vi.fn()} />);

  expect(screen.getByLabelText("Name")).toBeInTheDocument();
  expect(screen.getByLabelText("Email")).toBeInTheDocument();
  expect(screen.getByRole("button", { name: "Save" })).toBeInTheDocument();
});

// Test error states
test("shows validation errors", async () => {
  render(<UserForm onSubmit={vi.fn()} />);

  await userEvent.click(screen.getByRole("button", { name: "Save" }));

  expect(screen.getByText("Name is required")).toBeInTheDocument();
});
```

### Visual regression testing

```typescript
// Use Playwright or Chromatic for visual testing
test("user card renders correctly", async ({ page }) => {
  await page.goto("/storybook?id=user-card--default");
  await expect(page.locator(".user-card")).toHaveScreenshot();
});
```

---

## File Organization

```
src/
├── components/           # Shared UI components
│   ├── ui/              # Primitive components (Button, Input, Card)
│   ├── layout/          # Layout components (Sidebar, Header, Page)
│   └── domain/          # Domain-specific components (UserCard, DeviceList)
├── hooks/               # Custom React hooks
├── lib/                 # Utilities, API client, type helpers
├── pages/               # Route-level components (one per route)
├── stores/              # Zustand/Jotai stores
├── types/               # Shared TypeScript types
└── styles/              # Global styles, theme tokens
```

### Naming conventions

| Item | Convention | Example |
|------|-----------|---------|
| Components | PascalCase | `UserCard.tsx` |
| Hooks | camelCase with `use` prefix | `useDebounce.ts` |
| Utilities | camelCase | `formatDate.ts` |
| Types | PascalCase | `User.ts` |
| Constants | SCREAMING_SNAKE_CASE | `API_BASE_URL` |
| CSS classes | kebab-case / Tailwind | `user-card`, `flex items-center` |
| Test files | `*.test.tsx` co-located | `UserCard.test.tsx` |

---

## Anti-Patterns

| Anti-Pattern | Why | Instead |
|--------------|-----|---------|
| `any` type | Defeats TypeScript's purpose | `unknown` + type guards |
| `<div onClick>` | Not keyboard accessible | `<button>` or `<a>` |
| `useEffect` for data fetching | Race conditions, no caching | TanStack Query / SWR |
| CSS-in-JS runtime (styled-components) | Runtime overhead, bundle bloat | Tailwind CSS or CSS Modules |
| Inline styles for layout | Not responsive, hard to maintain | Utility classes or CSS |
| `index` as key for dynamic lists | Causes render bugs | Unique `id` from data |
| Prop drilling >2 levels | Couples components | Context or state library |
| Massive monolith components | Untestable, hard to reason about | Compose from small components |
| `console.log` in production | Leaks information | Structured error reporting |
| Uncontrolled re-renders | Performance degradation | React.memo, useMemo, useCallback |
| No loading/error states | Broken UX | Always handle all async states |
| Custom scroll/dropdown | Accessibility nightmare | Use Radix, Headless UI, Ariakit |

---

## Related Documentation

- [Go Generation Guide](./go-generation-guide.md) - Backend code patterns
- [Performance Guide](./performance-guide.md) - System-wide performance standards
- [Testing Guide](./testing-guide.md) - Test patterns and strategies

<!-- Add these cross-references as you create the specs:
- api-design.md - REST conventions the frontend consumes
- error-handling.md - Error codes the frontend must handle
-->
