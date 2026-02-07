---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/components/**"
  - "**/pages/**"
  - "**/app/**"
  - "**/hooks/**"
  - "**/stores/**"
---

# Frontend Architecture Standards

Mandatory patterns for React/Next.js frontend development in multi-tenant SaaS applications. Component architecture, state management, data fetching, and testing patterns.

## Component Architecture: Atomic Design

Build from small to large. Every component at each level must be independently testable.

```
atoms/          # Buttons, inputs, labels, icons, badges
molecules/      # Form fields (label + input + error), search bars, nav items
organisms/      # Forms, data tables, navigation bars, card lists
templates/      # Page layouts (sidebar + content + header)
pages/          # Full pages composing templates + organisms
```

### Component File Structure

```
components/
  ui/                    # atoms + molecules (design system primitives)
    button.tsx
    input.tsx
    badge.tsx
    form-field.tsx
    search-bar.tsx
  features/              # organisms (business-specific)
    user-table/
      user-table.tsx
      user-table.test.tsx
      use-user-table.ts  # Hook for table logic
      columns.tsx        # Column definitions
    invite-form/
      invite-form.tsx
      invite-form.test.tsx
      invite-form.schema.ts  # Zod validation schema
```

### Component Rules

```tsx
// GOOD: Small, focused, typed component
interface UserAvatarProps {
  name: string;
  imageUrl?: string;
  size?: 'sm' | 'md' | 'lg';
}

export function UserAvatar({ name, imageUrl, size = 'md' }: UserAvatarProps) {
  const initials = name.split(' ').map(n => n[0]).join('').slice(0, 2);

  return (
    <div className={cn('avatar', `avatar-${size}`)} role="img" aria-label={name}>
      {imageUrl ? (
        <img src={imageUrl} alt="" /> // decorative, name in aria-label
      ) : (
        <span>{initials}</span>
      )}
    </div>
  );
}

// BAD: God component doing everything
export function UserManagementPage() {
  // 200+ lines of mixed concerns
  // Data fetching, state, rendering, event handling all tangled together
}
```

Rules:
- Maximum 100 lines per component file. Split if larger.
- Every component has a TypeScript interface for its props.
- No `any` types. No `@ts-ignore`.
- Export named components (not default exports) for better tree-shaking and refactoring.
- Colocate tests, hooks, and schemas with the component.

## State Management

### Server State: TanStack Query (React Query)

All API data is server state. Use TanStack Query for caching, background refetching, and optimistic updates.

```tsx
// Collocate query with the component that uses it
function useUsers(filter: UserFilter) {
  return useQuery({
    queryKey: ['users', filter],
    queryFn: () => api.users.list(filter),
    staleTime: 30_000,        // 30 seconds before refetch
    gcTime: 5 * 60_000,       // 5 minutes in cache after unmount
    placeholderData: keepPreviousData,  // Show old data while refetching
  });
}

// Mutations with optimistic updates
function useCreateUser() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: api.users.create,
    onMutate: async (newUser) => {
      await queryClient.cancelQueries({ queryKey: ['users'] });
      const previous = queryClient.getQueryData(['users']);
      queryClient.setQueryData(['users'], (old) => [...old, { ...newUser, id: 'temp' }]);
      return { previous };
    },
    onError: (err, newUser, context) => {
      queryClient.setQueryData(['users'], context?.previous);  // Rollback
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });  // Refetch
    },
  });
}
```

### Client State: Zustand (Minimal)

Only for truly client-side state that doesn't come from the API:

```tsx
// GOOD: UI-only state in Zustand
interface UIStore {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
  theme: 'light' | 'dark';
  setTheme: (theme: 'light' | 'dark') => void;
}

const useUIStore = create<UIStore>((set) => ({
  sidebarOpen: true,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
  theme: 'light',
  setTheme: (theme) => set({ theme }),
}));

// BAD: Duplicating server state in client store
const useUserStore = create((set) => ({
  users: [],  // This belongs in TanStack Query, not a client store
  fetchUsers: async () => { ... },
}));
```

### URL State

Filters, sorts, pagination, and view options belong in URL search params:

```tsx
function useUrlFilters() {
  const [searchParams, setSearchParams] = useSearchParams();

  return {
    status: searchParams.get('status') ?? 'active',
    sort: searchParams.get('sort') ?? '-created_at',
    page: parseInt(searchParams.get('page') ?? '1'),
    setFilter: (key: string, value: string) => {
      setSearchParams((prev) => {
        prev.set(key, value);
        prev.set('page', '1');  // Reset page on filter change
        return prev;
      });
    },
  };
}
```

This makes views shareable, bookmarkable, and browser-back-button friendly.

## Data Fetching Patterns

### Collocate Queries with Components

```tsx
// GOOD: Query defined next to the component that uses it
function UserList() {
  const { data, isLoading, error } = useUsers({ status: 'active' });
  // ...
}

// BAD: Query in a parent, passed as props through multiple levels
function App() {
  const users = useUsers();
  return <Layout><Sidebar><UserList users={users.data} /></Sidebar></Layout>;
}
```

### Prefetch on Hover

```tsx
function UserRow({ user }: { user: User }) {
  const queryClient = useQueryClient();

  return (
    <Link
      to={`/users/${user.id}`}
      onMouseEnter={() => {
        queryClient.prefetchQuery({
          queryKey: ['user', user.id],
          queryFn: () => api.users.get(user.id),
        });
      }}
    >
      {user.name}
    </Link>
  );
}
```

### Streaming SSR (Next.js)

```tsx
// app/users/page.tsx
import { Suspense } from 'react';

export default function UsersPage() {
  return (
    <div>
      <h1>Users</h1>
      <Suspense fallback={<UserTableSkeleton />}>
        <UserTable />
      </Suspense>
      <Suspense fallback={<ActivityFeedSkeleton />}>
        <ActivityFeed />
      </Suspense>
    </div>
  );
}
```

## Multi-Tenant UI

### Tenant Context Provider

```tsx
interface TenantConfig {
  id: string;
  name: string;
  logoUrl: string;
  primaryColor: string;
  features: Record<string, boolean>;
  plan: 'free' | 'pro' | 'enterprise';
  limits: { maxUsers: number; maxStorage: number };
}

const TenantContext = createContext<TenantConfig | null>(null);

export function TenantProvider({ children }: { children: ReactNode }) {
  const { data: tenant, isLoading } = useQuery({
    queryKey: ['tenant-config'],
    queryFn: api.tenant.getConfig,
    staleTime: 5 * 60_000,
  });

  if (isLoading) return <FullPageSkeleton />;

  return (
    <TenantContext.Provider value={tenant}>
      <TenantTheme config={tenant}>
        {children}
      </TenantTheme>
    </TenantContext.Provider>
  );
}

export function useTenant() {
  const ctx = useContext(TenantContext);
  if (!ctx) throw new Error('useTenant must be used within TenantProvider');
  return ctx;
}
```

### Feature Flags

```tsx
export function useFeatureFlag(flag: string): boolean {
  const tenant = useTenant();
  return tenant.features[flag] ?? false;
}

// Usage: render nothing for unavailable features (don't show disabled)
function AdvancedAnalytics() {
  if (!useFeatureFlag('advanced-analytics')) return null;
  return <AnalyticsDashboard />;
}

// For upgrade prompts on plan-gated features
function ExportButton() {
  const hasExport = useFeatureFlag('data-export');
  const tenant = useTenant();

  if (!hasExport) {
    return (
      <UpgradePrompt
        feature="Data Export"
        requiredPlan="pro"
        currentPlan={tenant.plan}
      />
    );
  }

  return <Button onClick={handleExport}>Export Data</Button>;
}
```

### Theme Tokens from API

```tsx
function TenantTheme({ config, children }: { config: TenantConfig; children: ReactNode }) {
  return (
    <div
      style={{
        '--color-primary': config.primaryColor,
        '--color-primary-hover': adjustColor(config.primaryColor, -10),
        '--color-primary-light': adjustColor(config.primaryColor, 90),
      } as React.CSSProperties}
    >
      {children}
    </div>
  );
}
```

## Form Handling

### React Hook Form + Zod

```tsx
const createUserSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100),
  email: z.string().email('Invalid email address'),
  role: z.enum(['admin', 'member', 'viewer']),
});

type CreateUserInput = z.infer<typeof createUserSchema>;

function CreateUserForm() {
  const form = useForm<CreateUserInput>({
    resolver: zodResolver(createUserSchema),
    defaultValues: { name: '', email: '', role: 'member' },
  });

  const mutation = useCreateUser();

  return (
    <form onSubmit={form.handleSubmit((data) => mutation.mutate(data))}>
      <FormField
        label="Name"
        error={form.formState.errors.name?.message}
        {...form.register('name')}
      />
      <FormField
        label="Email"
        error={form.formState.errors.email?.message}
        {...form.register('email')}
      />
      <Button type="submit" loading={mutation.isPending}>
        Create User
      </Button>
    </form>
  );
}
```

## Error Boundaries

```tsx
// Per-route error boundaries
function ErrorBoundaryFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div role="alert">
      <h2>Something went wrong</h2>
      <p>{error.message}</p>
      <Button onClick={resetErrorBoundary}>Try Again</Button>
    </div>
  );
}

// Wrap each route independently
<ErrorBoundary FallbackComponent={ErrorBoundaryFallback}>
  <UserManagement />
</ErrorBoundary>
```

## Loading UX

```tsx
// GOOD: Skeleton screens
function UserTableSkeleton() {
  return (
    <div aria-busy="true" aria-label="Loading users">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="skeleton-row">
          <div className="skeleton skeleton-avatar" />
          <div className="skeleton skeleton-text" style={{ width: '40%' }} />
          <div className="skeleton skeleton-text" style={{ width: '25%' }} />
        </div>
      ))}
    </div>
  );
}

// BAD: Blank page or full-page spinner
function UserTable() {
  const { data, isLoading } = useUsers();
  if (isLoading) return <Spinner />; // Shows nothing useful
}
```

## Code Splitting

```tsx
// Route-based splitting (automatic in Next.js)
// For heavy components, use dynamic imports
import dynamic from 'next/dynamic';

const RichTextEditor = dynamic(() => import('@/components/rich-text-editor'), {
  loading: () => <div className="skeleton" style={{ height: 300 }} />,
  ssr: false,  // Client-only component
});

const ChartDashboard = dynamic(() => import('@/components/chart-dashboard'), {
  loading: () => <ChartSkeleton />,
});
```

## Testing

### React Testing Library (Behavior, not implementation)

```tsx
// GOOD: Test user behavior
test('creates user when form is submitted with valid data', async () => {
  render(<CreateUserForm />);

  await userEvent.type(screen.getByLabelText('Name'), 'Jane Doe');
  await userEvent.type(screen.getByLabelText('Email'), 'jane@example.com');
  await userEvent.click(screen.getByRole('button', { name: 'Create User' }));

  expect(await screen.findByText('User created successfully')).toBeInTheDocument();
});

// BAD: Testing implementation details
test('sets state when input changes', () => {
  const { result } = renderHook(() => useState(''));
  act(() => result.current[1]('test'));
  expect(result.current[0]).toBe('test');
});
```

### MSW for API Mocking

```tsx
// Mock API at the network level, not the import level
const handlers = [
  http.get('/api/v1/users', () => {
    return HttpResponse.json({
      data: [{ id: '1', name: 'Jane', email: 'jane@example.com' }],
      meta: { has_more: false },
    });
  }),
  http.post('/api/v1/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ data: { id: '2', ...body } }, { status: 201 });
  }),
];
```

## Internationalization

- Use ICU message format for plurals and variables: `{count, plural, one {# item} other {# items}}`
- Support RTL layouts with `dir="rtl"` and logical CSS properties (`margin-inline-start` not `margin-left`)
- Format dates and numbers per locale: `Intl.DateTimeFormat`, `Intl.NumberFormat`
- Never hardcode date formats or currency symbols

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|----------------|
| `any` types | Proper TypeScript interfaces |
| `useEffect` for data fetching | TanStack Query or SWR |
| Props drilling through 3+ levels | Context or composition |
| Global CSS | CSS modules, Tailwind, or styled-components |
| `index.ts` barrel files (tree-shaking issues) | Direct imports |
| Hardcoded colors/spacing | Design tokens / CSS custom properties |
| `dangerouslySetInnerHTML` | Sanitize with DOMPurify if absolutely needed |
| Default exports | Named exports for better refactoring |
| Client-side store for server data | TanStack Query for API data |
| Full-page spinners | Skeleton screens + Suspense boundaries |
